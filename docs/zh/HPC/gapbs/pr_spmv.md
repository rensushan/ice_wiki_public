`pr_spmv.cc` 实现的是 GAPBS 的 **legacy PageRank（Pull + Jacobi / SpMV 风格）**：每轮先全图计算 `outgoing_contrib = scores/deg`，再 pull 聚合入边贡献更新 `scores`。新值 **下一轮才可见**，与 `pr.cc` 的 Gauss-Seidel 融合更新相对。

## 构造真实的图

```bash
cd tao/gapbs
make bench-graphs
```

## 运行

```bash
# 与 pr 相同官方参数（bench.mk 用 pr，非 pr_spmv）
./pr_spmv -f benchmark/graphs/twitter.sg -i1000 -t1e-4 -n16

OMP_NUM_THREADS=1 ./pr_spmv -f benchmark/graphs/twitter.sg -i1000 -t1e-4 -n1
OMP_NUM_THREADS=1 ./pr_spmv -g 20 -i100 -t1e-4 -n1 -l
```

| 参数 | 含义 |
|------|------|
| **`-i N`** | 最大迭代次数（**1000**） |
| **`-t ε`** | L1 误差阈值（**1e-4**） |
| **`-n N`** | trial 次数（官方 benchmark 用 **pr** 时为 **16**） |
| **`-l`** | 每轮 **迭代号 + 累计误差** |

---

## 实测热点（gprof, kron20）

**Setup：** SERIAL 构建（`-pg -no-pie`），`OMP_NUM_THREADS=1`，图 `benchmark/graphs/kron20.sg`，**20 trials**，`-i1000 -t1e-4`，加载序列化图。

| % self | 函数 |
|--------|------|
| **≈99.7%** | `PageRankPull` |

**Avg Trial Time：** 463.5 ms

Jacobi 两阶段（scale + pull gather）整体折叠在 `PageRankPull` 内；Phase 1 scale 与 Phase 2 gather 均未单独出现在 gprof flat profile 顶层。

```bash
cd tao/gapbs
# SERIAL: make clean && make CXXFLAGS+='-pg -no-pie'
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=pr_spmv_kron20 ./pr_spmv -f benchmark/graphs/kron20.sg -i1000 -t1e-4 -n20
gprof ./pr_spmv gmon.file
```

原始 gprof：`tao/gapbs/profile_runs/pr_spmv_gprof.txt`

---

## 整体执行流程

`main` → `PageRankPull()`：

```35:60:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr_spmv.cc
pvector<ScoreT> PageRankPull(const Graph &g, int max_iters, ...) {
  for (int iter=0; iter < max_iters; iter++) {
    // Phase 1: scale
    for (NodeID n=0; n < g.num_nodes(); n++)
      outgoing_contrib[n] = scores[n] / g.out_degree(n);
    // Phase 2: pull + update
    for (NodeID u=0; u < g.num_nodes(); u++) {
      incoming_total = Σ outgoing_contrib[v]  (v ∈ in_neigh(u))
      scores[u] = base + kDamp * incoming_total
    }
  }
}
```

```
PageRankPull() 每轮迭代
 ├─ Phase 1: outgoing_contrib[n] = scores[n]/deg   ← P1：|V| 顺序扫
 └─ Phase 2: parallel for u                         ← P0：主热点
      └─ in_neigh gather + 写 scores[u]
```

每轮 **两次全图 pass**（scale + pull），比 `pr` 多约一倍外层扫描带宽。

---

## 热点排序（按 CPU 时间占比）

### P0：Phase 2 — `in_neigh` gather（与 `pr` 相同内核）

```47:54:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr_spmv.cc
    for (NodeID u=0; u < g.num_nodes(); u++) {
      ScoreT incoming_total = 0;
      for (NodeID v : g.in_neigh(u))
        incoming_total += outgoing_contrib[v];
      ScoreT old_score = scores[u];
      scores[u] = base_score + kDamp * incoming_total;
      error += fabs(scores[u] - old_score);
    }
```

**为什么热：**

- 内层遍历 **全部入边**，读 `outgoing_contrib[v]` — 典型 pull SpMV
- 占每轮大部分时间；g20 约 **8 轮**收敛（比 `pr` 的 11 轮少，但每轮更重）

**访存特征：** 与 `pr.md` P0 相同 — CSR 顺序 + `outgoing_contrib` IRR。

---

### P1：Phase 1 — scale `outgoing_contrib`

```43:45:/home/ice/src/sdc-benchmark/tao/gapbs/src/pr_spmv.cc
    for (NodeID n=0; n < g.num_nodes(); n++)
      outgoing_contrib[n] = scores[n] / g.out_degree(n);
```

**为什么次热：**

- 每轮额外 **|V|** 次顺序读 `scores`、写 `outgoing_contrib`
- 无 gather，带宽友好，但迭代轮数 ×2 外层 pass 仍可观
- g20 上约占单轮 **15–25%**（相对 Phase 2）

