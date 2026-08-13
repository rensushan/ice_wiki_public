`bfs.cc` 实现的是 GAPBS 的 **Direction-Optimizing BFS（DOBFS）**（Beamer 等 SC'12）：在 top-down（TD）与 bottom-up（BU）之间按 `alpha`/`beta` 切换，用 `SlidingQueue` 表示前沿、`Bitmap` 表示 BU 阶段的已访问集合。

## 构造真实的图

```bash
cd tao/gapbs
make bench-graphs
```

## 运行

```bash
# GAP 官方 benchmark（bench.mk）
./bfs -f benchmark/graphs/twitter.sg -n64

# ChampSim trace / 单源 profiling
OMP_NUM_THREADS=1 ./bfs -f benchmark/graphs/twitter.sg -n1

# 小图快速试跑 + 分段耗时
OMP_NUM_THREADS=1 ./bfs -g 20 -n 1 -l
```

| 参数 | 含义 |
|------|------|
| **`-n N`** | **N 次 trial**（官方 **64**），每次随机选一个源点 |
| **`-r ID`** | 固定源点（与 `-n` 多次 trial 同用会告警） |
| **`-l`** | 打印 DOBFS 各阶段耗时：`i`/`td`/`bu`/`e`/`c` |

---

## 实测热点（gprof）— 图相关，kron ≠ road

CPU 时间占比**强烈依赖图结构**（直径 / 度分布 → 前沿宽度 → DO 切不切 BU），不能只用一张图定「谁是 P0」。

### kron20（小世界、中等度）→ **BU 主导**

**Setup：** SERIAL（`-pg -no-pie`），`OMP_NUM_THREADS=1`，`benchmark/graphs/kron20.sg`（2^20 顶点，≈15.7M 无向边，deg≈14），**200 trials**。

| % self | 函数 |
|--------|------|
| **73.2%** | `BUStep` |
| 17.1% | `DOBFS` |
| 6.2% | `BitmapToQueue` |
| **2.9%** | `TDStep` |

**Avg Trial Time：** 25.6 ms。宽前沿时 BU 全图入边扫描压过 TD。

### road（低度、大直径）→ **TD 主导**

**Setup：** 同上 SERIAL `-pg -no-pie`，`OMP_NUM_THREADS=1`，图 `~/dataset/gapbs/road.sg`（**23,947,347** 顶点，**57,708,624** directed edges，**deg≈2**），**50 trials**。

| % self | 函数 |
|--------|------|
| **81.1%** | `TDStep` |
| 7.4% | `DOBFS` |
| **6.1%** | `BUStep` |
| 4.6% | `BitmapToQueue` |

**Avg Trial Time：** 1.143 s。`-l` 单源示例：约 **6792** 次 `td` 层 vs **5** 次 `bu`；低度大直径下前沿长期偏窄，多数时间停在 TD，偶发短 BU。

```bash
cd tao/gapbs
# 注意 Makefile 变量是 CXX_FLAGS（不是 CXXFLAGS）
make bfs SERIAL=1 'CXX_FLAGS=-std=c++11 -O3 -Wall -pg -no-pie'

OMP_NUM_THREADS=1 GMON_OUT_PREFIX=profile_runs/bfs_kron20 \
  ./bfs -f benchmark/graphs/kron20.sg -n200
gprof ./bfs profile_runs/bfs_kron20.* > profile_runs/bfs_gprof.txt

OMP_NUM_THREADS=1 GMON_OUT_PREFIX=profile_runs/bfs_road \
  ./bfs -f ~/dataset/gapbs/road.sg -n50
gprof ./bfs profile_runs/bfs_road.* > profile_runs/bfs_road_gprof.txt

# 分段耗时（road 上单层 td 常 <1e-5s，打印成 0.00000；看层数 + gprof）
OMP_NUM_THREADS=1 ./bfs -f ~/dataset/gapbs/road.sg -n1 -l
```

原始 gprof：`tao/gapbs/profile_runs/bfs_gprof.txt`（kron20）、`tao/gapbs/profile_runs/bfs_road_gprof.txt`（road）。

---

## 整体执行流程

`main` → `BenchmarkKernel` → `DOBFS()`：

