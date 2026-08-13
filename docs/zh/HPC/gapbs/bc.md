`bc.cc` 实现的是 GAPBS 的 **Brandes 近似 BC**（Madduri 等 IPDPS'09 并行优化版）：对每个源点做前向 BFS + 反向依赖累加，只采样部分源点，最后归一化到 [0,1]。

## 构造真实的图

make bench-graphs

（在 `tao/gapbs/` 下，与 `cc` 相同。）

## 运行

```bash
# GAP 官方 benchmark（bench.mk）
./bc -f benchmark/graphs/twitter.sg -i4 -n16

# ChampSim trace / 单源 profiling
OMP_NUM_THREADS=1 ./bc -f benchmark/graphs/twitter.sg -i1 -n1

# 小图快速试跑
OMP_NUM_THREADS=1 ./bc -g 12 -i1 -n1
```

| 参数 | 含义 |
|------|------|
| **`-i N`** | 每个 trial 采 **N 个源点**（官方 **4**） |
| **`-n N`** | **N 次 trial**（官方 **16**），不是顶点数 |
| **`-l`** | 打印每源点 **PBFS（b）** 与 **back-prop（p）** 分段耗时 |

---

## 实测热点（gprof, kron20）

**Setup：** SERIAL 构建（`-pg -no-pie`），`OMP_NUM_THREADS=1`，图 `benchmark/graphs/kron20.sg`，**20 trials**，**`-i 1`**（每 trial 1 个源点），加载序列化图。

| % self | 函数 |
|--------|------|
| **54.3%** | `PBFS` |
| **45.3%** | `Brandes`（反向 back-prop 计入 Brandes self） |

**Avg Trial Time：** 381.6 ms

前向 PBFS 与反向 Brandes **几乎平分**（54% / 45%）；back-prop 的 CSR 扫边与浮点 delta 累加未单独出现在 flat profile。

```bash
cd tao/gapbs
# SERIAL: make clean && make CXXFLAGS+='-pg -no-pie'
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=bc_kron20 ./bc -f benchmark/graphs/kron20.sg -i1 -n20
gprof ./bc gmon.file
```

原始 gprof：`tao/gapbs/profile_runs/bc_gprof.txt`

---

## 整体执行流程

`main` → `BenchmarkKernel` → `Brandes()`；每个源点两阶段：

```108:139:/home/ice/src/sdc-benchmark/tao/gapbs/src/bc.cc
  for (NodeID iter=0; iter < num_iters; iter++) {
    NodeID source = sp.PickNext();
    path_counts.fill(0);
    depth_index.resize(0);
    queue.reset();
    succ.reset();
    PBFS(g, source, path_counts, succ, depth_index, queue);   // 前向 BFS
    // ...
    for (int d=depth_index.size()-2; d >= 0; d--) {            // 反向依赖
      for (auto it = depth_index[d]; it < depth_index[d+1]; it++) {
        NodeID u = *it;
        for (NodeID &v : g.out_neigh(u)) { ... }
      }
    }
  }
```

```
Brandes()
 └─ for each source (-i4 → 4 次)
      ├─ PBFS()           ← P0 热点：前向层同步 BFS
      └─ back-prop 循环    ← P1 热点：按深度反向累加 delta
```

---

## 关键结构速查

### `SlidingQueue<NodeID> queue`

双缓冲 **BFS 层队列**：底层连续数组 `shared[]` 存 **`NodeID`（4B）**，不是指针。

- `begin()/end()`：当前层可读区间  
- `push_back`：写入下一层（本层循环不可见）  
- `slide_window()`：下一层变为当前层  

并行时用线程局部 `QueueBuffer` 再 `flush` 进共享队列。  
**访存：** 对本层 `u` 为 SEQ，宽 frontier 时有带宽，但相对 CSR/`depths`/`path_counts` 为次要（同 SSSP 的 `frontier` 档）。

### `depth_index`（`vector<NodeID*>`）

只存各层在 `queue.shared` 上的**边界指针**（fencepost），长度约 BFS 层数，很小。

- 数组本身按层从浅到深存放；**反向阶段** `for (d = size-2; d >= 0; d--)` 是对下标 **递减**（最远层 → 源点）。  
- 热路径不是扫整个 `depth_index[]`，而是每层取 `depth_index[d]` / `[d+1]`，再在中间的 **`NodeID` 段**上顺序扫 `u`。

### `PBFS()` 输入 / 输出（无返回值）

| | 含义 |
|--|------|
| 输入 | `g`、`source`；工作区 `queue` |
| 写出 | `path_counts`、`succ`、`depth_index` |
| 内部 | `depths`（仅 PBFS 内） |

---

## 中间数组生命周期（TAO 绑基址必读）

不全是「申请一次、地址永远不变」。按 `Brandes` 内一次调用来分：

