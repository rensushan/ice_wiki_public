# GAPBS 访存对照大纲

> 用途：快速判断各 kernel 与 `cc` 的异同，以及 TAO hint / ChampSim 评测怎么排优先级。  
> 细部热点见同目录各 `*.md`（`cc.md`、`bfs.md`、…）。

---

## 术语（缩写）

| 缩写 | 全称 / 含义 | 在 GAP 里常见样子 |
| ---- | ----------- | ----------------- |
| **CSR** | Compressed Sparse Row | `out_index_[u]` + `out_neighbors_[i..j]` 存邻接表 |
| **SEQ** | Sequential / 顺序流式 | 地址近似连续或固定小 stride 前进（如扫邻接表、扫 `index[]`） |
| **STR** | Stride | 固定跨步（列扫、按 word 扫 bitmap 等）；常并入 SEQ 讨论 |
| **IRR** | Irregular / 不规则 | 地址由数据决定、空间局部性差（如 `parent[v]`、`comp[id]`） |
| **gather** | 间接聚集读 | `B[A[i]]` / `score[neigh]`：索引来自数组，目标随机读 |
| **UF** | Union-Find（并查集） | `comp[u]` 父指针；`Link` / `Compress`；`comp[comp[n]]` 路径压缩 |
| **依赖链** | load-use 串行依赖 | 下一拍地址依赖上一拍 load 结果（如 `comp[comp[high]]`），ILP/预取难 |
| **CAS** | Compare-And-Swap | 原子 RMW（`parent[v]`、`dist[v]`、`comp[high]`）；多线程争用 + false sharing |
| **RMW** | Read-Modify-Write | 读-改-写；CAS 是常见形式 |
| **TD / BU** | Top-Down / Bottom-Up | BFS 两种扩展：TD 从前沿扫出边；BU 扫全图入边 |
| **SpMV** | Sparse Matrix–Vector | 稀疏矩阵×向量；`pr_spmv` / HPCG 的 `x[col[j]]` |
| **hint** | 软件语义提示 | TAO `pfConfig` / `sdcSet`：声明区间与间接耦合，非 `__builtin_prefetch` 逐条地址 |
| **kron** | Kronecker 合成图 | GAPBS `-g <scale>`，顶点数 \(2^{\text{scale}}\)（如 `-g 20` ≈ 1M 点） |

与 `profile/hotspot.md` / `profile/Tao.md` 中 `SEQ` / `STR` / `IRR` / `CSR` 用法一致。

---

## 与 `cc` 的访存对照表

**结论：其它 kernel 与 `cc` 并不一样。** 多数共用 CSR 扫边，但和 `cc` 的「并查集依赖链」只有部分重叠。

| Kernel | 和 `cc` 比 | 访存主型（热点） |
| ------ | ---------- | ---------------- |
| **cc**（对照） | — | CSR 扫边 + **`comp[]` 随机** + **`comp[comp[]]` 依赖链** + CAS |
| **cc_sv** | **最像** | 仍是 UF / `comp[]`；无 Afforest 采样，链/扫边形态接近 |
| **bfs** | **部分像** | CSR + **`parent[v]` 随机 CAS**；**无**长 UF 链；另有 BU 全图 + 入边 |
| **sssp** | **像 bfs** | 加权 CSR + **`dist[v]` CAS**；无 UF 链 |
| **bc** | **像 bfs 加戏** | 前向≈BFS（`depths` CAS + 原子）；反向还有 **`deltas` 依赖**与更多原子 |
| **pr** | **不太像** | 反复 **`score[neigh]` gather**（pull）；少 CAS，无 UF |
| **pr_spmv** | **像 pr** | 更接近 SpMV：`x[col]` 式 gather + 顺序写；无 UF |
| **tc** | **最不像** | 邻接表 **双指针归并（几乎纯 SEQ）**；无顶点属性 IRR，无 CAS |

---

## 评测 / TAO 归类（一句话）

