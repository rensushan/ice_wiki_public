`sssp.cc` 实现的是 GAPBS 的 **∆-stepping SSSP**（Meyer & Sanders）+ **bucket fusion**（Zhang 等 CGO'20）：按距离 bin 宽度 `delta` 分桶，前沿顶点松弛加权出边，用 **CAS** 更新 `dist[v]`，线程本地 bin 与共享 frontier 双缓冲。

## 构造真实的图

```bash
cd tao/gapbs
make bench-graphs
```

需 **加权图** `*.wsg`。

## 运行

```bash
# GAP 官方 benchmark（bench.mk）
./sssp -f benchmark/graphs/twitter.wsg -n64 -d2
./sssp -f benchmark/graphs/road.wsg -n64 -d50000   # road 需大 delta

OMP_NUM_THREADS=1 ./sssp -f benchmark/graphs/twitter.wsg -n1 -d2
OMP_NUM_THREADS=1 ./sssp -g 20 -n1 -d2 -l
```


| 参数     | 含义                                                  |
| ------ | --------------------------------------------------- |
| `-d Δ` | bin 宽度（twitter/web/kron/urand：**2**；road：**50000**） |
| `-n N` | trial 次数（官方 **64**）                                 |
| `-l`   | 每轮打印 **bin 索引、毫秒、frontier 大小** + 总迭代数               |


---



## 实测热点（gprof, kron20）

**Setup：** SERIAL 构建（`-pg -no-pie`），`OMP_NUM_THREADS=1`，加权图 `benchmark/graphs/kron20.wsg`，**50 trials**，`-d2`，加载序列化图（非 `-g` 生成）。


| % self     | 函数                            |
| ---------- | ----------------------------- |
| **≈99.6%** | `DeltaStep`（`RelaxEdges` 已内联） |


**Avg Trial Time：** 179.7 ms

几乎全部 CPU 时间在 `DeltaStep` 主循环内（含 `RelaxEdges` 的 `dist` CAS + 加权 CSR），bucket fusion / barrier 占比可忽略（单线程）。

```bash
cd tao/gapbs
# SERIAL: make clean && make CXXFLAGS+='-pg -no-pie'
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=sssp_kron20 ./sssp -f benchmark/graphs/kron20.wsg -n50 -d2
gprof ./sssp gmon.file
```

原始 gprof：`tao/gapbs/profile_runs/sssp_gprof.txt`

---



## 整体执行流程

`main` → `DeltaStep()` → 反复 `RelaxEdges()`：

```87:152:/home/ice/src/sdc-benchmark/tao/gapbs/src/sssp.cc
pvector<WeightT> DeltaStep(...) {
  dist[source] = 0; frontier[0] = source;
  while (shared_indexes[iter&1] != kMaxBin) {
  #pragma omp for
    for (i in curr_frontier)
      if (dist[u] >= delta * curr_bin_index)
        RelaxEdges(g, u, delta, dist, local_bins);
    // bucket fusion: 处理小 local bin
    // vote next_bin, barrier, copy to shared frontier
  }
}
```

```
DeltaStep()
 ├─ 初始化 dist[], frontier[]           ← P2
 └─ while (未结束)
      ├─ 处理 shared frontier            ← P0：RelaxEdges
      ├─ bucket fusion（小 local bin）    ← P0
      ├─ 选 next_bin + barrier           ← P3
      └─ 拷贝 thread-local bin → frontier ← P3
```

---



## 热点排序（按 CPU 时间占比）



### P0：`RelaxEdges()` — 加权 CSR + `dist` CAS

```69:84:/home/ice/src/sdc-benchmark/tao/gapbs/src/sssp.cc
void RelaxEdges(const WGraph &g, NodeID u, WeightT delta,
                pvector<WeightT> &dist, vector<vector<NodeID>> &local_bins) {
  for (WNode wn : g.out_neigh(u)) {
    WeightT old_dist = dist[wn.v];
    WeightT new_dist = dist[u] + wn.w;
    while (new_dist < old_dist) {
      if (compare_and_swap(dist[wn.v], old_dist, new_dist)) {
        local_bins[dest_bin].push_back(wn.v);
        break;
      }
      old_dist = dist[wn.v];
    }
  }
}
```