```122:178:/home/ice/src/sdc-benchmark/tao/gapbs/src/bfs.cc
pvector<NodeID> DOBFS(const Graph &g, NodeID source, ...) {
  parent = InitParent(g);          // parent[v]<0 编码未访问 + 出度
  parent[source] = source;
  queue.push_back(source);
  while (!queue.empty()) {
    if (scout_count > edges_to_check / alpha) {
      QueueToBitmap(queue, front); // TD → BU 切换
      do { BUStep(...); } while (...);
      BitmapToQueue(g, front, queue); // BU → TD 切换
    } else {
      TDStep(g, parent, queue);    // top-down 扩展
      queue.slide_window();
    }
  }
  return parent;
}
```

```
DOBFS()
 ├─ InitParent()           ← 一次性 |V| 扫描，写 parent[]
 └─ while (queue 非空)
      ├─ TDStep()          ← road 上墙钟 P0；访存最不规则（parent CAS）
      ├─ QueueToBitmap()   ← 前沿 → Bitmap
      ├─ BUStep()          ← kron20 上墙钟 P0；全图扫描 + 入边 CSR
      └─ BitmapToQueue()   ← Bitmap → 前沿队列
```

**`parent[]` 编码**（省掉单独 `scout_count` 数组）：

- `parent[x] < 0`：未访问，且 `parent[x] = -out_degree(x)`（预存出度供 TD 统计）
- `parent[x] >= 0`：已访问，`parent[x]` 为 BFS 树中的父节点

默认 `alpha=15`、`beta=18`：当 `scout_count > |E|/alpha` 时切 BU；BU 内当 `awake_count` 不再增长或 `<= |V|/beta` 时退回 TD。

---

## 热点循环（两套排序不要混）

| 排序维度 | kron20 | road |
|----------|--------|------|
| **墙钟 / gprof self** | **BUStep ≫ TDStep**（73% vs 3%） | **TDStep ≫ BUStep**（81% vs 6%） |
| **访存不规则 / 预取难度** | 仍是 TD 的 `parent[v]` CAS 最难 | 同左；且 road 上它还是时间大头 |

下面按**循环形态**讲解；谁算「CPU P0」看上表与具体图。

### `TDStep()` — top-down 前沿扩展

```74:85:/home/ice/src/sdc-benchmark/tao/gapbs/src/bfs.cc
    for (auto q_iter = queue.begin(); q_iter < queue.end(); q_iter++) {
      NodeID u = *q_iter;
      for (NodeID v : g.out_neigh(u)) {
        NodeID curr_val = parent[v];
        if (curr_val < 0) {
          if (compare_and_swap(parent[v], curr_val, u)) {
            lqueue.push_back(v);
            scout_count += -curr_val;
          }
        }
      }
    }
```

**为什么热：**

- BFS 早期前沿小时，几乎全程跑 TD
- 每个前沿顶点 `u` 扫全部出边 `out_neigh(u)`
- 对未访问邻居 `v` 做 **CAS** 写 `parent[v]`，竞争与 false sharing 明显
- `scout_count += -curr_val` 利用 parent 中预存的出度，避免额外读 `out_degree(v)`

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| `out_index_[u]`, `out_neighbors_[·]` | CSR：索引按队列 + 块内顺序 | ★★ 中 |
| `parent[v]` | 按邻居 id **随机 RMW + CAS** | ★★★★★ |
| `queue` / `lqueue` | 前沿顶点顺序 push | ★★ 中 |

与 `bc` 的 `PBFS` 前向阶段高度相似（同一类 CAS + CSR 扫边），但无 `path_counts` / `succ` bitmap。

---

### `BUStep()` — bottom-up 全图扫描

```50:62:/home/ice/src/sdc-benchmark/tao/gapbs/src/bfs.cc
  for (NodeID u=0; u < g.num_nodes(); u++) {
    if (parent[u] < 0) {
      for (NodeID v : g.in_neigh(u)) {
        if (front.get_bit(v)) {
          parent[u] = v;
          awake_count++;
          next.set_bit(u);
          break;
        }
      }
    }
  }
```

**为什么热：**

- 前沿变宽时 DO 算法切 BU，**每层对全图 |V| 顶点扫描**
- 未访问顶点 `u` 扫 **入边** `in_neigh(u)`，查 `front` bitmap 是否有父节点在前沿
- 无 CAS，但 **O(|V| × 平均入度)** 的工作量在宽前沿阶段仍很大
- 无向图 CSR 存双向边，`in_neigh` 与 `out_neigh` 对称

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| `parent[u]` | **顺序**读（按 u 递增） | ★★ 友好 |
| `in_index_[u]`, `in_neighbors_[·]` | CSR 入边：块内顺序 | ★★ 中 |
| `front` / `next` bitmap | 按顶点 id `get_bit` / `set_bit` | ★★★ |

