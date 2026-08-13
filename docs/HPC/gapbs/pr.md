`pr.cc` 实现的是 GAPBS 的 **PageRank（Pull + Gauss-Seidel）**：按入边 pull 聚合邻居贡献，**同一轮迭代内**立刻更新 `scores[u]` 并写回 `outgoing_contrib[u]`，无需原子操作，收敛通常快于 Jacobi 版 `pr_spmv`。

## 构造真实的图

```bash
cd tao/gapbs
make bench-graphs
```

## 运行

```bash
# GAP 官方 benchmark（bench.mk）
./pr -f benchmark/graphs/twitter.sg -i1000 -t1e-4 -n16

# ChampSim trace / 单 kernel profiling
OMP_NUM_THREADS=1 ./pr -f benchmark/graphs/twitter.sg -i1000 -t1e-4 -n1

# 小图快速试跑 + 收敛日志
OMP_NUM_THREADS=1 ./pr -g 20 -i100 -t1e-4 -n1 -l
```

| 参数 | 含义 |
|------|------|
| **`-i N`** | 最大迭代次数（官方 **1000**） |
| **`-t ε`** | 全局 L1 误差阈值（官方 **1e-4**） |
| **`-n N`** | **N 次 trial**（官方 **16**） |
| **`-l`** | 每轮打印 **迭代号 + 累计误差**（不是分段耗时） |

---

## 实测热点（gprof, kron20）

**Setup：** SERIAL 构建（`-pg -no-pie`），`OMP_NUM_THREADS=1`，图 `benchmark/graphs/kron20.sg`，**20 trials**，`-i1000 -t1e-4`，加载序列化图。

| % self | 函数 |
|--------|------|
| **≈99.7%** | `PageRankPullGS` |

**Avg Trial Time：** 435.9 ms

几乎全部时间在 Gauss-Seidel pull 主循环（`in_neigh` gather + `outgoing_contrib[v]` 随机读），无 CAS、无多阶段拆分。

```bash
cd tao/gapbs
# SERIAL: make clean && make CXXFLAGS+='-pg -no-pie'
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=pr_kron20 ./pr -f benchmark/graphs/kron20.sg -i1000 -t1e-4 -n20
gprof ./pr gmon.file
```

原始 gprof：`tao/gapbs/profile_runs/pr_gprof.txt`

---

## 整体执行流程

`main` → `BenchmarkKernel` → `PageRankPullGS()`：

```34:60:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr.cc
pvector<ScoreT> PageRankPullGS(const Graph &g, int max_iters, ...) {
  // 初始化 scores[]、outgoing_contrib[]
  for (int iter=0; iter < max_iters; iter++) {
    for (NodeID u=0; u < g.num_nodes(); u++) {
      incoming_total = Σ outgoing_contrib[v]  (v ∈ in_neigh(u))
      scores[u] = base + kDamp * incoming_total
      outgoing_contrib[u] = scores[u] / out_degree(u)   // 同轮立即可见
    }
    if (error < epsilon) break;
  }
}
```

```
PageRankPullGS()
 ├─ 初始化 scores / outgoing_contrib     ← P2：一次性 |V|
 └─ for iter until ε
      └─ parallel for u ∈ [0, |V|)       ← P0：主热点
           ├─ 内层 in_neigh(u) gather    ← P0：CSR + IRR
           ├─ 写 scores[u]
           └─ 写 outgoing_contrib[u]
```

与 `pr_spmv` 的区别：**不拆成两阶段**，`outgoing_contrib` 在本轮 u 循环里随写随用（Gauss-Seidel），少一次全图 pass。

---

## 热点排序（按 CPU 时间占比）

### P0：主迭代 — `in_neigh` gather + `outgoing_contrib[v]`

```46:54:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr.cc
    for (NodeID u=0; u < g.num_nodes(); u++) {
      ScoreT incoming_total = 0;
      for (NodeID v : g.in_neigh(u))
        incoming_total += outgoing_contrib[v];
      ScoreT old_score = scores[u];
      scores[u] = base_score + kDamp * incoming_total;
      error += fabs(scores[u] - old_score);
      outgoing_contrib[u] = scores[u] / g.out_degree(u);
    }
```