**为什么热：**

- 每个前沿顶点松弛 **全部加权出边**
- `dist[wn.v]` **随机 CAS RMW**，与 `bfs` TD 的 `parent` CAS 同类
- 成功松弛后 `push_back` 到 `local_bins[dest_bin]`，带来额外写
- g20 `-d2`：**237 iterations**；早期 bin 3–5 frontier 暴涨（数千–数万顶点）

**访存特征：**（`out_neigh(u)` 拆成 index + neighbors）

**优先级数字含义：** `1` = **最高优先**（相对 no-prefetch / 硬件预取，预期收益最大、最该先挂 TAO hint）；数字越大越靠后。`1` 比 `3` 更优先。依据是：**流量（每边 vs 每顶点）× 不规则程度 × 硬件预取是否已能覆盖**，不是算法正确性顺序。


| 访问 | 模式 | 难点 | 优先级 |
| ---- | ---- | ---- | ------ |
| `dist[wn.v]` | **随机 CAS** | ★★★★★ IRR | 1（最高） |
| `out_neighbors_`（WNode 段） | CSR **块内顺序** | ★★ | 2 |
| `out_index_[u]` / `[u+1]` | 按顶点 **间接**读指针 | ★★★ IRR | 3 |
| `dist[u]` | 按 frontier 中的 u **间接**读 | ★★★ IRR | 3 |
| `frontier[i]` | 数组顺序读 u | ★★ | 4（最低） |
| `local_bins` | append | ★★★ | — |


---



### P0：`DeltaStep` 主循环 — frontier 扫描 + bucket fusion

```107:119:/home/ice/src/sdc-benchmark/tao/gapbs/src/sssp.cc
      for (size_t i=0; i < curr_frontier_tail; i++) {
        NodeID u = frontier[i];
        if (dist[u] >= delta * curr_bin_index)
          RelaxEdges(g, u, delta, dist, local_bins);
      }
      while (curr_bin_index < local_bins.size() &&
             !local_bins[curr_bin_index].empty() &&
             local_bins[curr_bin_index].size() < kBinSizeThreshold) {
        // 拷贝并再次 RelaxEdges（bucket fusion）
      }
```

**为什么热：**

- 外层按 **iteration/bin** 驱动，宽前沿时 frontier 扫描本身占带宽
- **Bucket fusion**：小 bin 同轮继续松弛，减少 barrier 次数（road 图关键）
- `dist[u] >= delta * curr_bin_index` 过滤已入更低 bin 的冗余顶点

---



### P3：同步与 frontier 合并

```121:146:/home/ice/src/sdc-benchmark/tao/gapbs/src/sssp.cc
      #pragma omp critical  // vote next_bin_index
      #pragma omp barrier
      #pragma omp single    // 切换 bin、PrintStep
      fetch_and_add + copy local_bins → frontier
      #pragma omp barrier
```

OpenMP **barrier + critical** 每轮至少一次；g20 上 237 轮 → 同步开销 **5–15%**（估）。单线程无此问题。

---



### P2：初始化

`dist[] = inf`，`frontier[0]=source`；一次性，可忽略。

---



## 访存热点汇总

依赖链：`frontier → u → (dist[u], out_index_[u]) → out_neighbors_ 段 → v → dist[v]`

**「优先 k」物理含义：** 预取/TAO 的**实施次序与预期收益排序**——`优先 1` 最高（miss 多、HW 难覆盖），`优先 4` 最低（顺序流、边际小）。**不是**“数字越大越优先”，也**不是**源码执行先后。