| 族 | Kernel | 说明 |
| -- | ------ | ---- |
| **UF 族**（最难 / 最贴现有 `cc` 结果） | `cc`、`cc_sv` | 依赖链 + 随机 `comp[]`；stride 基本无效 |
| **CSR + 顶点数组 CAS** | `bfs`、`sssp`、`bc` | indirect → `parent` / `dist` / `depths`；CAS 使 mirror 易 stale |
| **CSR + 属性 gather** | `pr`、`pr_spmv` | indirect gather；同步少，更像 SpMV |
| **CSR 顺序友好对照** | `tc` | 主打 **stride**；应用作「规则基线」 |

**TAO hint 不能从 `cc` 原样套到全部：**

- `cc` / `cc_sv`：`comp` 区间 + 链式 / ensemble  
- `bfs` / `sssp` / `bc`：偏 **indirect → 顶点属性**  
- `pr` / `pr_spmv`：偏 **indirect gather**  
- `tc`：主要 **stride** 绑邻接表  

---

## 官方运行参数（`benchmark/bench.mk`）

与上游 [sbeamer/gapbs](https://github.com/sbeamer/gapbs) 的 `bench.mk` 一致。图目录默认 `~/dataset/gapbs`（或 `tao/gapbs/benchmark/graphs`）。一键官方跑：`cd tao/gapbs && make bench-run`。

### 按 kernel（与图无关，除 SSSP `-d`）

| Kernel | 图后缀 | 官方参数 |
|--------|--------|----------|
| **bfs** | `.sg` | `-n64` |
| **sssp** | `.wsg`（加权） | `-n64` + **delta 见下表** |
| **pr** | `.sg` | `-i1000 -t1e-4 -n16` |
| **cc** | `.sg` | `-n16` |
| **bc** | `.sg` | `-i4 -n16` |
| **tc** | **`U.sg`**（对称化） | `-n3` |

BFS 的 `alpha`/`beta` 用默认（15/18），官方不按图改。

### SSSP `-d`（唯一按图变）

| 图 | delta |
|----|-------|
| twitter / web / kron / urand | **`-d2`** |
| **road** | **`-d50000`** |

### 完整命令（官方 trial 数）

```bash
GRAPH=~/dataset/gapbs

# BFS
./bfs  -f $GRAPH/twitter.sg -n64
./bfs  -f $GRAPH/web.sg     -n64
./bfs  -f $GRAPH/road.sg    -n64
./bfs  -f $GRAPH/kron.sg    -n64
./bfs  -f $GRAPH/urand.sg   -n64

# SSSP
./sssp -f $GRAPH/twitter.wsg -n64 -d2
./sssp -f $GRAPH/web.wsg     -n64 -d2
./sssp -f $GRAPH/road.wsg    -n64 -d50000
./sssp -f $GRAPH/kron.wsg    -n64 -d2
./sssp -f $GRAPH/urand.wsg   -n64 -d2

# PR
./pr   -f $GRAPH/twitter.sg -i1000 -t1e-4 -n16
./pr   -f $GRAPH/web.sg     -i1000 -t1e-4 -n16
./pr   -f $GRAPH/road.sg    -i1000 -t1e-4 -n16
./pr   -f $GRAPH/kron.sg    -i1000 -t1e-4 -n16
./pr   -f $GRAPH/urand.sg   -i1000 -t1e-4 -n16

# CC
./cc   -f $GRAPH/twitter.sg -n16
./cc   -f $GRAPH/web.sg     -n16
./cc   -f $GRAPH/road.sg    -n16
./cc   -f $GRAPH/kron.sg    -n16
./cc   -f $GRAPH/urand.sg   -n16

# BC
./bc   -f $GRAPH/twitter.sg -i4 -n16
./bc   -f $GRAPH/web.sg     -i4 -n16
./bc   -f $GRAPH/road.sg    -i4 -n16
./bc   -f $GRAPH/kron.sg    -i4 -n16
./bc   -f $GRAPH/urand.sg   -i4 -n16

# TC（必须 *U.sg）
./tc   -f $GRAPH/twitterU.sg -n3
./tc   -f $GRAPH/webU.sg     -n3
./tc   -f $GRAPH/roadU.sg    -n3
./tc   -f $GRAPH/kronU.sg    -n3   # 常为 kron.sg 的 symlink
./tc   -f $GRAPH/urandU.sg   -n3
```

### ChampSim / 单次试跑

参数语义不变，只减 trial、单线程：

```bash
OMP_NUM_THREADS=1 ./bfs  -f $GRAPH/road.sg     -n1
OMP_NUM_THREADS=1 ./sssp -f $GRAPH/road.wsg    -n1 -d50000
OMP_NUM_THREADS=1 ./sssp -f $GRAPH/twitter.wsg  -n1 -d2
OMP_NUM_THREADS=1 ./pr   -f $GRAPH/twitter.sg  -i1000 -t1e-4 -n1
OMP_NUM_THREADS=1 ./cc   -f $GRAPH/twitter.sg  -n1
OMP_NUM_THREADS=1 ./bc   -f $GRAPH/twitter.sg  -i4 -n1
OMP_NUM_THREADS=1 ./tc   -f $GRAPH/twitterU.sg -n1
```

---

## 实测热点汇总（kron20 gprof）

**Setup：** SERIAL `-pg -no-pie`，`OMP_NUM_THREADS=1`，图 `benchmark/graphs/kron20.sg`（2^20 顶点，15,699,691 无向边，deg≈14）。加权 kernel（`sssp`）用 `kron20.wsg`。加载序列化图（非 `-g` 生成），避免 MakeRMat 占 profile。完整原始输出见 [`tao/gapbs/profile_runs/SUMMARY.md`](../../tao/gapbs/profile_runs/SUMMARY.md) 与各 `*_gprof.txt`。

| Kernel | Trials | Avg Trial | Dominant gprof self |
|--------|--------|-----------|---------------------|
| **bfs** | 200 | 25.6 ms | BUStep **73.2%**, DOBFS 17.1%, BitmapToQueue 6.2%, TDStep **2.9%** |
| **sssp** | 50 | 179.7 ms | DeltaStep **≈99.6%**（RelaxEdges inlined） |
| **pr** | 20 | 435.9 ms | PageRankPullGS **≈99.7%** |
| **pr_spmv** | 20 | 463.5 ms | PageRankPull **≈99.7%** |
| **bc** | 20, `-i 1` | 381.6 ms | PBFS **54.3%**, Brandes **45.3%**（back-prop in Brandes self） |
| **cc_sv** | 50 | 219.3 ms | ShiloachVishkin **≈99.8%**（2 iterations; hook+compress inlined） |
| **tc** | 1 | 12.43 s + Relabel 1.10 s | Hybrid **91.4%**（OrderedCount inlined）, RelabelByDegree 3.2% self (~8% with children) |

**读表要点：**

- **bfs**：kron20 上 BU 压倒 TD（与 twitter 等图可能相反）
- **sssp / pr / pr_spmv / cc_sv**：单函数占 ~99%+，内联使子阶段不可分
- **bc**：前向 PBFS 与反向 Brandes 近乎对半
- **tc**：规则归并核；Relabel 为次要预处理

---

## 文档索引

| Kernel | Profile |
| ------ | ------- |
| 图结构 / CSR | `graph.md` |
| Connected Components (Afforest) | `cc.md` |
| Connected Components (SV) | `cc_sv.md` |
| BFS | `bfs.md` |
| SSSP | `sssp.md` |
| Betweenness | `bc.md` |
| PageRank (GS) | `pr.md` |
| PageRank (SpMV/Jacobi) | `pr_spmv.md` |
| Triangle Counting | `tc.md` |

论文 / ChampSim 总纲见 `profile/Tao.md`、`profile/hotspot.md`。