**为什么热：**

- 每轮对 **全部 |V| 顶点** 执行，直到误差 < ε（g20 上约 **11 轮**）
- 内层按 **入边 CSR** 遍历，对每个邻居 `v` 读 `outgoing_contrib[v]`
- 浮点累加 + 除法，计算量 ∝ **|E|** × 迭代次数
- Pull 方向避免原子，但 **`outgoing_contrib` 按邻居 id 随机读** 仍是主瓶颈

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| `in_index_[u]`, `in_neighbors_[·]` | CSR：按 u 顺序 + 块内顺序 | ★★ 中 |
| `outgoing_contrib[v]` | 按邻居 id **随机读** | ★★★★ IRR |
| `scores[u]` | 按 u **顺序** RMW | ★★ 友好 |
| `out_degree(u)` | 顺序读索引 | ★★ |

---

### P2：初始化 — `scores` / `outgoing_contrib` 填充

```38:42:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr.cc
  pvector<ScoreT> scores(g.num_nodes(), init_score);
  pvector<ScoreT> outgoing_contrib(g.num_nodes());
  for (NodeID n=0; n < g.num_nodes(); n++)
    outgoing_contrib[n] = init_score / g.out_degree(n);
```

一次性 **|V|** 顺序写；相对主循环可忽略。

---

### P3：`PrintTopScores` / `PRVerifier`（benchmark 框架）

仅在 trial 结束或验证时运行，**不计入 kernel 热点**。

---

## 访存热点汇总

```
┌──────────────────────────────────────────────────────────────────┐
│  PageRankPullGS 访存热点                                          │
├──────────────┬──────────────┬────────────────────────────────────┤
│ 数组          │ 访问模式      │ 预取难度                            │
├──────────────┼──────────────┼────────────────────────────────────┤
│ in_neighbors │ 块内顺序      │ ★★                                 │
│ in_index     │ 按 u 递增     │ ★★                                 │
│ outgoing_contrib│ 按 v 随机读 │ ★★★★（IRR）                        │
│ scores       │ 按 u 顺序     │ ★★                                 │
└──────────────┴──────────────┴────────────────────────────────────┘
```

工作集：**`scores[]` + `outgoing_contrib[]`**（各 |V| × 4B）+ CSR 图。无 CAS，比 `sssp`/`bfs` 同步压力小，但 **IRR gather** 与迭代次数叠加后带宽压力大。

---

## 从微架构角度的理解

```mermaid
flowchart TD
    INIT[初始化 scores / outgoing_contrib] --> LOOP{iter < max 且 error ≥ ε?}
    LOOP -->|是| SCAN[parallel for u: 扫 in_neigh]
    SCAN --> GATHER[累加 outgoing_contrib[v]]
    GATHER --> UPD[scores[u] = base + damp×sum]
    UPD --> SCALE[outgoing_contrib[u] = scores[u]/deg]
    SCALE --> ERR[归约 error]
    ERR --> LOOP
    LOOP -->|否| DONE[返回 scores]
```

1. **规则段**：CSR 邻接表遍历，stride/BOP 对 `in_neighbors` 有一定帮助。
2. **不规则段**：`outgoing_contrib[v]` 地址由邻居 id 决定，经典 **SpMV pull** 模式。
3. **相对 `pr_spmv`**：融合更新减少一轮全图 pass，通常更快、访存次数更少。

---

## 各阶段时间占比（kron20 gprof 实测 + 经验）

| 阶段 | 占比（估） | kron20 gprof / g20 量级 | 说明 |
|------|-----------|-------------------------|------|
| **主迭代 gather** | **>95%** | **≈99.7%** self（kron20 gprof）；Trial **435.9 ms** | 收敛至 `-t1e-4` |
| 初始化 | **<3%** | 含在 Trial 内 | 一次 |V| 写 |
| Verifier | 框架外 | — | 仅验证时 |