### A. `Brandes()` 内申请一次，多源复用（基址在本次 Brandes 内稳定）

| 对象 | 每源做什么 | 基址 |
|------|------------|------|
| `scores` | 跨源累加 | 稳定 |
| `path_counts` | `fill(0)`，不重新 `new` | 稳定 |
| `succ` | `reset()` 清零，同一块 bitmap | 稳定 |
| `queue` | `reset()`；`shared[]` 不动 | **底层缓冲稳定** |
| `depth_index` | `resize(0)` 再 `push_back` | 容器多数不换基址；**元素是指向 queue 的指针，每源指针值会变** |

### B. 每个源点重新申请（地址可能变）

| 对象 | 位置 | 说明 |
|------|------|------|
| **`deltas`** | back-prop 前：`pvector deltas(n, 0)` | **每源 new**，换源基址可能变 |
| **`depths`** | `PBFS` 局部 | **每次 PBFS new**，换源基址变 |
| `QueueBuffer` | OpenMP 并行区局部 | 临时小缓冲，非主工作集 |

### C. 多次 trial

`BenchmarkKernel` 若多次调用 `Brandes`（`-n` trials），则 **A 类对象也会在每次 trial 重新申请**。

**对 TAO hint：**  
- 可在单次 Brandes / 单源 ROI 内当常量基址绑的：`path_counts`、`scores`、`succ`、`queue.shared`、CSR。  
- **不要**假设跨源不变：`deltas`、`depths`。  
- **不要**把 `depth_index` 里的指针值当长期常量（只是当前源在 queue 上的边界）。

---

## 热点排序（按 CPU 时间占比）

### P0：`PBFS()` 内层邻居遍历 — 最核心

```68:80:/home/ice/src/sdc-benchmark/tao/gapbs/src/bc.cc
      for (auto q_iter = queue.begin(); q_iter < queue.end(); q_iter++) {
        NodeID u = *q_iter;
        for (NodeID &v : g.out_neigh(u)) {
          if ((depths[v] == -1) &&
              (compare_and_swap(depths[v], static_cast<NodeID>(-1), depth))) {
            lqueue.push_back(v);
          }
          if (depths[v] == depth) {
            succ.set_bit_atomic(&v - g_out_start);
            #pragma omp atomic
            path_counts[v] += path_counts[u];
          }
        }
      }
```

**为什么热：**
- 每个源点、每一层 frontier 都要扫全部出边
- 同一条边可能被多个 frontier 顶点重复访问（多最短路径）
- 多线程 + **CAS**（`depths[v]`）+ **原子 bitmap**（`succ`）+ **原子累加**（`path_counts`）
- 每层 `#pragma omp barrier` 同步

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| `out_index_[u]`, `out_neighbors_[·]` | CSR：索引顺序 + 块内顺序 | 相对友好 |
| `depths[v]` | 按邻居 id 随机 R/W | CAS 竞争 |
| `path_counts[v]` | 随机 RMW | `#pragma omp atomic` |
| `succ` bitmap | 按 **边在全局邻接数组中的偏移** 标位（`&v - g_out_start`） | 原子 CAS 写 word |

`succ` 用边偏移而非顶点 id 索引，是为省内存（`|E|` bit vs `|V|` 后继表），但前向阶段原子写密集。

---

### P1：反向 back-propagation 邻居遍历

```123:136:/home/ice/src/sdc-benchmark/tao/gapbs/src/bc.cc
    for (int d=depth_index.size()-2; d >= 0; d--) {
      #pragma omp parallel for schedule(dynamic, 64)
      for (auto it = depth_index[d]; it < depth_index[d+1]; it++) {
        NodeID u = *it;
        ScoreT delta_u = 0;
        for (NodeID &v : g.out_neigh(u)) {
          if (succ.get_bit(&v - g_out_start)) {
            delta_u += (path_counts[u] / path_counts[v]) * (1 + deltas[v]);
          }
        }
        deltas[u] = delta_u;
        scores[u] += delta_u;
      }
    }
```

**依赖链（`it` 类型 = `NodeID*`，扫的是 queue 里的 `NodeID`）：**

```text
depth_index[d]/[d+1]     → 两边界（很少）
  → [it, it_end) 连续读 u  → SEQ（queue.shared）
  → out_index_[u] + 邻接段 → IRR + SEQ → v
  → succ.get_bit(边偏移)
  → path_counts[u], path_counts[v], deltas[v]   （按 id，IRR）
  → 写 deltas[u], scores[u]
```

