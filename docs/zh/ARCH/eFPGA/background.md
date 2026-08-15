# eFPGA 背景综述：文献、工具与处理器异构加速

> **用途：** 系统梳理 eFPGA 相关 **综述 / 专著 / 关键工作 / 工业 IP**，重点是 **近年来把 eFPGA 放进处理器 / SoC、做 CPU 侧异构加速** 的设计。  
> **配套：** 组内预取方向定位见 [`outline.md`](outline.md)。  
> **说明：** 下列为阅读地图与关键结论；具体数字以原文为准。CPU–独立 FPGA 板卡（HARP / CAPI / CXL）放在 §6，作「相干加速」对照，本身多数 **不是** 片上 eFPGA IP。

---

## 1. eFPGA 是什么、为什么重要

**Embedded FPGA（eFPGA）**：把 FPGA 的可编程逻辑核做成 **可嵌入 ASIC/SoC 的 IP**（硬核或可综合 soft fabric），而非独立 FPGA 芯片。

相对「整颗 FPGA 贴 CPU」：

| 维度 | 独立 FPGA / FPSoC | eFPGA IP |
|------|-------------------|----------|
| 集成 | 封装 / 板级 / 同封装 | **同一 die**，标准数字接口 |
| 面积 | 整片可编程逻辑 + 大量 I/O/SerDes | 可裁成 **刚好够用的 LUT/BRAM/DSP** |
| 延迟 | PCIe / 片间互连常成瓶颈 | 可接 NoC / cache / RoCC，**低延迟** |
| 用途 | 粗粒度整算法卸载 | 细粒度加速、后硅定制、安全 redaction、DMA/协议、**微架构侧路** |

经典动机（综述共识）：摊薄 NRE、修后硅缺陷、产品分化、在固定加速器之外保留可编程性。ASIC vs FPGA 的 PPA 鸿沟（约数十倍面积/功耗量级）仍在，因此 eFPGA **宜小、宜贴数据、宜打「变化的那一块逻辑」**——与组内「语义预取 / 哈希 \(f\)」叙事一致。

**两类实现：**

- **Hard eFPGA：** 全定制或半定制硬核 IP（Flex Logix EFLX、QuickLogic、Menta、Achronix Speedcore 等）——密度/速度好，工艺绑定、布局不灵活。  
- **Soft / synthesizable eFPGA：** RTL + 标准单元流生成（PRGA、OpenFPGA、FABulous、CMU soft fabric）——可移植、可定制，PPA 通常弱于 hard。

---

## 2. 综述与专著（建议阅读顺序）

### 2.1 专谈 eFPGA 的综述

| 文献 | 年份 | 读什么 |
|------|------|--------|
| **Bouaziz et al.**, *A review on embedded field programmable gate array architectures and configuration tools*, Turkish J. Elec. Eng. & Comp. Sci., 2019 | 2019 | **入门首选**：eFPGA 架构（细/粗粒度）、CAD/配置、设计挑战；强调「核要小、贴应用、要有配套工具链」 |
| 更广的 RC/嵌入式可重构综述（近年多篇，质量参差） | 2020s | 把 eFPGA 放进 FPGA / CGRA / DPR 谱系时扫一眼即可；细节不如上面这篇聚焦 |

### 2.2 可重构计算专著（地基，不专写「eFPGA」一词）

| 书 | 编者/作者 | 用途 |
|----|-----------|------|
| ***Reconfigurable Computing: The Theory and Practice of FPGA-Based Computation*** | Hauck & DeHon (Morgan Kaufmann, 2008) | 领域标准参考：架构、编译、运行时、案例；理解「可编程硬件当计算载体」 |
| ***Introduction to Reconfigurable Computing*** | Christophe Bobda | 教材向：从早期机器到嵌入式/粗粒度可重构；适合补概念 |

再往前的经典 survey（可选）：Compton & Hauck 等早期 *Reconfigurable Computing* survey——建立「为何 CPU+可编程逻辑」的历史脉络。

### 2.3 工具链与架构生成（做研究必碰）