| 访问 | 模式 | 难点 |
|------|------|------|
| `scores[n]` | 顺序读 | ★★ |
| `outgoing_contrib[n]` | 顺序写 | ★★ |
| `out_degree(n)` | 顺序读 | ★★ |

---

## 访存热点汇总

```
┌──────────────────────────────────────────────────────────────────┐
│  PageRankPull 访存热点                                            │
├──────────────┬──────────────┬────────────────────────────────────┤
│ 数组          │ 访问模式      │ 预取难度                            │
├──────────────┼──────────────┼────────────────────────────────────┤
│ in_neighbors │ 块内顺序      │ ★★                                 │
│ outgoing_contrib│ Phase2: IRR │ ★★★★                               │
│              │ Phase1: SEQ   │ ★★                                 │
│ scores       │ Phase1 读 / Phase2 写 │ ★★                        │
└──────────────┴──────────────┴────────────────────────────────────┘
```

---

## 从微架构角度的理解

```mermaid
flowchart TD
    LOOP{iter} --> P1[Phase1: outgoing_contrib = scores/deg]
    P1 --> P2[Phase2: u 扫 in_neigh gather]
    P2 --> UPD[scores[u] = base + damp×sum]
    UPD --> ERR{error < ε?}
    ERR -->|否| LOOP
    ERR -->|是| DONE[结束]
```

Jacobi 语义使 Phase 1 的 `outgoing_contrib` 整轮只读；Phase 2 的 gather 与 `pr` 同构，但 **无法在本轮使用刚更新的 scores**。

---

## 各阶段时间占比（kron20 gprof 实测 + g20 经验）

| 阶段 | 占比（估） | kron20 gprof / g20 量级 | 说明 |
|------|-----------|-------------------------|------|
| **Phase 2 gather** | **70–85%** | 含在 `PageRankPull` **≈99.7%** self | 主热点 |
| **Phase 1 scale** | **15–30%** | 同上（内联未拆分） | 每轮额外 |V| pass |
| 初始化 | <3% | — | 一次 |

**kron20 实测：** Trial Avg **463.5 ms**（20 trials），比 `pr`（435.9 ms）慢约 **6%**，符合 Jacobi 多一轮 pass 的预期。g20 `-l` 误差：**1.12 → 8 轮** 至 ε。

---

## 验证热点的 profiling 命令

```bash
cd tao/gapbs
OMP_NUM_THREADS=1 ./pr_spmv -g 20 -i100 -t1e-4 -n1 -l
OMP_NUM_THREADS=1 ./pr_spmv -g 20 -i100 -t1e-4 -n1

OMP_NUM_THREADS=1 perf record -g ./pr_spmv -g 20 -i50 -t1e-4 -n1
perf report --stdio | head -60
# 关注：PageRankPull 两个 parallel for 循环
```

---

## 和预取研究的关系

访存形态与 **`pr` 几乎相同**，额外多一段 **顺序 scale**。预取策略可复用 `pr.md` 的 TAO 表；Phase 1 对 stride 更友好。

| 方法 | 预期 |
|------|------|
| **Stride** | Phase 1 **良**；Phase 2 仅 CSR 块内 |
| **Indirect / Berti** | Phase 2 **`outgoing_contrib[v]`** 同 `pr` |
| **对比 `pr`** | 多一次 SEQ pass，整体 IPC 略低 |

### TAO hint 候选

| 阶段 | 数组 | 引擎 |
|------|------|------|
| Phase 2 | `in_neighbors` + `outgoing_contrib` | Stride + Indirect |
| Phase 1 | `scores` / `outgoing_contrib` | Stride（顺序） |

---

## 与 `pr` 对比

| 维度 | **pr_spmv** | **pr** |
|------|-------------|--------|
| 算法 | Jacobi SpMV | Gauss-Seidel pull |
| 每轮 pass 数 | **2× |V|** | **1× |V|** |
| 最热循环 | gather（同） | gather（同） |
| kron20 Trial | **463.5 ms**（gprof） | **435.9 ms**（gprof） |
| 官方 GAP 二进制 | 非默认 | **bench.mk 用 `pr`** |

研究预取时：**优先 profile `pr`**（官方主路径）；`pr_spmv` 适合与文献/其他实现对齐。

---

## 结论

| 问题 | 答案 |
|------|------|
| 最热循环？ | **`PageRankPull` ≈99.7%** — Phase 2 gather（Phase 1 scale 内联） |
| 次热？ | **Phase 1 全图 scale** |
| 访存主型？ | **CSR SEQ + outgoing_contrib IRR** |
| 与 `pr`？ | 同 gather 内核，**多一轮 Jacobi scale** |
| 值不值得 profile？ | **中**；官方用 `pr`，本内核多用于算法对比 |
