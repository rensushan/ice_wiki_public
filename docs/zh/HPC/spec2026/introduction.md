# SPEC CPU®2026 概述（Q12–Q16）

> 摘自 [SPEC CPU 2026 Overview / What's New?](https://www.spec.org/cpu2026/Docs/overview.html)（Suites and Benchmarks / Metrics 部分）。原文版权归 SPEC®。本文为中文译本。

## 套件与基准（Suites and Benchmarks）

### Q12. 什么是 SPEC CPU 2026 的「suite」（套件）？

**Suite（套件）**是一组作为整体运行、共同产生某一综合指标的基准程序集合。

SPEC CPU 2026 产品包含四个套件，分别面向不同类型的计算密集型性能：

| 短标签（ShortTag） | 套件（Suite） | 内容 | 指标（Metrics） | 跑几份拷贝？分数越高意味着什么？ |
| --- | --- | --- | --- | --- |
| intspeed | [SPECspeed®2026 Integer](https://www.spec.org/cpu2026/Docs/index.html#intspeed) | 13 个整数基准 | `SPECspeed2026_int_base`<br>`SPECspeed2026_int_peak` | SPECspeed 套件对每个基准始终只跑 **1 份拷贝**。分数越高表示完成所需时间越短。 |
| fpspeed | [SPECspeed®2026 Floating Point](https://www.spec.org/cpu2026/Docs/index.html#fpspeed) | 13 个浮点基准 | `SPECspeed2026_fp_base`<br>`SPECspeed2026_fp_peak` | |
| intrate | [SPECrate®2026 Integer](https://www.spec.org/cpu2026/Docs/index.html#intrate) | 14 个整数基准 | `SPECrate2026_int_base`<br>`SPECrate2026_int_peak` | SPECrate 套件对每个基准跑 **多份并发拷贝**，份数由测试者选择。分数越高表示吞吐（单位时间完成的工作量）越高。 |
| fprate | [SPECrate®2026 Floating Point](https://www.spec.org/cpu2026/Docs/index.html#fprate) | 12 个浮点基准 | `SPECrate2026_fp_base`<br>`SPECrate2026_fp_peak` | |

「短标签（Short Tag）」是配合 `runcpu` 使用的规范缩写，上下文由工具定义。在公开发表的文档里，上下文未必清楚；为避免歧义，发表时应使用上表所示的**套件全名**或**指标全名**。

### Q13. 有哪些基准程序？

SPEC CPU 2026 共有 **52** 个基准，组织进 4 个套件：

```
 SPECrate 2026 Integer            SPECspeed 2026 Integer
 SPECrate 2026 Floating Point     SPECspeed 2026 Floating Point
```

成对出现的基准形如：

```
 7nn.benchmark_r / 8nn.benchmark_s
```

彼此相似；差异包括：编译选项、负载规模、运行规则等。参见：[OpenMP](https://www.spec.org/cpu2026/Docs/overview.html) / [memory](https://www.spec.org/cpu2026/Docs/overview.html) / [rules](https://www.spec.org/cpu2026/Docs/runrules.html)。

#### 整数（Integer）

| SPECrate®2026 Integer | SPECspeed®2026 Integer | 语言[^1] | KLOC[^2] | 应用领域 |
| --- | --- | --- | --- | --- |
| | 801.xz_s | CXX,C | 53 | 数据压缩 |
| 706.stockfish_r | | CXX | 13 | 游戏 / AI（国际象棋）——α-β 树搜索、神经网络 |
| 707.ntest_r | 807.ntest_s | CXX | 16 | 游戏 / AI（黑白棋 / othello） |
| 708.sqlite_r | | C | 245 | SQL 编译器/解释器与数据库 |
| 710.omnetpp_r | | CXX,C | 224 | 离散事件建模——网络与排队仿真 |
| 714.cpython_r | | C | 747 | Python 解释器 |
| | 817.flac_s | CXX,C | 57 | 无损音频压缩 |
| 721.gcc_r | 821.gcc_s | CXX,C | 3,833 | C 语言优化编译器 |
| 723.llvm_r | 823.llvm_s | CXX,C | 3,167 | C/C++ 语言优化编译器 |
| 727.cppcheck_r | 827.cppcheck_s | CXX | 287 | C/C++ 代码静态分析 |
| 729.abc_r | 829.abc_s | CXX,C | 989 | 时序逻辑综合与形式化验证 |
| 734.vpr_r | 834.vpr_s | CXX,C | 210 | FPGA 布局布线 |
| 735.gem5_r | 835.gem5_s | CXX,C | 971 | 计算机体系结构仿真 |
| | 838.diamond_s | CXX,C | 239 | 生物信息学——宏基因组与蛋白测序 |
| | 846.minizinc_s | CXX,C | 372 | 约束规划 |
| 750.sealcrypto_r | | CXX,C | 39 | 安全与隐私——同态加密（HE）查询 |
| 753.ns3_r | 853.ns3_s | CXX | 942 | 互联网系统离散事件网络仿真器 |
| | 854.graph500_s | C | 10 | 图分析 |
| 777.zstd_r | | C | 58 | 数据压缩/解压缩 |

#### 浮点（Floating Point）

| SPECrate®2026 Floating Point | SPECspeed®2026 Floating Point | 语言[^1] | KLOC[^2] | 应用领域 |
| --- | --- | --- | --- | --- |
| | 800.pot3d_s | F | 12 | 太阳物理：有限差分法、共轭梯度求解器 |
| | 803.sph_exa_s | CXX | 3 | 天体物理——平滑粒子流体动力学（SPH） |
| 709.cactus_r | 809.cactus_s | CXX,C | 187 | 天体物理——相对论、有限差分、时间积分 |
| | 811.tealeaf_s | C | 5 | 高能物理 |
| | 816.nab_s | C | 26 | 分子建模 |
| | 820.cloverleaf_s | F | 10 | 显式流体动力学 |
| 722.palm_r | 822.palm_s | F | 298 | 大气科学 |
| 731.astcenc_r | | CXX | 43 | 图像压缩——自适应可扩展纹理压缩（ASTC） |
| 736.ocio_r | | CXX | 183 | 视觉特效与动画的色彩管理 |
| 737.gmsh_r | | CXX,C | 721 | 有限元网格生成 |
| 748.flightdm_r | | CXX | 100 | 航空飞行力学模型 |
| 749.fotonik3d_r | 849.fotonik3d_s | F | 15 | 计算电磁学（CEM） |
| | 857.namd_s | CXX | 9 | 经典分子动力学仿真 |
| 765.roms_r | 865.roms_s | F | 585 | 区域海洋建模 |
| 766.femflow_r | | CXX | 2,505 | 流体动力学：高阶有限元方法 |
| 767.nest_r | 867.nest_s | CXX | 208 | 脉冲神经网络模型的神经科学仿真器 |
| 772.marian_r | 872.marian_s | CXX | 219 | 书面语言的神经机器翻译 |
| 782.lbm_r | | C | 1 | 计算流体动力学，格子玻尔兹曼方法（LBM） |
| | 881.neutron_s | C | 4 | 核反应堆中子输运物理仿真 |

[^1]: 多语言基准中，**所列第一种语言**决定库与链接选项（[详情](https://www.spec.org/cpu2026/Docs/makevars.html#linkNote)）。
[^2]: KLOC = 千行代码量。统计包含全部 `src/` 文件，以及注释与空行。

### Q14. `7nn.benchmark` 与 `8nn.benchmark` 有何不同？

上表中部分基准成对出现：

```
 7nn.benchmark_r —— SPECrate 版本
 8nn.benchmark_s —— SPECspeed 版本
```

同一对内的基准共享（大部分）源代码，主要差异包括：

- **负载（Workloads）：** 输入数据集不同；SPECspeed 版本通常求解更复杂的问题。
- **内存（Memory）：** SPECrate 基准按约 **2 GB** 内可放下设计（具体系统可能有所出入）；SPECspeed 基准按约 **64 GB** 设计。
- **线程（Threading）：** SPECrate 每个拷贝只用 **一个线程**；多数 SPECspeed 基准使用**多线程**。

更多细节：[memory](https://www.spec.org/cpu2026/Docs/overview.html) / [OpenMP](https://www.spec.org/cpu2026/Docs/overview.html) / [rules](https://www.spec.org/cpu2026/Docs/runrules.html)。

## SPEC CPU 2026 指标（Metrics）

### Q15. 什么是「SPECspeed」与「SPECrate」指标？

衡量计算机性能的方式很多，最常见的两类是：

- **时间（Time）** —— 例如完成某负载所需的秒数。
- **吞吐（Throughput）** —— 单位时间内完成的工作量，例如每小时作业数。

**SPECspeed** 是基于时间的指标；**SPECrate** 是吞吐指标。

| SPECspeed® 指标计算 | SPECrate® 指标计算 |
| --- | --- |
| 套件中每个基准跑 **1 份拷贝**。 | 测试者自行选择并发拷贝数。 |
| 测试者可选择问题如何并行化。 | 使用单线程；**禁用 OpenMP**。 |
| 每个基准的性能比：<br>**参考机时间 / 被测系统（SUT）时间** | 每个基准的性能比：<br>**拷贝数 × 参考机时间 / SUT 时间** |
| 分数越高表示所需时间越少。 | 分数越高表示单位时间完成的工作越多。 |
| 示例：参考机跑完 `807.ntest_s` 用时 37556 秒。某 SUT 大约只用了 1/12 的时间，得分约 12。更精确地：`37556/2956.313 = 12.70` | 示例：参考机跑 1 份 `707.ntest_r` 用时 638 秒。某 SUT 跑 4 份，用时大约为一半，得分约 8。更精确地：`4*(638/294.95) = 8.65` |

无论 SPECspeed 还是 SPECrate，为提高结果可重复性，整套流程需要重复执行。测试者可选择：

- 将整套基准跑 **三次**，工具取各次结果的**中位数（median）**；或
- 跑 **两次**，工具取**较低的比值**（即更慢的那次）。

对选出的各基准比值再做**几何平均（Geometric Mean）**，作为报告的综合指标。

能耗（energy）类指标用同样方式计算，只是把公式中的时间换成能耗。

参考时间与参考能耗见结果页中的 observations：[www.spec.org/cpu2026/results/](https://www.spec.org/cpu2026/results/)。

### Q16. 什么是「base」与「peak」指标？

SPEC CPU 基准以**源代码**形式分发，必须先编译，于是就有一个问题：该怎么编译？可选范围很广，从低端的

```
--debug --no-optimize
```

一直到高度定制的优化，甚至改写源码的高端做法。区间上任意一点，对兴趣点不同的人来说都可能显得武断；但终究必须做出选择。

对 SPEC CPU 2026，SPEC 允许区间上的**两个点**。前者更适合希望构建过程相对简单的人；后者更适合愿意投入更多精力以换取更高性能的人。

- **base** 指标（例如 `SPECspeed2026_int_base`）要求：同一套件中、同一语言的所有模块，必须使用**相同的编译选项，且顺序相同**。所有正式报告的结果都必须包含 base 指标。
- 可选的 **peak** 指标（例如 `SPECspeed2026_int_peak`）更灵活：可为每个基准使用不同的编译选项，并允许**反馈指导优化（FDO）**。

base 规则允许的选项是 peak 规则的子集。合法的 base 结果在 peak 规则下也合法；但合法的 peak 结果**不一定**在 base 规则下合法。

更多信息见 [SPEC CPU 2026 Run and Reporting Rules](https://www.spec.org/cpu2026/Docs/runrules.html)。