**g20 / kron20：** 前沿变宽后 **BU 占主导**（gprof **73.2%**）。**road：** 相反，BU 只偶发切入（gprof **6.1%**），墙钟在 TD。

---

### `InitParent()` — 初始化

```114:119:/home/ice/src/sdc-benchmark/tao/gapbs/src/bfs.cc
  for (NodeID n=0; n < g.num_nodes(); n++)
    parent[n] = g.out_degree(n) != 0 ? -g.out_degree(n) : -1;
```

一次性 **|V|** 顺序写 `parent[]` + 读 `out_degree`；相对主循环可忽略（`-l` 中 `i` ≈ 2ms @ g20）。

---

### 方向切换辅助 — `QueueToBitmap` / `BitmapToQueue`

```92:111:/home/ice/src/sdc-benchmark/tao/gapbs/src/bfs.cc
void QueueToBitmap(...)   // 前沿队列 → front bitmap（原子 set_bit）
void BitmapToQueue(...)   // front bitmap → 队列（全图扫描 |V|）
```

每次 TD↔BU 切换调用；`BitmapToQueue` 又一次 **|V| 扫描**。次数少于 `BUStep` 内层循环，但大图上不可完全忽略。

---

## 访存热点汇总

```
┌──────────────────────────────────────────────────────────────────┐
│  DOBFS 访存热点                                                   │
├──────────────┬──────────────┬────────────────────────────────────┤
│ 数组          │ 访问模式      │ 预取难度                            │
├──────────────┼──────────────┼────────────────────────────────────┤
│ parent[]     │ TD:随机CAS   │ ★★★★★（IRR）                       │
│              │ BU:顺序读    │ ★★（SEQ）                          │
│ out_neighbors│ TD:块内顺序   │ ★★                                 │
│ in_neighbors │ BU:块内顺序   │ ★★                                 │
│ out/in_index │ 按 u 递增     │ ★★                                 │
│ front bitmap │ 按顶点 id 读  │ ★★★                                │
│ SlidingQueue │ 前沿顺序      │ ★★                                 │
└──────────────┴──────────────┴────────────────────────────────────┘
```

工作集：主要 **`parent[]`**（|V| × 4B）+ **两个 Bitmap**（各 |V| bit）+ **SlidingQueue**（|V| 容量）+ CSR 图。比 `bc` 少 `path_counts`/`deltas`/`succ`，但 DO 切换带来额外全图扫描。

---

## 从微架构角度的理解

```mermaid
flowchart TD
    S[源点 source] --> INIT[InitParent: parent=-deg]
    INIT --> LOOP{queue 空?}
    LOOP -->|否| SWITCH{scout > |E|/α?}
    SWITCH -->|否 TD| TD[TDStep: 前沿 u 扫 out_neigh]
    TD --> CAS[CAS parent[v]=u]
    CAS --> LOOP
    SWITCH -->|是 BU| Q2B[QueueToBitmap]
    Q2B --> BU[BUStep: 全图 u 扫 in_neigh]
    BU --> BIT{front[v]?}
    BIT -->|是| SET[parent[u]=v]
    SET --> BU
    BU --> B2Q[BitmapToQueue]
    B2Q --> LOOP
    LOOP -->|是| DONE[修正 parent=-1]
```

1. **TD 阶段**：内存 + 同步受限（`parent[v]` CAS），与 `bc` PBFS 同类。
2. **BU 阶段**：计算较轻，但 **全图扫描 + 入边遍历**，带宽与 cache 容量压力大。
3. **相对 `cc`**：无 UF 指针链 `parent[parent[·]]`；**相对 `bc`**：无浮点 back-prop，但 DO 双模式使热点在 TD/BU 间切换。

---

## 各阶段时间占比（gprof 实测）

| 阶段 | kron20（200 trials） | road（50 trials） | 主要操作 |
|------|----------------------|-------------------|----------|
| **BUStep** | **73.2%** self | **6.1%** self | 全图扫描 + 入边 + bitmap |
| **TDStep** | **2.9%** self | **81.1%** self | 出边 CSR + `parent` CAS |
| `BitmapToQueue` 等 | 6.2% | 4.6% | BU→TD 转换 |
| Avg trial | **25.6 ms** | **1.143 s** | |

**结论：** 小世界/中高平均度（kron、twitter 类）→ BU 易成墙钟热点；道路网低度大直径 → **几乎全程 TD**。预取研究若只看 kron，会低估 `parent[v]` CAS 的实际时间权重。