| 框架 | 文献 / 入口 | 要点 |
|------|-------------|------|
| **VTR / VPR** | 长期维护的学术 FPGA CAD | 架构探索基准；多数 soft eFPGA 后端会接到它 |
| **PRGA** | Li et al., **FPGA’21**；[princetonuniversity/prga](https://github.com/princetonuniversity/prga) | Python 描述 → 可综合 Verilog + 开源 CAD；**显式支持 eFPGA IP**；Duet/CIFER/DECADES 同系 |
| **OpenFPGA** | Tang et al., **FPL’19**；*IEEE Micro* 2020 | XML 架构 → Verilog/布局/ bitstream；工业与 redaction 社区常用；QuickLogic Australis 亦依托其生态 |
| **FABulous** | **FPGA’21**；开源 eFPGA 框架 | 强调易用、可移植、部分重配；有 **RISC-V + eFPGA 定制指令** tapeout 案例 |
| **CMU Soft eFPGA** | Mohan et al., *Top-down Physical Design…*, **FPGA’21**；Mohan 博士论文 2022 | top-down 标准单元流；16nm/22nm tapeout；**RoCC 协处理器 + redaction** |

---

## 3. 工业 eFPGA IP（处理器周边常见）

了解「业界把 eFPGA 嵌进谁家 SoC」时看这些（白皮书为主，少公开微架构细节）：

| 厂商 / 产品 | 角色 |
|-------------|------|
| **Flex Logix EFLX** | 主流 hard eFPGA IP；按 LUT/DSP/RAM 比例裁剪；多颗量产 SoC |
| **QuickLogic**（Australis / ArcticPro） | 可生成硬核；与 OpenFPGA 路线有合作叙述 |
| **Menta** | 标准单元风格 eFPGA；材料中明确提到 **Data Prefetching / reconfigurable DMA** 等用例（与组内方向相关，但是营销表述） |
| **Achronix Speedcore** | 可规模化到很大 LUT 数；偏高性能嵌入 |
| **Xilinx/AMD Zynq、Intel Agilex 等** | 严格说是 **FPGA+硬核 CPU 的 FPSoC / 封装**，不是「给任意 ASIC 卖的小块 eFPGA IP」，但编程模型与相干口经验可借鉴（§6） |

---

## 4. 重中之重：eFPGA 进处理器 / CPU 异构加速

下面按 **贴核紧密度** 与 **是否真正片上 eFPGA** 组织。组内做预取/微架构侧路时，应优先精读 **§4.1–4.2**。

### 4.1 片上、cache-coherent、manycore + eFPGA（学术标杆）

#### Duet — HPCA’23（架构论文，必读）

| 项 | 内容 |
|----|------|
| **题目** | Duet: Creating Harmony between Processors and Embedded FPGAs |
| **作者** | Ang Li, August Ning, David Wentzlaff（Princeton） |
| **会议** | *2023 IEEE International Symposium on High-Performance Computer Architecture*（**HPCA 2023**），Montreal，2023-02 |
| **页码** | pp. 745–758 |
| **DOI** | [10.1109/HPCA56546.2023.10070989](https://doi.org/10.1109/HPCA56546.2023.10070989) |
| **IEEE Xplore** | https://ieeexplore.ieee.org/document/10070989 （以 DOI 为准） |
| **预印本** | [arXiv:2301.02785](https://arxiv.org/abs/2301.02785) |
| **作者 PDF** | https://parallel.princeton.edu/papers/HPCA23_Ang_Li.pdf |
| **开源** | Dolly：[PrincetonUniversity/Duet](https://github.com/PrincetonUniversity/Duet) |

- **核心主张：** 把 eFPGA 提升为与 CPU **对等** 的 NoC 节点，经 **双向 cache 相干** 集成；反对「CPU 只当 FPGA 的搬运工」的粗粒度卸载。  
- **两类后硅增强：**  
  1. **Fine-grained acceleration**：热点小任务下到 soft accelerator，CPU 管控制流与难加速部分；  
  2. **Hardware augmentation**：用 eFPGA **仿真微架构部件**（软 cache、协议/运行时小部件等）提升 CPU 效率。  
- **关键机制：** Duet Adapter + **硬件 Proxy Cache**（CPU 时钟域）把复杂相干协议翻译成 eFPGA 侧简单存储接口；可选 eFPGA 上的 soft cache。  
- **结果量级：** 通信延迟最高降约 **82%**、带宽约 **9.5×**；应用基准约 **1.5–24.9×** vs 纯 CPU（及相对 FPSoC 的对比）。  
- **对组内启示：** 「eFPGA = 微架构增强部件」与 **语义预取引擎** 同构；Proxy Cache / 相干旁路是接口设计模板。

#### CIFER — CICC’23 / SSCL（硅片，Duet 落地）

| 项 | 内容 |
|----|------|
| **题目（CICC’23）** | CIFER: A 12nm, 16mm², 22-Core SoC with a 1541 LUT6/mm² 1.92 MOPS/LUT, Fully Synthesizable, Cache-Coherent, Embedded FPGA |
| **作者** | Ting-Jung Chang et al.（Princeton 等；与 Duet 同组脉络） |
| **会议** | *2023 IEEE Custom Integrated Circuits Conference*（**CICC 2023**） |
| **DOI（CICC）** | [10.1109/CICC57935.2023.10121294](https://doi.org/10.1109/CICC57935.2023.10121294) |
| **作者 PDF** | https://angl-dev.github.io/assets/pdfs/CIFER_CICC23.pdf ；https://pncel.github.io/pdfs/cicc23_cifer.pdf |
| **期刊扩写（SSCL）** | *CIFER: A Cache-Coherent 12-nm 16-mm² SoC With Four 64-Bit RISC-V Application Cores…*，IEEE Solid-State Circuits Letters；IEEE Xplore：[10210635](https://ieeexplore.ieee.org/document/10210635)；作者稿：https://pncel.github.io/pdfs/sscl23.pdf |

- 12nm、约 16 mm²、多核 RISC-V + **可综合、全 cache-coherent eFPGA**（PRGA）；强调 **多核并行、真相干共享、非全定制可移植**。  
- eFPGA 规模约 **6.7K multimode LUT6** + BRAM；开源 Yosys+VPR+PRGA bitstream。  
- **必读原因：** 证明 Duet 类集成可上硅，soft eFPGA 密度约 **1541 LUT6/mm²**（原文指标）。

#### DECADES — CICC’23（更大异构 manycore + eFPGA）

| 项 | 内容 |
|----|------|
| **题目** | DECADES: A 67mm², 1.46TOPS, 55 Giga Cache-Coherent 64-bit RISC-V Instructions per second, Heterogeneous Manycore SoC with 109 Tiles including Accelerators, Intelligent Storage, and eFPGA in 12nm FinFET |
| **作者** | Fei Gao, Ting-Jung Chang, Ang Li, Marcelo Orenes-Vera, Davide Giri, Paul J. Jackson, August Ning, …, Margaret Martonosi, Luca Carloni, David Wentzlaff（**Princeton + Columbia** 等） |
| **会议** | *2023 IEEE Custom Integrated Circuits Conference*（**CICC 2023**），San Antonio，2023-04 |
| **DOI** | [10.1109/CICC57935.2023.10121257](https://doi.org/10.1109/CICC57935.2023.10121257) |
| **作者 PDF** | https://parallel.princeton.edu/papers/CICC-2023-DECADES-final.pdf ；Columbia：https://sld.cs.columbia.edu/pubs/gao_cicc23.pdf |
| **项目页** | https://decades.cs.princeton.edu/ |

- **109 tile** 级异构 SoC（GF 12nm FinFET，约 8.2×8.2 mm），含相干 RISC-V、加速器、**Intelligent Storage (IS)** 与 **eFPGA tile**。  
- 数据供给：IS 上 **MAPLE** 等做间接访存并行取数；eFPGA 提供后硅 soft accelerator。  
- 生态：OpenPiton/BYOC、ESP 等——「CPU+加速器+可编程逻辑」全栈参考。  
- **对组内启示：** 片上同时存在 **硬间接预取（MAPLE）** 与 **eFPGA**——正好对照「为何有些 \(f\) 仍值得放进 eFPGA」。

### 4.2 Soft eFPGA 作 RISC-V 协处理器 / 定制指令

| 工作 | 集成方式 | 意义 |
|------|----------|------|
| **CMU Soft eFPGA**（Mohan, FPGA’21 + 论文） | Rocket **RoCC** 接 heterogeneous soft fabric；另有 redaction tapeout | 标准「CPU 发自定义指令 / 共享内存语义」协处理器模型；流片实证 |
| **FABulous**（FPGA’21） | RISC-V + eFPGA **ISA 扩展** tapeout（180nm / 开源 45nm 等叙述） | 强调嵌入式、可部分重配；定制指令加速路径 |
| 各类 CGRA / 可重构阵列贴核 | 多非 LUT-FPGA | 同属「可编程加速」，粒度更粗；写 related 时区分 CGRA vs eFPGA |

### 4.3 eFPGA 作片上 introspection / 预取仿真（近预取）

| 工作 | 内容 | 与预取的关系 |
|------|------|----------------|
| **BRYT / IPU**（arXiv 2023 一带） | 轻量 introspection 单元；**IPUpro** 带 soft-logic/eFPGA | 用 eFPGA **仿真 Entangled Prefetcher**，约 **1 address/cycle**；目的是场测指标，**不注入真实预取** |
| 组内 [`outline.md`](outline.md) | eFPGA-backed Semantic Prefetcher | 在 Duet/IPU 证明「eFPGA 能跑预取 FSM」之上，进一步 **向 cache 发语义预取**（HASH/BITREV） |

### 4.4 集成形态对比（CPU 异构加速）

```
紧密度大致增加 →

[独立 FPGA 板]  HARP / CAPI / CXL 卡     ← 相干或半相干，但非 die 内 eFPGA IP
[同封装/同片 FPSoC]  Zynq / Agilex+硬核CPU ← 大块 FPGA + 硬核，编程成熟
[片上 eFPGA tile]   Duet / CIFER / DECADES ← 小型 eFPGA + NoC + 真/混合相干  ★
[贴核协处理器]      RoCC / 定制指令 eFPGA ← 指令级卸载，缓存模型因实现而异  ★
[微架构侧路]        预取/AGU/监控用小型 eFPGA ← 组内目标；文献最少，空白最大  ★★
```

★ = 近年学术重点；★★ = 发表空间。

---

## 5. 其它重要 eFPGA 论文簇（非加速但常同台出现）

### 5.1 硬件安全 / IP Redaction

用定制 soft eFPGA **抠掉** ASIC 关键逻辑，仅可信方持有 bitstream：

- ALICE（DAC’22 一带）、ARIANNA、*Not All Fabrics Are Created Equal*（TVLSI’23）等。  
- 工具：OpenFPGA / FABulous。  
- **对架构组：** 说明 soft eFPGA 已进入主流 EDA/安全叙事；eFPGA 架构参数影响面积与抗 SAT。

### 5.2 Soft fabric 物理设计

- CMU **top-down** soft eFPGA（FPGA’21）：相对 tile-by-tile bottom-up，全芯片 timing 视野，性能可提升约 20% 量级（原文）。  
- 早期 soft eFPGA / tactical cell 工作（UBC Lemieux 组等硕士论文）：标准单元 eFPGA 面积延迟优化——历史上下文。

### 5.3 为可重构阵列做的「预取」（勿与 CPU eFPGA 预取混淆）

- CDPM / CCP 等：**给 CGRA** 做 context-directed cache prefetch。  
- Transmuter + Prodigy 变体：可重构 manycore 上的间接预取。  
写 related work 时标明：**预取对象是 CGRA/MRA，不是「eFPGA 实现 CPU prefetcher」**。

---

## 6. 对照：CPU–FPGA 异构平台（多数不是 eFPGA IP）

做「相干加速」调研时必读，但引用时要说清 **集成层级不同**：

| 平台 / 文 | 要点 |
|-----------|------|
| **Intel HARP / Xeon+FPGA** | QPI/UPI + PCIe；FPGA 侧 caching agent；共享虚拟地址；大量应用论文 |
| **IBM CAPI / OpenCAPI** | 加速器相干挂 POWER；生物信息等案例 |
| **CCIX / CXL** | 标准化 CPU–加速器相干；Agilex 等硬 IP；近年 CXL survey 很多 |
| **Zynq MPSoC ACP 等** | 片上 ARM + FPGA；非对称相干口 |
| **ECI**（arXiv’22）等 | 可定制相干协议栈，面向 hybrid FPGA–CPU |
| **TRETS’19** 等 microarch 分析 | *In-Depth Analysis on Microarchitectures of Modern Heterogeneous CPU-FPGA Platforms*——平台对照表很好用 |

**一句话：** 这些工作证明 **相干共享内存对异构加速极重要**；Duet/CIFER 把同一思想收进 **die 内小 eFPGA**。

---

## 7. 按主题的精读清单（针对组内兴趣）

### 若目标是「CPU 里用 eFPGA 做异构 / 微架构增强」

1. **Duet (HPCA’23)** — 架构与相干集成圣经。  
2. **CIFER (CICC/SSCL’23)** — 硅片与密度数字。  
3. **DECADES (CICC’23)** — 大规模异构 + eFPGA + 数据供给（MAPLE）。  
4. **PRGA (FPGA’21)** — 自己生成/改 eFPGA 架构。  
5. **CMU Soft eFPGA + RoCC** — 协处理器集成范式。  
6. **FABulous (FPGA’21)** — 嵌入式 + 定制指令另一条开源线。  
7. **IPU/BRYT** — eFPGA 跑预取状态机的吞吐可行性。  
8. **Bouaziz 2019 review** — 补 CAD/配置与分类词汇。

### 若目标是「语义预取 / 哈希 \(f\)」（见 outline）

额外对照：

- 可编程预取：**ETP (ASPLOS’18)**、Prodigy/ATP——说明「可编程核」竞争方案。  
- 工业：Menta 等对 prefetch/DMA 的表述（弱证据，可作动机句）。  
- **空白句：** 片上 eFPGA 作 **cache 旁路语义 AGU** 并真实发预取——文献极少（outline §4）。

### 若目标是「自己做 soft eFPGA IP」

PRGA → OpenFPGA → FABulous 三选一深挖，再读 CMU top-down 物理设计；redaction 文当「eFPGA 架构参数」习题。

---

## 8. 时间线（处理器向，极简）

```
~2005–2015   soft eFPGA / 标准单元可编程逻辑探索（学术）；独立 FPGA 加速主流
2016–        Flex Logix 等 hard eFPGA IP 产业化
2019         OpenFPGA (FPL)；Bouaziz eFPGA review
2021         PRGA / FABulous / CMU top-down soft eFPGA (FPGA’21)
2022–2023   eFPGA redaction 流程（ALICE 等）；IPU 用 soft-logic 仿真预取
2023         Duet (HPCA)；CIFER / DECADES (CICC) —— 片上相干 eFPGA 硅片高峰
2024+        CXL 相干加速生态膨胀（多为独立/封装 FPGA，反衬 die 内 eFPGA 研究仍稀缺）
```

---

## 9. 对本仓库方向的直接含义

| 问题 | 背景结论 |
|------|----------|
| eFPGA 进 CPU 是否成熟？ | **架构+硅片已有标杆**（Duet/CIFER/DECADES）；工业 hard IP 亦成熟 |
| 异构加速主流形态？ | 相干共享内存 + 细粒度任务切分；粗粒度整算法卸载正在被 Duet 叙事挑战 |
| 预取能否用 eFPGA？ | **接口与吞吐已被侧面验证**（Duet 增强部件、IPU 仿真预取）；**语义 HASH 预取仍是缺口** |
| 该跟哪条开源线？ | 处理器研究优先 **PRGA + Duet/OpenPiton 生态**；安全/定制 eFPGA可看 OpenFPGA/FABulous |

---

## 10. 检索venue：会议 / 期刊（按 eFPGA 相关优先级）

> 面向「**eFPGA / 可编程逻辑进 SoC·处理器**」扫文献；越靠前越应优先盯。  
> 预取 SOTA（Berti/IPCP 等）另见体系结构顶会，不必和 eFPGA 检索混为一谈。

### ★★★ 第一优先：eFPGA / FPGA 架构与 CAD（本领域主场）

| Venue | 全称 / 类型 | 为何优先 |
|-------|-------------|----------|
| **FPGA** | ACM/SIGDA International Symposium on Field-Programmable Gate Arrays（会议） | **最核心**；PRGA、FABulous、CMU soft eFPGA、架构/CAD 多发于此 |
| **FPL** | International Conference on Field-Programmable Logic and Applications（会议） | 欧洲主场；OpenFPGA 等；eFPGA/应用面广 |
| **FCCM** | IEEE Symposium on Field-Programmable Custom Computing Machines（会议） | 可重构计算 + 系统；与「可编程硬件当计算」强相关 |
| **TRETS** | ACM Transactions on Reconfigurable Technology and Systems（期刊） | FPGA/可重构领域顶刊；长文、工具与架构 |

### ★★★ 第一优先（并列）：CPU–eFPGA 集成会发在体系结构顶会

| Venue | 全称 / 类型 | 为何优先 |
|-------|-------------|----------|
| **HPCA** | IEEE International Symposium on High-Performance Computer Architecture | **Duet** 所在；CPU–加速器/相干集成 |
| **ISCA** | International Symposium on Computer Architecture | 体系结构顶会；异构/可重构偶有重磅 |
| **MICRO** | IEEE/ACM International Symposium on Microarchitecture | 微架构；侧路部件、预取与可编程增强 |
| **ASPLOS** | ACM International Conference on Architectural Support for Programming Languages and Operating Systems | 软硬协同；可编程预取（如 ETP）、运行时重配 |

### ★★ 第二优先：硅片 / SoC / 电路实现（证明能上片）

| Venue | 全称 / 类型 | 为何优先 |
|-------|-------------|----------|
| **CICC** | IEEE Custom Integrated Circuits Conference | **CIFER、DECADES** 所在；学术 SoC + eFPGA 常见 |
| **ISSCC** | IEEE International Solid-State Circuits Conference | 顶级电路/芯片；工业与顶尖学术 eFPGA/FPSoC |
| **VLSI Symposium** | Symposium on VLSI Technology and Circuits（常分 Tech/Circuits） | 先进工艺 SoC、嵌入式可编程 |
| **JSSC** | IEEE Journal of Solid-State Circuits（期刊） | 电路顶刊；ISSCC/CICC 扩写 |
| **SSCL** | IEEE Solid-State Circuits Letters（期刊） | 短平快硅片结果；CIFER 有扩写 |

### ★★ 第二优先：EDA / 设计自动化（生成与工具链）

| Venue | 全称 / 类型 | 为何优先 |
|-------|-------------|----------|
| **DAC** | Design Automation Conference | eFPGA 生成、物理设计、系统集成 |
| **ICCAD** | International Conference on Computer-Aided Design | CAD/架构探索 |
| **DATE** | Design, Automation and Test in Europe | 欧洲 EDA + 嵌入式可重构 |
| **TCAD** | IEEE Transactions on Computer-Aided Design of Integrated Circuits and Systems（期刊） | CAD 长文 |

### ★ 第三优先：可重构 / FPGA 应用与扩展会议

| Venue | 全称 / 类型 | 备注 |
|-------|-------------|------|
| **FPT** | International Conference on Field-Programmable Technology | 亚太 FPGA |
| **ARC** | International Symposium on Applied Reconfigurable Computing | 应用向可重构 |
| **ReConFig** | International Conference on Reconfigurable Computing and FPGAs | 可重构系统 |
| **RAW** | Reconfigurable Architectures Workshop（常挂 IPDPS） | 短文/工作坊，可扫想法 |

### ★ 第三优先：总览与工业向期刊 / 杂志

| Venue | 全称 / 类型 | 备注 |
|-------|-------------|------|
| **IEEE Micro** | 杂志 | 架构综述、OpenFPGA 等介绍向；适合快速摸地图 |
| **CAL** | IEEE Computer Architecture Letters | 短文；想法验证 |
| **TVLSI** | IEEE Transactions on VLSI Systems | 嵌入式/SoC 实现 |
| **IEEE Access / Electronics** 等 | OA 期刊 | 噪声大；仅作补充，不作主检索 |

### 检索策略（实用）

1. **eFPGA 架构/IP/CAD**：FPGA → FPL → FCCM → TRETS → DAC/ICCAD。  
2. **贴 CPU / 相干 / 微架构增强**：HPCA → ISCA → MICRO → ASPLOS；再跟作者链到 CICC/ISSCC。  
3. **关键词组合示例：** `embedded FPGA` / `eFPGA` / `synthesizable FPGA` / `cache-coherent FPGA` / `FPGA fabric soft logic` + `RISC-V` / `many-core` / `prefetch`。  
4. **预取本征文献**另开检索：MICRO/HPCA/ISCA/ASPLOS + `prefetcher`（不必强加 eFPGA）。

---

## 11. 链接速查

| 资源 | URL |
|------|-----|
| Duet 开源 | https://github.com/PrincetonUniversity/Duet |
| PRGA | https://github.com/princetonuniversity/prga ；https://parallel.princeton.edu/prga/ |
| DECADES | https://decades.cs.princeton.edu/ |
| OpenFPGA | 社区/文档随 Tang et al. FPL’19 / IEEE Micro’20 |
| FABulous | FPGA’21 论文及开源仓库（搜索 FABulous eFPGA） |
| Flex Logix EFLX | https://flex-logix.com/eflx-efpga/ |
| QuickLogic eFPGA | https://www.quicklogic.com/efpga-ip/ |
| 组内 outline | [`outline.md`](outline.md) |

---

*初稿供组内扫文献用；投稿引用请核对卷期页码与最终公开版数字。*