**为什么热：**
- 与 PBFS 同形态的 **CSR 扫边**，`d` **递减**（最远 → 源点）
- 无 CAS，但有 **浮点除法 + 累加** 和 `deltas[v]` **load-use 依赖链**
- `succ.get_bit` 过滤最短路上的后继边

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| queue 段内 `u` | SEQ | ★★（次要） |
| `out_index_[u]` | 按 u 间接 | ★★★ |
| `out_neighbors_` | 块内 SEQ | ★★ |
| `succ` bitmap | 按边偏移读 bit | ★★★ |
| `path_counts[u/v]` | 随机读 | ★★★★ |
| `deltas[v]` | 反向依赖读 | ★★★★（且每源可能换基址） |
| `scores[u]` | 累加写 | ★★★ |

kron20 上与 PBFS **近乎对半**；加 `-l` 看 `b` / `p` 最直接。

---

### P2：外层重复与 per-source 重置

每个源点：`path_counts.fill(0)`、`succ.reset()`（规模 `num_edges_directed()`）、`queue.reset()`。  
官方 `-i4 -n16` → 每 trial **4 个源点 × 16 trial = 64 次** 完整 PBFS + back-prop。  
`succ.reset()` 在大图上不可忽视，但仍一般小于 PBFS。

---

### P3：归一化 / 打印 / 验证 — 可忽略

`scores[n] / biggest_score`、`PrintTopScores`、`BCVerifier` 不在 `BenchmarkKernel` 计时内。

---

## 访存热点汇总

```
┌──────────────────────────────────────────────────────────────────┐
│  Brandes 访存热点（前向+反向）                                     │
├────────────────┬──────────────┬─────────────┬────────────────────┤
│ 数组            │ 访问模式      │ 预取难度     │ 基址生命周期         │
├────────────────┼──────────────┼─────────────┼────────────────────┤
│ depths[]       │ 随机 R/W+CAS  │ ★★★★★       │ 每源 PBFS 重申请     │
│ path_counts[]  │ 随机 RMW/读   │ ★★★★★       │ Brandes 内稳定       │
│ deltas[]       │ 反向随机读    │ ★★★★        │ 每源重申请           │
│ scores[]       │ 累加写        │ ★★★         │ Brandes 内稳定       │
│ succ bitmap    │ 按边偏移 R/W  │ ★★★         │ Brandes 内稳定       │
│ out_index_[]   │ 按 u 间接     │ ★★★         │ 图常量               │
│ out_neighbors_ │ 块内顺序      │ ★★          │ 图常量               │
│ queue.shared   │ 层内 SEQ      │ ★★（次要）   │ Brandes 内稳定       │
│ depth_index    │ 层边界指针    │ 可忽略       │ 容器稳；指针值每源变  │
└────────────────┴──────────────┴─────────────┴────────────────────┘
```

工作集：`depths` + `path_counts` + `deltas` + `scores` ≈ **|V| × (4+8+4+4) ≈ 20B/顶点**；`succ` ≈ **|E|/8** bit。大图易超 LLC。

---

## 从微架构角度的理解

```mermaid
flowchart TD
    S[源点 source] --> BFS[PBFS 按层扩展]
    BFS --> E["for v in out_neigh(u)"]
    E --> D1{depths[v] 首次?}
    D1 -->|是| CAS[CAS depths[v]]
    D1 -->|同层| AT["atomic succ + path_counts"]
    CAS --> Q[入队下一层]
    AT --> E
    Q --> BFS
    BFS --> BP[back-prop 最远→最近]
    BP --> E2["for v in out_neigh(u)"]
    E2 --> BIT{succ bit?}
    BIT -->|是| FP["delta += pc[u]/pc[v]*(1+deltas[v])"]
    FP --> E2
```

1. **前向阶段内存 + 同步受限**：原子 CAS/RMW 多，IPC 偏低
2. **反向阶段计算受限**：除法与 `deltas` 依赖链
3. **与 BFS 类似但更重**：每个源点 **两遍** 全图级 CSR 遍历 + 更多元数据数组

---

## 各阶段时间占比（kron20 gprof 实测 + 经验估计）

| 阶段 | 占比（估） | kron20 gprof | 主要操作 |
|------|-----------|--------------|----------|
| **PBFS（前向）** | **55–75%** | **54.3%** self | CSR 扫边 + CAS + 原子 path_count/succ |
| **back-prop（反向）** | **20–40%** | **45.3%**（Brandes self） | CSR 扫边 + bitmap 过滤 + FP delta |
| per-source reset + 归一化 | **<5%** | — | `succ.reset()` 等 |

**kron20 实测：** Trial Avg **381.6 ms**（20 trials，`-i1`）。实际比例用 `./bc ... -l` 看 `b` / `p` 最直接。

---

## 验证热点的 profiling 命令

```bash
OMP_NUM_THREADS=1 perf record -g ./bc -g 20 -i 1 -n 1
perf report --stdio | head -60
# 关注：PBFS, Brandes, g.out_neigh 内层循环

# 两阶段耗时
./bc -g 20 -i 1 -n 1 -l
```

