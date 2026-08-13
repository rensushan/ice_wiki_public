`cc_sv.cc` 实现的是 GAPBS 的 **Shiloach-Vishkin 连通分量**（Bader 等 ICPP'05 优化 + 有向图 min-max swap）。每轮 **hook 扫全图出边** + **Compress 指针压缩**，迭代至无变化。

## 构造真实的图

```bash
cd tao/gapbs
make bench-graphs
```

## 运行

```bash
# cc_sv 不在 GAP 官方 bench.mk 主列表（官方用 cc / Afforest）
OMP_NUM_THREADS=1 ./cc_sv -f benchmark/graphs/twitter.sg -n1

OMP_NUM_THREADS=1 ./cc_sv -g 20 -n1
```

| 参数 | 含义 |
|------|------|
| **`-n N`** | trial 次数 |
| 无 **`-l`** | 仅打印总迭代次数 `Shiloach-Vishkin took N iterations` |

---

## 实测热点（gprof, kron20）

**Setup：** SERIAL 构建（`-pg -no-pie`），`OMP_NUM_THREADS=1`，图 `benchmark/graphs/kron20.sg`，**50 trials**，加载序列化图。

| % self | 函数 |
|--------|------|
| **≈99.8%** | `ShiloachVishkin`（Hook + Compress 已内联） |

**Avg Trial Time：** 219.3 ms

kron20 上仅 **2 轮**迭代；Hook 扫边与 Compress 指针链均折叠在 `ShiloachVishkin` 内，gprof 无法拆分两阶段占比。

```bash
cd tao/gapbs
# SERIAL: make clean && make CXXFLAGS+='-pg -no-pie'
OMP_NUM_THREADS=1 GMON_OUT_PREFIX=cc_sv_kron20 ./cc_sv -f benchmark/graphs/kron20.sg -n50
gprof ./cc_sv gmon.file
```

原始 gprof：`tao/gapbs/profile_runs/cc_sv_gprof.txt`

---

## 整体执行流程

`main` → `ShiloachVishkin()`：

```49:82:/home/ice/src/sdc-benchmark/tao/gapbs/src/cc_sv.cc
pvector<NodeID> ShiloachVishkin(const Graph &g) {
  comp[n] = n;
  while (change) {
    // Hook: 扫所有出边
    for (NodeID u) for (NodeID v : g.out_neigh(u)) { ... comp[high]=low ... }
    // Compress: 全图指针压缩
    for (NodeID n) while (comp[n] != comp[comp[n]]) comp[n] = comp[comp[n]];
  }
}
```

```
ShiloachVishkin()
 └─ while (change)
      ├─ Hook 阶段          ← P0：|V|×deg 出边 + comp 随机读写
      └─ Compress 阶段      ← P0/P1：|V| 指针链 comp[comp[·]]
```

无 Afforest 的子图采样；**每轮都扫完整边集**。

---

## 热点排序（按 CPU 时间占比）

### P0：Hook 阶段 — 全图出边 + `comp` 写

```60:72:/home/ice/src/sdc-benchmark/tao/gapbs/src/cc_sv.cc
    for (NodeID u=0; u < g.num_nodes(); u++) {
      for (NodeID v : g.out_neigh(u)) {
        NodeID comp_u = comp[u];
        NodeID comp_v = comp[v];
        if (comp_u == comp_v) continue;
        NodeID high_comp = comp_u > comp_v ? comp_u : comp_v;
        NodeID low_comp = comp_u + (comp_v - high_comp);
        if (high_comp == comp[high_comp]) {
          change = true;
          comp[high_comp] = low_comp;
        }
      }
    }
```

**为什么热：**

- 每轮 **O(|E|)** 边遍历（无向图 CSR 双向存边，边数 ≈ 2×无向边）
- 对 `comp[u]`、`comp[v]`、`comp[high_comp]` **随机读 + 条件写**
- 多线程无 CAS（与 `cc` Link 不同），但写 `comp[high_comp]` 仍有 false sharing
- 迭代次数依赖图直径/结构；**g20 仅 2 轮**，大图（twitter）可达数十轮

**访存特征：**

| 访问 | 模式 | 难点 |
|------|------|------|
| `out_neighbors` | CSR 块内顺序 | ★★ |
| `comp[u]`, `comp[v]` | 随机读 | ★★★ |
| `comp[high_comp]` | 随机 RMW | ★★★★ |

---

### P0/P1：Compress 阶段 — 指针追逐

```75:78:/home/ice/src/sdc-benchmark/tao/gapbs/src/cc_sv.cc
    for (NodeID n=0; n < g.num_nodes(); n++) {
      while (comp[n] != comp[comp[n]]) {
        comp[n] = comp[comp[n]];
      }
    }
```

**为什么热：**