**`-l` 输出的是每轮 L1 误差**，不是秒数。g20 上误差从 **1.09 → 1e-4** 约 11 步。

---

## 验证热点的 profiling 命令

```bash
cd tao/gapbs
OMP_NUM_THREADS=1 ./pr -g 20 -i100 -t1e-4 -n1 -l    # 收敛曲线（误差）
OMP_NUM_THREADS=1 ./pr -g 20 -i100 -t1e-4 -n1       # Trial Time

# 若已安装 perf：
OMP_NUM_THREADS=1 perf record -g ./pr -g 20 -i50 -t1e-4 -n1
perf report --stdio | head -60
# 关注：PageRankPullGS 内层 in_neigh 循环、g.in_neigh 解引用
```

多线程时 `schedule(dynamic, 16384)` 带来负载均衡开销；**单线程 trace** 更适合 ChampSim。

---

## 和预取研究的关系

`pr` 是 GAP 官方流量表核心项（`pr-twitter` 等），访存为 **CSR SEQ + outgoing_contrib IRR**，与图 SpMV pull 同类。

| 方法 | 预期 |
|------|------|
| **Stride / BOP** | **中**；邻接块内有效，`outgoing_contrib[v]` 随机 |
| **Bingo / SPP+PPF** | **中–良**；重复迭代使 CSR  footprint 可学习 |
| **Berti / IPCP / Pythia** | **良**；固定 PC 下 gather 模式稳定 |
| **SDC / TAO** | **有潜力**：stride 绑 `in_neighbors`；indirect 绑 `outgoing_contrib` |

### TAO hint 候选

| 数组 | 引擎 | 说明 |
|------|------|------|
| `in_neighbors_[]` | **Stride** | 绑 `in_index` + `in_neighbors` |
| `outgoing_contrib[v]` | **Indirect** | trigger=`in_neighbors` → couple=`outgoing_contrib` |
| `scores[u]` | **Stride** | 外层 u 顺序扫，易覆盖 |

优先 profile 的 PC：`PageRankPullGS` 内层 `for (NodeID v : g.in_neigh(u))` 的 load `outgoing_contrib[v]`。

---

## 与 `pr_spmv` / `bfs` / `cc` 对比

| 维度 | **pr** | **pr_spmv** | **bfs** | **cc** |
|------|--------|-------------|---------|--------|
| 更新风格 | Gauss-Seidel pull | Jacobi pull（两阶段） | BFS 层扩展 | UF hook |
| 最热循环 | `in_neigh` gather | 同左 + 额外 scale pass | `TDStep` CAS | `Link` |
| 最不规则访存 | `outgoing_contrib[v]` | 同左 | `parent[v]` CAS | `comp[comp[·]]` |
| 原子操作 | 无 | 无 | CAS | CAS |
| 官方参数 | **`-i1000 -t1e-4 -n16`** | 同左 | `-n64` | `-n16` |

---

## 结论

| 问题 | 答案 |
|------|------|
| 最热函数/循环？ | **`PageRankPullGS` ≈99.7%** — `in_neigh` + `outgoing_contrib[v]` gather |
| 访存主型？ | **CSR 中等规则 + outgoing_contrib IRR** |
| 与 `pr_spmv` 比？ | 融合 Gauss-Seidel，**少一轮全图 pass**，通常更快 |
| 官方参数？ | **`-f <图> -i1000 -t1e-4 -n16`** |
| 值不值得 profile？ | **值得**；GAP 主流量表，Pythia/Berti 均含 `pr` trace |


### TAO hint 

| 数组 | 引擎 | 说明 |
|------|------|------|
| `in_neighbors_[]` | **Stride** | 绑 `in_index` + `in_neighbors` |
| `outgoing_contrib[v]` | **Indirect** | trigger=`in_neighbors` → couple=`outgoing_contrib` |
| `scores[u]` | **Stride** | 外层 u 顺序扫，易覆盖 |