多线程时 PBFS 原子竞争会进一步放大前向阶段占比；单线程更适合分析访存 PC。

---

## 和预取研究的关系

`bc` 在 `hotspot.md` §2.5 标为 **IRR/CSR 为主**，与 `bfs` 同类、比 `cc` 的 UF 链略规整：

| 方法 | 预期 |
|------|------|
| **Stride / BOP** | **差**；`depths`/`path_counts`/`deltas` 随机索引 |
| **Bingo / SPP+PPF** | **中**；CSR 邻接块有 spatial 收益 |
| **Berti / IPCP / Pythia** | **中–良**；Berti 论文 GAP 集含 `bc-*` trace |
| **SDC / TAO** | **有潜力**：profile PBFS/back-prop 中 CSR 邻接迭代与 `deltas[v]` load |

ChampSim trace 或手工 hint 时，优先 profile 的 PC：

1. `PBFS` 内层 `g.out_neigh(u)` 循环（`out_neighbors_` load）
2. `path_counts[v]` / `depths[v]` 的随机 load（前向）
3. back-prop 中 `deltas[v]` 与 `succ.get_bit` 所在循环

**TAO hint 候选：**

| 数组 | 引擎 | 说明 |
|------|------|------|
| `out_neighbors_[]` | **Stride** | 块内连续；图常量基址 |
| `out_index_[u]` | **Indirect** | trigger=`u`；图常量 |
| `depths[v]` / `path_counts[v]` | **Indirect** | 前向主 IRR；`depths` 每源换基址须重配或限 ROI |
| `deltas[v]` | **Indirect** | 反向主 IRR；**每源换基址** |
| `path_counts` / `scores` / `succ` / queue | 视模式 | Brandes 内基址稳；queue 为次要 SEQ |
| `depth_index` | 一般不绑 | 仅层边界，流量极小 |

---

## 结论

| 问题 | 答案 |
|------|------|
| 最热函数/循环？ | kron20 gprof：**`PBFS()` 54.3%** + **`Brandes()` 45.3%**（近乎对半） |
| 次热点？ | **back-prop 同形态邻居循环** |
| 队列热吗？ | `SlidingQueue` **有 SEQ 流量、非主瓶颈** |
| 谁每源换地址？ | **`deltas`、`depths`**；`path_counts`/`scores`/`succ`/`queue` 在一次 Brandes 内稳定 |
| 与 `cc` 比？ | 更少 UF 指针链，但 **每源两遍扫边 + 更多原子** |
| 官方参数？ | **`-f <图> -i4 -n16`**；trace 常用 **`-i1 -n1`** + 单线程 |
| 值不值得 profile？ | **值得**；Berti 等论文 GAP 集含 bc，是不规则图核代表之一 |

### 需优化的访存对象（按预取难度：难 → 易）

**难度数字：** `1` = **最难 / 最该优先打**（流量 × 不规则 × HW 难覆盖）；数字越大越容易、越靠后。不是源码执行顺序。

| 难度 | 数据 | 模式 | 阶段 | 运行时是否重复申请 |
|------|------|------|------|-------------------|
| **1（最难）** | `depths[v]` | IRR + CAS | PBFS | **是：每个 source 进 PBFS 都 new**（基址每源可能变） |
| **1（最难）** | `path_counts[v]`（及读 `path_counts[u]`） | IRR；前向 atomic RMW，反向只读 | 两阶段 | **否（一次 Brandes 内）**：只 `fill(0)`；多次 trial 调 Brandes 会重申请 |
| **2** | `deltas[v]`（写 `deltas[u]`） | IRR + 浮点依赖 | back-prop | **是：每个 source 都 new** |
| **3** | `succ` bitmap | 按边偏移 R/W | 两阶段 | **否（一次 Brandes 内）**：只 `reset()` |
| **3** | `out_index_[u]` | 按 u 间接 | 两阶段 | **否：图常量** |
| **4** | `out_neighbors_` 邻接段 | 块内 SEQ | 两阶段 | **否：图常量** |
| **5** | `scores[u]` | 按 u 累加写 | back-prop | **否（一次 Brandes 内）** |
| **6（最易/次要）** | `queue.shared` 层内 `u` | SEQ | 两阶段 | **否（一次 Brandes 内）**：只 `reset()` |
| **—（可不优化）** | `depth_index` | 层边界指针，流量极小 | 组织用 | 容器稳；**指针值每源变**，一般不绑 |

**实施提示：** 先打难度 1–2 的 IRR（注意 `depths`/`deltas` 换源要重配 hint 或把 ROI 限在单源内）；CSR（3–4）用 stride/indirect 绑图基址即可长期有效；queue/scores 边际小。