```
┌──────────────────────────────────────────────────────────────────┐
│  DeltaStep / RelaxEdges 访存热点（按预取优先级）                    │
├──────────────────┬──────────────┬────────────────────────────────┤
│ 数组              │ 访问模式      │ 预取难度                        │
├──────────────────┼──────────────┼────────────────────────────────┤
│ dist[v]          │ 随机 CAS RMW  │ ★★★★★（IRR + 同步）  优先 1     │
│ out_neighbors_   │ 块内顺序      │ ★★（加权 WNode SEQ） 优先 2     │
│ out_index_[u]    │ 按 u 间接     │ ★★★ IRR              优先 3     │
│ dist[u]          │ 按 u 间接     │ ★★★ IRR              优先 3     │
│ frontier[]       │ 顺序读 u      │ ★★                   优先 4     │
│ local_bins       │ 向量 append   │ ★★★                            │
└──────────────────┴──────────────┴────────────────────────────────┘
```

工作集：`dist[]`（|V|×sizeof(WeightT)）+ **frontier**（可达 |E|）+ `out_index_`（|V|+1 指针）+ `out_neighbors_`（|E_dir|×sizeof(WNode)）+ 线程本地 bins。

---



## 从微架构角度的理解

```mermaid
flowchart TD
    S[source dist=0] --> BIN[当前 bin 处理 frontier]
    BIN --> REL[RelaxEdges: CAS dist[v]]
    REL --> FUSE{bucket fusion?}
    FUSE -->|是| REL
    FUSE -->|否| SYNC[barrier 选 next bin]
    SYNC --> BIN
    BIN --> DONE[所有 bin 完成]
```



1. **∆ 参数敏感**：过小 → 迭代多、barrier 多；过大 → 每轮工作量大。road 用 **d=50000**。
2. **CAS 主导**：与 `bfs` TD 类似，预取 `dist[v]` 难，CSR stride 仍有效。
3. **Bucket fusion**：减少迭代，换更多同轮 RelaxEdges（计算换同步）。

---



## 各阶段时间占比（kron20 gprof 实测 + g20 `-d2 -l`）


| 阶段                         | 占比（估）          | kron20 gprof / g20 量级                            | 说明                   |
| -------------------------- | -------------- | ------------------------------------------------ | -------------------- |
| **DeltaStep / RelaxEdges** | **80–90%**     | **≈99.6%** self（kron20 gprof）；Trial **179.7 ms** | CAS + 加权 CSR         |
| Frontier / fusion          | **5–15%**      | 含在 DeltaStep 内                                   | 宽 bin 时升高            |
| Barrier / copy             | **5–10%**（多线程） | 单线程可忽略                                           | g20 共 237 iterations |


`-l` **示例（g20，节选）：** bin 3 frontier=31 → **9.3ms**；bin 4 frontier=4488 → **38ms**；后期 bin frontier 仍上万。

---



## 验证热点的 profiling 命令

```bash
cd tao/gapbs
OMP_NUM_THREADS=1 ./sssp -g 20 -n1 -d2 -l       # 按 bin 耗时
OMP_NUM_THREADS=1 ./sssp -g 20 -n1 -d2

OMP_NUM_THREADS=1 perf record -g ./sssp -g 20 -n1 -d2
perf report --stdio | head -60
# 关注：RelaxEdges、compare_and_swap、DeltaStep 内 omp 循环
```

---



## 和预取研究的关系

SSSP 结合 **`out_index_` IRR**、**加权邻接 SEQ** 与 `dist[]` **IRR/CAS**，是 GAP 中除 BFS/CC 外又一 **CAS 密集型** trace 候选。


| 方法               | 预期 |
| ---------------- | ---- |
| **Stride**       | 对 **`out_neighbors_`** 有效；`dist` / `out_index_` 无稳定跨步 |
| **Berti / IPCP** | **中–良**；RelaxEdges PC 稳定 |
| **SDC / TAO**    | stride 绑邻接；indirect 绑 `out_index_[u]` 与 `dist`（`dist` mirror 因 CAS 易 stale） |




### TAO hint 候选

「优先 k」同上：**1 = 最先做 / 预期收益最大**（非执行顺序）。