---

## 验证热点的 profiling 命令

```bash
cd tao/gapbs
OMP_NUM_THREADS=1 ./bfs -g 20 -n 1 -l          # 分段耗时
OMP_NUM_THREADS=1 ./bfs -f benchmark/graphs/kron20.sg -n200  # kron20 benchmark

# gprof（SERIAL -pg -no-pie 构建）：
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=bfs_kron20 ./bfs -f benchmark/graphs/kron20.sg -n200
gprof ./bfs gmon.file

# 若已安装 perf：
OMP_NUM_THREADS=1 perf record -g ./bfs -g 20 -n 4
perf report --stdio | head -60
# 关注：TDStep, BUStep, DOBFS, g.out_neigh / g.in_neigh 内层循环
```

多线程时 TD 的 CAS 竞争会进一步放大；**单线程 trace** 更适合 ChampSim / 手工 hint profiling。

---

## 和预取研究的关系

`bfs` 在 `hotspot.md` §2.2 标为 **CSR SEQ + parent IRR**，论文评测常见（Berti / Pythia GAP 集含 `bfs-*` trace）。

| 方法 | 预期 |
|------|------|
| **Stride / BOP** | **差–中**；仅邻接数组块内有效，`parent[v]` 随机 |
| **Bingo / SPP+PPF** | **中**；L2 对 CSR 邻接 footprint 有收益 |
| **Berti / IPCP / Pythia** | **中–良**；学习 per-IP 的间接模式 |
| **SDC / TAO** | **有潜力**：stride 绑 CSR；TD 可对 `parent` 做 indirect |

### TAO hint 候选

| 数组 / 阶段 | 引擎 | 说明 |
|-------------|------|------|
| `out_neighbors_[]`（TD） | **Stride** gid=0/1 | 与 `cc` 相同，绑 `out_index` + `out_neighbors` |
| `in_neighbors_[]`（BU） | **Stride** | 无向图需绑 **入边** CSR（`in_index` / `in_neighbors`） |
| `parent[v]`（TD） | **Indirect** | trigger=`out_neighbors` 或 frontier 访问路径 → couple=`parent`；CAS 写使 mirror 易 stale |
| `parent[u]`（BU） | **Stride** | 全图顺序扫，stride 直接覆盖 |
| `front` bitmap | **Stride** | 按顶点 id 访问，与 `parent` 顺序扫部分重叠 |

ChampSim trace 或手工 hint 时，**优先 profile 的 PC**：

1. `TDStep` 内层 `g.out_neigh(u)` → `parent[v]` CAS 路径
2. `BUStep` 内层 `g.in_neigh(u)` → `front.get_bit(v)` 路径
3. `BitmapToQueue` 全图 `bm.get_bit(n)` 扫描（若 BU 占比高）

---

## 与 `cc` / `bc` 对比

| 维度 | **bfs** | **cc** | **bc** |
|------|---------|--------|--------|
| 核心算法 | DO BFS | Afforest UF | Brandes BFS + back-prop |
| 最热循环 | `TDStep` / `BUStep` | `Link` / `Compress` | `PBFS` / back-prop |
| 最不规则访存 | `parent[v]` CAS | `comp[comp[·]]` | `depths`/`path_counts` 原子 |
| CSR 顺序段 | **有**（TD 出边 + BU 入边） | 有（边遍历） | 有 |
| 全图扫描 | **BU 阶段** | `Compress`（3 次） | 无（按层 frontier） |
| 官方参数 | **`-f <图> -n64`** | `-f <图> -n16` | `-f <图> -i4 -n16` |

---

## 结论

| 问题 | 答案 |
|------|------|
| 最热函数/循环？ | **看图**：kron20 → **`BUStep` 73%**；road → **`TDStep` 81%**；窄前沿/大直径抬高 TD |
| 访存主型？ | **CSR 中等规则 + `parent[]` IRR（TD）/ SEQ（BU）** |
| 与 `cc` 比？ | 无 UF 链；有 **DO 双模式** 与 **bitmap 前沿** |
| 与 `bc` 比？ | 共享 BFS 式 CAS，但 **无** path_counts / 浮点 back-prop |
| 官方参数？ | **`-f <图> -n64`**；trace 常用 **`-n1` + 单线程** |
| 值不值得 profile？ | **值得**；GAP 论文主流量表之一，Pythia/Berti 均含 `bfs` trace |