- 每轮一次 **全图 |V| 扫描**
- `comp[comp[n]]` 为 **load-use 依赖链**，与 `cc::Compress` 同构
- 链长未定时 ILP 差；多轮 SV 后链通常变短

| 访问 | 模式 | 难点 |
|------|------|------|
| `comp[n]` | 顺序起点 | ★★ |
| `comp[comp[n]]` | **间接链** | ★★★★★ |

---

## 访存热点汇总

```
┌──────────────────────────────────────────────────────────────────┐
│  Shiloach-Vishkin 访存热点                                        │
├──────────────┬──────────────┬────────────────────────────────────┤
│ 数组          │ 访问模式      │ 预取难度                            │
├──────────────┼──────────────┼────────────────────────────────────┤
│ out_neighbors│ CSR 顺序      │ ★★                                 │
│ comp[] Hook  │ 随机读写      │ ★★★★                               │
│ comp[] Compress│ 间接链      │ ★★★★★                              │
└──────────────┴──────────────┴────────────────────────────────────┘
```

工作集：**`comp[]`**（|V|×4B）+ CSR。比 `cc` Afforest **无采样、无 CAS**，但 **每轮全边 hook** 在大图上迭代次数可能更多。

---

## 从微架构角度的理解

```mermaid
flowchart TD
    INIT[comp[n]=n] --> LOOP{change?}
    LOOP -->|是| HOOK[Hook: 扫 out_neigh 写 comp]
    HOOK --> COMP[Compress: comp[n]=comp[comp[n]]]
    COMP --> LOOP
    LOOP -->|否| DONE[返回 comp]
```

1. **Hook**：带宽 + 随机 `comp` 访问主导。
2. **Compress**：延迟受限的指针链，与 `cc` 最难部分同类。
3. **相对 `cc` Afforest**：无子图采样与 `SampleFrequentElement`，算法更简单但大图可能更慢。

---

## 各阶段时间占比（kron20 gprof 实测 + g20 经验）

| 阶段 | 占比（估） | kron20 gprof / g20 量级 | 说明 |
|------|-----------|---------------------------|------|
| **Hook + Compress** | Hook **50–70%** / Compress **30–50%** | **≈99.8%** self（内联未拆分）；Trial **219.3 ms** | kron20 仅 2 轮 |
| 初始化 | <2% | — | `comp[n]=n` |

输出：`Shiloach-Vishkin took 2 iterations`（kron20，|V|≈1M，avg deg≈14）。

---

## 验证热点的 profiling 命令

```bash
cd tao/gapbs
OMP_NUM_THREADS=1 ./cc_sv -g 20 -n1
OMP_NUM_THREADS=1 ./cc_sv -f benchmark/graphs/twitter.sg -n1

OMP_NUM_THREADS=1 perf record -g ./cc_sv -g 20 -n1
perf report --stdio | head -60
# 关注：ShiloachVishkin 两个 parallel for、Compress 内 while
```

---

## 和预取研究的关系

与 **`cc`** 共享 **`comp[comp[·]]` 间接链** 难题；Hook 阶段多 **出边 CSR + comp 随机写**。

| 方法 | 预期 |
|------|------|
| **Stride** | 仅 `out_neighbors` 块内有效 |
| **Indirect / SDC** | **Compress** 与 `cc` 类似，有研究价值 |
| **对比 `cc`** | 无 CAS；**每轮全边** vs Afforest 采样+最终 Link |

### TAO hint 候选

| 阶段 | 数组 | 引擎 |
|------|------|------|
| Hook | `out_neighbors` | Stride |
| Hook | `comp[v]` | Indirect（trigger=neighbors） |
| Compress | `comp[comp[n]]` | Indirect（trigger=comp[n]） |

---

## 与 `cc` 对比

| 维度 | **cc_sv** | **cc (Afforest)** |
|------|-----------|-------------------|
| 算法 | Shiloach-Vishkin | Union-Find + 采样 |
| 最热循环 | Hook + Compress | Link + Compress |
| 同步 | 普通写 | CAS (`Link`) |
| 边遍历 | **每轮全 |E|** | 采样 + 最终 Link |
| GAP 官方 | 否 | **是** (`cc-twitter` 等) |
| g20 Trial | **219.3 ms**（kron20 gprof） | 视实现而定 |

---

## 结论

| 问题 | 答案 |
|------|------|
| 最热循环？ | **`ShiloachVishkin` ≈99.8%**（Hook + Compress 内联；kron20 仅 2 轮） |
| 访存主型？ | **CSR SEQ + comp IRR/链** |
| 与 `cc`？ | 共享 Compress 难点；**无 Afforest 优化** |
| 官方 benchmark？ | **否**（对比/教学用） |
| 值不值得 profile？ | **中**；研究 UF/Compress 时可与 `cc` 对照 |