| 数组 | 引擎 | 说明 |
| ---- | ---- | ---- |
| `dist[wn.v]` | **Indirect** | trigger=`wn.v`；优先 1（最高） |
| `out_neighbors_`（WNode） | **Stride** | 行内加权 CSR SEQ；优先 2 |
| `out_index_[u]` | **Indirect** | trigger=frontier/`u`；取邻接段起止指针；优先 3 |
| `dist[u]` | **Indirect** | 可与 `out_index_` 共用 trigger `u`；优先 3 |
| `frontier[i]` | **Stride** | 顺序读顶点 id；优先 4（最低） |


优先 profile PC：`RelaxEdges` 内 `dist[wn.v]` CAS 路径；其次邻接段与 `out_index_` load。

---



## 与 `bfs` / `pr` 对比


| 维度           | **sssp**                     | **bfs**      | **pr**               |
| ------------ | ---------------------------- | ------------ | -------------------- |
| 边权           | **有**                        | 无            | 无                    |
| 核心更新         | `dist` CAS                   | `parent` CAS | 浮点 gather            |
| 遍历模式         | ∆-stepping bins              | DO BFS 层     | 全图迭代                 |
| delta        | **图相关**                      | alpha/beta   | ε 收敛                 |
| 官方参数         | `-n64 -d2`（road **-d50000**） | `-n64`       | `-i1000 -t1e-4 -n16` |
| kron20 Trial | **179.7 ms**（gprof）          | 视 DO 而定      | **435.9 ms**（gprof）  |


---



## 结论


| 问题            | 答案                                                                |
| ------------- | ----------------------------------------------------------------- |
| 最热函数？         | `DeltaStep()` **≈99.6%**（`RelaxEdges` 内联）— `dist[v]` CAS + 加权 CSR |
| 访存主型？         | **`out_index_` IRR + 邻接 SEQ + `dist` IRR/CAS**                  |
| 迭代特征？         | **多 bin 迭代**（g20: 237）；frontier 宽度波动大                             |
| 官方参数？         | `-f *.wsg -n64 -d2`（road **-d50000**）                             |
| 值不值得 profile？ | **值得**；`sssp-`* 在 bench.mk 中，CAS+加权与 bfs 互补                       |




## 访存热点汇总（文末速查）

依赖链：`frontier → u → (dist[u], out_index_[u]) → out_neighbors_ 段 → v → dist[v]`

**「优先 k」：** `1` 最高、`4` 最低——表示预取/TAO **实施与收益排序**（流量 × 不规则 × HW 是否已覆盖），**不是**“数字越大越优先”，也不是源码执行先后。

```
┌──────────────────────────────────────────────────────────────────┐
│  DeltaStep / RelaxEdges 访存热点（按预取优先级）                    │
├──────────────────┬──────────────┬────────────────────────────────┤
│ 数组              │ 访问模式      │ 预取难度                        │
├──────────────────┼──────────────┼────────────────────────────────┤
│ dist[v]          │ 随机 CAS RMW  │ ★★★★★（IRR + 同步）  优先 1     │
│ out_neighbors_   │ 块内顺序      │ ★★（加权 WNode SEQ） 优先 2     │
│ out_index_[u]    │ 按 u 间接     │ ★★★ IRR              优先 3     │
│ dist[u]          │ 按 u 间接     │ ★★★ IRR              优先 3     │
│ frontier[]       │ 顺序读 u      │ ★★                   优先 4     │
│ local_bins       │ 向量 append   │ ★★★                            │
└──────────────────┴──────────────┴────────────────────────────────┘
```

### TAO hint 候选


| 数组 | 引擎 | 说明 |
| ---- | ---- | ---- |
| `dist[wn.v]` | **Indirect** | trigger=`wn.v`；优先 1（最高） |
| `out_neighbors_`（WNode） | **Stride** | 行内加权 CSR SEQ；优先 2 |
| `out_index_[u]` | **Indirect** | trigger=`u`；邻接段起止指针；优先 3 |
| `dist[u]` | **Indirect** | 可与 `out_index_` 共用 trigger `u`；优先 3 |
| `frontier[i]` | **Stride** | 顺序读顶点 id；优先 4（最低） |
