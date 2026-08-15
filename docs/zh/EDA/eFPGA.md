# eFPGA研究综述：架构、应用与进展（2005–2026）

> 豆包

## 一、概述

本文系统梳理近 20 年来嵌入式现场可编程门阵列（embedded FPGA, eFPGA）的研究进展，覆盖 ISCA、MICRO、ASPLOS、HPCA、ISSCC、JSSC、IEEE Micro、FPGA、FPL、FCCM 等顶级会议与期刊。重点分析 eFPGA 的架构框架、在 CPU 中作为计算加速的应用、优势与局限性，并对未来前景进行展望。

## 二、eFPGA 基本概念与架构框架

### 2.1 定义与基本原理

嵌入式 FPGA（eFPGA）是将 FPGA 的可编程逻辑阵列作为 IP 核嵌入到 ASIC 或 SoC 内部的技术。与独立 FPGA 芯片不同，eFPGA 不存在 I/O 引脚、SERDES、PCB 走线等板级开销，可直接通过片上总线或缓存一致性互连与 CPU、DSP、存储器等模块通信，从而获得更低的延迟、更高的带宽和更低的功耗。

eFPGA 的核心架构要素包括：

- 可配置逻辑块（CLB / Logic Tile）：由查找表（LUT，通常 4–6 输入）、触发器（FF）、进位链和多路选择器组成，用于实现任意组合逻辑和时序逻辑。
- 可编程互连（Routing / Switch Box）：由可编程多路选择器构成的布线网络，决定逻辑块之间的连接方式，是 eFPGA 面积的主要消耗者（传统 FPGA 中互连占约 80% 面积）。
- 块存储器（BRAM / LRAM）：嵌入的 SRAM 块，用于实现 FIFO、缓冲区、查找表等，容量通常为 2–72 Kb。
- DSP 块（DSP Slice / MAC）：硬连线的乘法累加单元，支持 18×18 或更宽的乘法运算，用于加速信号处理和机器学习。
- 配置存储器（Configuration Memory）：存储 LUT 真值表和互连选择位的 SRAM 或 Flash，决定 eFPGA 的具体功能。
- I/O 接口环（Core I/O Ring）：eFPGA 与 ASIC 其余部分的信号接口，可配置为输入、输出或双向。

### 2.2 硬 IP 与软 IP 两条技术路线

eFPGA 的实现方式分为两大类：

（1）硬 eFPGA（Hard eFPGA / Full-Custom）：以全定制或结构化版图方式实现，类似商业 FPGA 的物理设计。代表厂商包括 Achronix（Speedcore）、Flex Logix（EFLX）、QuickLogic（Australis）。优势是面积小、性能高、功耗低；劣势是依赖特定工艺节点，移植成本高，设计周期长。

（2）软 eFPGA（Soft eFPGA / Synthesizable）：用标准单元库以 RTL 综合方式实现，完全走标准 ASIC 设计流程。代表工作包括 UBC 的 Soft/Soft++ 方法学、普林斯顿的 PRGA、曼彻斯特的 FABulous、哥伦比亚的 OpenFPGA。优势是工艺无关、可移植性强、设计周期短；劣势是面积和功耗开销较大（通常比硬 eFPGA 大 2–3 倍）。

## 三、eFPGA 技术发展脉络（2005–2026）

### 3.1 萌芽期（2003–2009）：软 eFPGA 方法学与早期商业探索

这一阶段的核心问题是如何在标准 ASIC 流程中实现可编程逻辑。UBC 的 Steve Wilton 和 Guy Lemieux 团队提出了 Soft eFPGA 方法学（FPGA 2003、JSSC 2005），证明用标准单元综合实现可编程逻辑核的可行性，并进一步提出 Soft++（CICC 2005、TVLSI 2007），通过结构化布局、瓦片化架构和专用战术标准单元，将面积和延迟开销分别降低 58% 和 40%。

同期，工业界开始探索 eFPGA 与 CPU 的融合。Stretch 公司于 2004 年推出 S5000 系列，将 Tensilica Xtensa RISC 核与可重构计算阵列（ISEF, Instruction Set Extension Fabric）集成，允许在运行时通过软件定义自定义指令。2007 年推出的 S6000 系列增加了固定功能加速器（运动估计、熵编码、加密），主要面向视频和无线信号处理。Menta 公司（2005 年成立于法国 LIRMM 实验室）则推出了标准单元基的 eFPGA 软 IP 和 Origami 工具链。

### 3.2 成长期（2010–2017）：商业 IP 成熟与互连创新

这一阶段的标志是商业 eFPGA IP 的成熟和互连架构的突破。Flex Logix 成立于 2014 年，其联合创始人 Cheng Wang 在 ISSCC 2014 发表的 XFLX（Boundless Radix Interconnect）互连架构获得 Outstanding Paper Award，将互连面积减少约 45%，仅使用 5–7 层金属，使 eFPGA 能兼容大多数 ASIC 金属堆叠。Achronix 于 2017 年正式发布 Speedcore eFPGA IP，采用 6-LUT + BRAM + DSP64 的混合架构，支持 TSMC 16FFC/7nm 工艺。

学术界方面，2015 年出现了基于多级交换网络（MSSN）的软核 eFPGA，证明了可综合、无拥塞的互连架构。2017 年，多伦多大学的工作展示了可被 VTR（Verilog-to-Routing）CAD 流程支持的标准单元 FPGA 阵列，为开源 eFPGA 工具链奠定了基础。

### 3.3 爆发期（2018–2022）：开源框架涌现与硅验证

这一阶段是 eFPGA 研究的爆发期，三大开源框架相继问世：

- OpenFPGA（哥伦比亚大学，IEEE Micro 2020）：自动化生成可定制 FPGA 架构的开源框架，支持从架构描述到 GDSII 的完整流程。
- PRGA（普林斯顿大学，FPGA 2021）：高度可定制、可扩展的开源 FPGA 构建框架，生成可综合 Verilog 并提供完整 CAD 工具链，明确支持 eFPGA 场景。
- FABulous（曼彻斯特大学，FPGA 2021）：面向嵌入式场景的开源 eFPGA 框架，采用 CSV 配置文件定义架构，支持异构瓦片（逻辑、算术、存储器、自定义块）和动态部分重配置，已在 TSMC 180nm 和开源 45nm 工艺上流片验证。

硅验证方面，IBM/哈佛/Tufts 联合设计的 SMIV（ISSCC 2018、JSSC 2022）在 16nm 工艺上集成了双核 ARM Cortex-A53、Flex Logix eFPGA 和四核缓存一致性加速器，展示了 54.5 倍的灵活性-效率范围。博洛尼亚大学的 Arnold（JSSC 2021）在 GF22FDX 工艺上实现了 RISC-V MCU + eFPGA 的低功耗 IoT 节点，功耗仅 46.83 μW/MHz。

### 3.4 深化期（2023–2026）：缓存一致性、RISC-V 定制指令与安全

近期研究向三个方向深化：

（1）缓存一致的 CPU-eFPGA 集成：普林斯顿的 Duet（HPCA 2023）提出将 eFPGA 提升为与 CPU 对等的缓存一致性组件，通过非侵入式的双向缓存一致性互连实现细粒度加速。康奈尔/普林斯顿的 CIFER（CICC 2023、JSSC 2023）在 12nm 工艺上实现了全球首个开源、全缓存一致的多核 CPU-eFPGA SoC，包含 4 个 64 位 RISC-V 应用核、18 个 32 位 RISC-V 计算核和 1541 LUT6/mm² 的可综合 eFPGA。哥伦比亚的 DECADES（CICC 2023）在 12nm 上集成了 109 个瓦片，包含 7040 个多功能 6-LUT、32 个 40 位硬乘法器和 32 个 16Kb 双口 BRAM。

（2）RISC-V 可重构定制指令：22nm FinFET 上的 RISC-V SoC（ISSCC 2023、JSSC 2025）将 eFPGA 紧耦合到 CPU 数据通路和便签式存储器，实现 1.8 μs 快速配置和 748 GOPS/W 的能效，支持可重构自定义指令。SLMLET（COOL 2024）提出基于查找表式存储器（SLM）的面积高效 eFPGA 块，紧耦合到 RISC-V 处理器。2026 年的工作进一步将 eFPGA 用于 RISC-V 的可重构 SIMD 指令扩展，支持混合精度神经网络推理。

（3）eFPGA 硬件安全：eFPGA 重写（redaction）成为硬件 IP 保护的新兴方向。ICCAD 2021 首次系统探索了 eFPGA 重写的面积和时序开销；USENIX Security 2023 的 FuncTeller 则揭示了 eFPGA 并非天然安全，攻击者可通过侧信道推断隐藏功能。2025 年的 ARIANNA 提出了自动化的 eFPGA 重写设计流程，REDACTOR 则将重写扩展到 DNN 加速器领域。

## 四、eFPGA 在 CPU 计算加速中的应用（重点）

### 4.1 CPU-eFPGA 集成的三种范式

根据 eFPGA 与 CPU 的耦合程度，可将 CPU 加速应用分为三种架构范式：

| 耦合范式 | 互连方式 | 典型延迟/带宽 | 代表工作 |
| --- | --- | --- | --- |
| 松耦合（Loosely-Coupled） | 通过 AXI/AHB/Wishbone 等片上总线连接，eFPGA 作为内存映射外设 | 延迟较高（数十至数百周期），带宽受总线限制 | Arnold、An Open-Source eFPGA-based SoC、EPI eFPGA Tile |
| 紧耦合（Tightly-Coupled） | eFPGA 直接接入 CPU 数据通路/执行阶段，或紧耦合便签式存储器（SPM） | 延迟低（数周期），带宽高（16+ GB/s） | Stretch S6000、22nm RISC-V eFPGA SoC、SLMLET、Flex Logix+CEVA DSP |
| 缓存一致（Cache-Coherent） | eFPGA 作为对等节点接入缓存一致性互连，可直接读写 CPU 缓存 | 延迟最低，支持细粒度共享内存编程模型 | Duet（HPCA 2023）、CIFER（12nm）、DECADES（12nm）、SMIV（16nm） |

### 4.2 紧耦合：可重构自定义指令集扩展

紧耦合范式将 eFPGA 嵌入 CPU 的执行阶段或协处理器接口，使 eFPGA 实现的自定义指令能以接近原生指令的延迟执行。这是 eFPGA 用于 CPU 加速最直接的方式。

Stretch S5000/S6000（2004–2009）是最早商业化的紧耦合 eFPGA CPU。其架构将 Tensilica Xtensa RISC 核与 ISEF（Instruction Set Extension Fabric）可重构阵列紧耦合，ISEF 分为两个区域，允许一个区域运行时重配置而另一个继续执行。S6000 还集成了运动估计、熵编码、加密等固定功能加速器，在视频编码场景中实现了显著加速。Stretch 的 C/C++ 编译器可自动识别代码热点并将其"压缩"为单条自定义指令。

22nm FinFET RISC-V eFPGA SoC（ISSCC 2023 / JSSC 2025）代表了当前紧耦合范式的最新进展。该工作将可综合 eFPGA 紧耦合到 RISC-V CPU 和 SoC 便签式存储器，实现：

- 1.8 μs 超快速配置时间，支持运行时动态切换自定义指令
- 16 GB/s 并行高带宽访问便签式 SRAM
- 748 GOPS/W 的能效，比纯 RISC-V CPU 执行提升 1–2 个数量级
- 支持可重构自定义指令，eFPGA 直接接入 CPU 执行流水线

SLMLET（COOL 2024）提出基于查找表式存储器（SLM, Search-Look-aside Memory）的面积高效 eFPGA 块，紧耦合到 RISC-V 处理器。SLM 逻辑块尺寸仅 106.80 μm 见方，每个瓦片包含 4 个 5 输入 SLM 逻辑单元，在 28nm 工艺上实现了高密度的可重构逻辑。芯片面积 4.2 mm × 4.2 mm。

Flex Logix + CEVA DSP（2022）是工业界紧耦合的代表。Bar-Ilan 大学在 TSMC 16nm 上流片了 SOC2，将 CEVA-X2 DSP 与 Flex Logix EFLX eFPGA 集成，实现了可灵活变更的 DSP 指令集架构（ISA），允许根据不同工作负载动态添加自定义硬连线指令。

混合精度神经网络 SIMD 扩展（2026）进一步将 eFPGA 用于 RISC-V CPU 的可重构 SIMD 指令扩展。该工作设计了可配置精度的数据通路和创新的 SIMD 指令，支持混合精度神经网络的部署，通过 eFPGA 实现向量数据映射策略的优化。

### 4.3 缓存一致：eFPGA 作为对等计算节点

缓存一致范式是 eFPGA CPU 加速的前沿方向，其核心思想是将 eFPGA 提升为与 CPU 核对等的一等公民，通过缓存一致性互连共享内存层次，从而消除数据拷贝开销，支持细粒度加速。

Duet（HPCA 2023，普林斯顿大学）是这一方向的标志性工作。作者 Ang Li、August Ning 和 David Wentzlaff 提出了可扩展的众核-FPGA 架构，通过非侵入式的双向缓存一致性集成将 eFPGA 提升为与处理器对等的节点。Duet 支持两种加速范式：

- 硬件增强（Hardware Augmentation）：将大算法映射到多个小加速器，利用处理器处理动态控制流和不易加速的任务
- 细粒度加速（Fine-Grained Acceleration）：利用 eFPGA 加速广泛领域中丰富的细粒度加速机会，而非仅加速完整稳定算法

Duet 基于 OpenPiton + PRGA 实现了 RTL 级原型，开源在 GitHub（PrincetonUniversity/duet）。其核心创新是 Duet Adapter，使 eFPGA 能以非侵入方式接入缓存一致性互连，无需修改 CPU 核本身。

CIFER（CICC 2023 / JSSC 2023，康奈尔+普林斯顿）是全球首个开源、全缓存一致、异构多核 CPU-eFPGA SoC 的硅验证。12nm 工艺、16 mm² 芯片集成：

- 4 个 64 位、可运行 Linux 的 RISC-V 应用核（Ariane）
- 3 个 TinyCore 集群，每个含 6 个 32 位 RISC-V 计算核（共 18 核）
- EDA 综合的标准单元 eFPGA，密度达 1541 LUT6/mm²，性能 1.92 MOPS/LUT
- 全缓存一致性互连，eFPGA 可直接访问 CPU 缓存层次

CIFER 在疫情期间由研究生和博士后团队在 7 个月内完成设计，充分展示了开源工具链（OpenPiton、BYOC、PyMTL、PyOCN、Ariane、PRGA）对敏捷芯片开发的价值。该工作获得 CICC 2023 最佳学生论文提名。

DECADES（CICC 2023，哥伦比亚大学）是另一颗 12nm 异构众核 SoC，67 mm² 面积包含 109 个瓦片，其中 eFPGA 部分包含：

- 7040 个多功能 6 输入 LUT
- 32 个 40 位硬乘法器
- 32 个 16Kb 双口块 RAM

eFPGA 由 PRGA 生成 RTL，再通过标准数字 EDA 工具综合到标准单元。DECADES 的 eFPGA 允许用户在流片后生成"软"加速器，配合 64 位 RISC-V 核实现 55 Giga 缓存一致指令/秒的吞吐量和 1.46 TOPS 的算力。

SMIV（ISSCC 2018 / JSSC 2022，IBM+哈佛+Tufts）在 16nm 工艺上集成了双核 ARM Cortex-A53、Flex Logix eFPGA（2×2 阵列，含 2 个逻辑瓦片和 2 个 DSP 瓦片，共约 5K 6-LUT）和四核缓存一致性加速器（CCA）。eFPGA 通过 ACP（Accelerator Coherence Port）接入缓存一致性互连，测量结果显示 eFPGA 实现比软件实现能效提升 28.9 倍、吞吐量提升 120 倍，整个 SoC 的灵活性-效率范围达 54.5 倍。

### 4.4 松耦合：内存映射加速器与 SoC 集成

松耦合范式通过标准片上总线（AXI/AHB/Wishbone）将 eFPGA 作为内存映射外设连接到 CPU，实现最简单但延迟较高。适用于粗粒度、数据密集型加速任务。

Arnold（JSSC 2021，博洛尼亚大学）在 GF22FDX 22nm 工艺上实现了 RISC-V MCU + eFPGA 的低功耗 IoT 节点。eFPGA 紧耦合到 MCU 的扩展接口，工作电压 0.5–0.8V，功耗 46.83 μW/MHz，算力 600 MOPS。Arnold 的架构灵活性允许完全利用可配置逻辑，支持智能传感器、可穿戴设备等低功耗 IoT 场景。

An Open-Source eFPGA-based SoC Design for Computation Acceleration（2024）基于开源 eFPGA 构建了计算加速 SoC。eFPGA 为均匀岛式风格，包含 1960 个 LUT 和 448 个 I/O，CLB 含 10 个 6-LUT，开关盒为 Wilton 风格（连接度参数 3），采用扫描链配置协议。系统通过 Wishbone B4 总线协议通信，eFPGA 作为可重构加速器连接到 CPU 总线。

EPI eFPGA Tile（欧洲处理器计划，2019–2024）由 Menta 提供 eFPGA IP，集成到通用处理器芯片（GPP）中。eFPGA 瓦片通过明确定义的互连与处理器集群、专用硬件加速器连接，支持运行时重配置，在某些工作负载上达到 18 倍加速。EPI 还探索了 eFPGA 用于后量子密码学（PQRC）的架构，在 GlobalFoundries 22FDX+ 工艺上完成了物理实现。

Towards Reconfigurable Accelerators in HPC（FPGA 2022）设计了面向异构 SoC 的多用途 eFPGA 瓦片，用于 HPC 场景。该工作集成了 Picos（依赖检测算法的快速硬件实现），可替代传统软件运行时，显著降低运行时开销，透明加速细粒度并行应用。

### 4.5 CPU 加速的关键技术挑战

尽管 eFPGA 在 CPU 加速中展现出巨大潜力，但仍面临以下关键挑战：

1. 配置延迟与开销：eFPGA 的配置时间从微秒级（紧耦合、扫描链）到毫秒级（大阵列、全配置）不等。对于细粒度加速，配置开销可能抵消加速收益。部分重配置（Partial Reconfiguration）和快速配置接口是主要缓解手段。
2. 面积效率：软 eFPGA 的面积通常是等效 ASIC 的 20–40 倍，硬 eFPGA 也有 5–10 倍。在 CPU 芯片中分配多少面积给 eFPGA 是关键权衡。
3. 编程模型与工具链：如何让软件开发者高效利用 eFPGA 仍是难题。高级综合（HLS）、自动热点识别、自定义指令自动生成是活跃研究方向。
4. 缓存一致性复杂度：将 eFPGA 接入缓存一致性互连需要处理内存序、缓存行粒度、一致性协议等复杂问题，Duet 的非侵入式 Adapter 是一个有前景的方向。
5. 虚拟化与多任务：在多任务/多租户环境中，eFPGA 的时间分片和空间分区机制尚不成熟，类似 AmorphOS、ViTAL 的 FPGA 虚拟化技术需要适配 eFPGA 场景。

## 五、eFPGA 其他应用领域

### 5.1 硬件安全与 IP 保护

eFPGA 重写（eFPGA-based Hardware Redaction）是近年来增长最快的应用方向。其核心思想是将设计中的关键模块替换为 eFPGA，流片时 eFPGA 的功能未定义，只有授权用户在制造后加载正确比特流才能恢复功能，从而防止代工厂过度生产和逆向工程。

- Exploring eFPGA-based Redaction for IP Protection（ICCAD 2021）：首次系统探索 eFPGA 重写的面积和时序开销，基于开源 FPGA 生成流程进行实验。
- Not All Fabrics Are Created Equal（2021）：研究不同 eFPGA 架构参数对 IP 重写安全性的影响，指出并非所有 eFPGA 都能提供足够的安全保证。
- Evaluating the Security of eFPGA-based Redaction Algorithms（2023）：评估 eFPGA 重写算法对 SAT 攻击和暴力攻击的抵抗能力。
- FuncTeller: How Well Does eFPGA Hide Functionality?（USENIX Security 2023）：揭示 eFPGA 并非天然安全，攻击者可通过侧信道和结构分析推断隐藏功能。
- Predictive Model Attack for Embedded FPGA Logic Locking（CCS 2022）：提出基于预测模型的攻击方法，可破解 eFPGA 逻辑锁定。
- ARIANNA（2025）：提出自动化的 eFPGA 重写设计流程，包括模块识别、架构优化和比特流生成。
- REDACTOR（2025）：将 eFPGA 重写扩展到 DNN 加速器安全领域，研究关键模块选择和物理设计实现。
- Physical-Aware eFPGA Redaction（2026）：提出物理感知的重写方法，利用综合和布局布线后的精确时序、空间和连接信息做出更优的分区决策。
- Dynamic Security Management via eFPGA（MWSCAS 2024）：在 22nm CMOS 上验证通过 eFPGA 进行 SoC 动态安全管理。

### 5.2 机器学习与 AI 推理

eFPGA 的可重构性使其适合加速不断演进的机器学习算法。Achronix Speedcore Gen4 增加了 MLP（Machine Learning Processor）块，每个块含 32 个 MAC，支持整数和浮点格式。Flex Logix 则推出了 InferX AI 推理技术。

学术方面，Embedded FPGA Developments in 130nm and 28nm CMOS（2024）使用 FABulous 框架在两种工艺上实现 eFPGA，用于粒子探测器读出中的机器学习推理，证明 eFPGA 可在 ASIC 内动态重配置 ML 模型架构而非仅更新权重。SMIV（16nm）的 eFPGA 在 DNN 推理中实现了 28.9 倍能效提升。2026 年的混合精度神经网络工作则通过 eFPGA 扩展 RISC-V SIMD 指令来支持 AI 推理。

### 5.3 通信与网络

eFPGA 在通信和网络领域有天然优势，因为通信标准（如 5G/6G、加密协议）经常更新，需要硬件级的灵活性。Achronix Speedcore 被用于基站和数据中心芯片，Flex Logix EFLX 则被用于网络处理。eFPGA 可用于加速加密/解密（AES、SHA）、压缩、数据包处理等功能，且同一 ASIC 可通过重配置支持不同应用。

### 5.4 物联网与边缘计算

低功耗 IoT 是 eFPGA 的重要应用场景。Arnold（GF22FDX）以 46.83 μW/MHz 的功耗实现了灵活的低功耗 IoT 节点。SMIV（16nm）的功耗范围从 1.1 mW（仅 always-on 集群）到 1.36 W（全芯片最大吞吐量），覆盖了广泛的 IoT 功率包络。eFPGA 允许在同一芯片上通过重配置支持不同的传感器接口和数据处理算法，降低 IoT 设备的 SKU 数量。

### 5.5 航空航天与国防

航空航天领域对芯片的灵活性和长期可维护性有特殊需求。Menta 为 EPI 欧洲处理器计划提供 eFPGA IP，并针对航天和国防应用提供抗辐射加固的 eFPGA。QuickLogic 也提供辐射加固的 eFPGA IP。eFPGA 可用于卫星载荷中的软件无线电、加密算法更新和在轨重配置。

### 5.6 高能物理与科学仪器

Embedded FPGA Developments in 130nm and 28nm CMOS（2024）探索了 eFPGA 在下一代对撞机实验粒子探测器读出中的应用。eFPGA 可在前端 ASIC 中实现可重配置的 ML 推理，不仅能更新模型权重，还能重配置整个 ML 架构，填补了专用 ASIC（刚性）和独立 FPGA（高功耗）之间的技术空白。

## 六、eFPGA 的核心优势

### 6.1 后硅可重构性（Post-Silicon Reconfigurability）

eFPGA 最核心的优势是流片后的可重构能力。传统 ASIC 一旦流片，功能即固定，无法修改或升级；而集成 eFPGA 的 SoC 可在制造后通过加载不同比特流来改变 eFPGA 区域的功能。这带来了多重价值：

- 标准升级：通信协议（5G→6G）、加密算法（RSA→后量子密码）、AI 模型架构等标准演进时，无需重新流片即可更新硬件。
- bug 修复：流片后发现的逻辑错误可通过重配置 eFPGA 修复，避免昂贵的 respin。
- 多 SKU 统一：同一芯片可通过不同 eFPGA 配置服务不同市场和客户，降低设计和制造成本。
- 运行时自适应：根据当前工作负载动态切换 eFPGA 功能，实现能效最优化。

### 6.2 低功耗与高能效

与独立 FPGA 相比，eFPGA 消除了板级 I/O、SERDES、PCB 走线等开销，功耗显著降低。SMIV（16nm）的测量显示，eFPGA 实现比等效软件实现能效提升 28.9 倍。22nm RISC-V eFPGA SoC 达到 748 GOPS/W。Arnold（GF22FDX）在 0.5V 近阈值电压下功耗仅 46.83 μW/MHz，适合电池供电的 IoT 设备。

与 ASIC 加速器相比，eFPGA 虽然面积和功耗较大，但其灵活性避免了为每种工作负载设计专用加速器的 NRE 成本，且可通过重配置在同一硬件上时分复用多种加速功能。

### 6.3 高带宽与低延迟片上通信

eFPGA 直接嵌入 SoC 内部，可通过片上总线、紧耦合接口或缓存一致性互连与 CPU 和存储器通信，带宽远高于独立 FPGA 的板级互连，延迟显著降低。22nm RISC-V eFPGA SoC 实现了 16 GB/s 的便签式存储器带宽。缓存一致的 eFPGA（Duet、CIFER、DECADES）可直接读写 CPU 缓存，消除了传统加速器的 DMA 数据拷贝开销。

### 6.4 PPA 权衡灵活性

eFPGA 提供了 ASIC（最高性能/最低功耗/最低灵活性）和独立 FPGA（最低性能/最高功耗/最高灵活性）之间的中间点。设计者可根据应用需求选择：

- 硬 eFPGA：面积小、性能高，但工艺依赖
- 软 eFPGA：工艺无关、可移植，但面积较大
- 细粒度 vs 粗粒度：灵活性 vs 面积效率
- eFPGA 面积占比：根据加速需求和芯片面积预算调整

### 6.5 安全性

eFPGA 为硬件安全提供了新机制。eFPGA 重写可防止代工厂过度生产和 IP 盗窃。动态安全管理（MWSCAS 2024）允许通过 eFPGA 在运行时更新安全策略和加密算法。后量子密码学 eFPGA（EPI/Menta）可在量子计算威胁出现后升级加密硬件。

## 七、eFPGA 的局限性与挑战

### 7.1 面积开销

eFPGA 的面积效率远低于等效 ASIC。传统 FPGA 中，可编程互连占约 80% 的面积，LUT 和配置存储器占剩余部分。软 eFPGA（标准单元实现）的面积通常是等效 ASIC 的 20–40 倍，硬 eFPGA 也有 5–10 倍。这意味着在 CPU 芯片中分配 eFPGA 区域需要仔细的面积-性能权衡。对于面积敏感的应用（如移动 SoC、微控制器），eFPGA 的面积开销可能难以接受。

缓解方向：粗粒度 eFPGA（CGRA 风格）可显著提高面积效率；专用战术标准单元（Soft++）可降低软 eFPGA 开销；3D 集成（eFPGA 与逻辑层堆叠）可缓解平面面积压力。

### 7.2 配置延迟与开销

eFPGA 的配置时间取决于阵列大小和配置接口。小阵列（如紧耦合自定义指令 eFPGA）可在微秒级完成配置（22nm RISC-V SoC 为 1.8 μs），但大阵列（数万 LUT）的全配置可能需要毫秒级。对于细粒度、频繁切换的加速场景，配置开销可能抵消加速收益。

缓解方向：部分重配置（Partial Reconfiguration）只重配置需要变化的区域；快速配置接口（并行加载、扫描链优化）；配置缓存/上下文切换（类似 AmorphOS 的多上下文管理）。

### 7.3 工具链成熟度与编程难度

eFPGA 的 CAD 工具链（综合、技术映射、布局布线、比特流生成）成熟度远低于商业 FPGA。开源框架（OpenFPGA、PRGA、FABulous）虽提供了完整流程，但在优化质量（QoR）和运行时间上仍有差距。商业 IP（Achronix ACE、Flex Logix EFLX Compiler、Menta Origami）工具链较成熟，但通常是闭源且价格昂贵。

更根本的挑战是编程模型：如何让软件开发者（而非硬件工程师）高效利用 eFPGA。高级综合（HLS）、自动热点识别、自定义指令自动生成、领域特定语言（DSL）是活跃研究方向，但距离"一键加速"仍有距离。

### 7.4 软 eFPGA 的性能差距

软 eFPGA 用标准单元实现，其性能（频率、延迟、功耗）显著低于硬 eFPGA。CIFER（12nm）的可综合 eFPGA 密度为 1541 LUT6/mm²，而商业硬 eFPGA（如 Achronix Speedcore）在同工艺下密度可达数千 LUT/mm²。软 eFPGA 的工作频率通常在数百 MHz，而硬 eFPGA 可达 1 GHz 以上。

缓解方向：结构化布局（Soft++）、自顶向下物理设计方法学（FPGA 2021）、专用标准单元、先进工艺节点（7nm/5nm）。

### 7.5 调试与可观测性

eFPGA 内部信号的可观测性差，调试困难。传统 FPGA 有成熟的在线逻辑分析仪（如 Xilinx ILA、Intel SignalTap），但 eFPGA 的调试基础设施尚不完善。对于 CPU-eFPGA 紧耦合系统，还需要跨 CPU 和 eFPGA 的协同调试能力。

### 7.6 可靠性与老化

eFPGA 的配置存储器（SRAM）受单粒子翻转（SEU）影响，在航空航天和高可靠性场景中需要冗余和纠错。频繁重配置可能导致配置接口的电迁移和老化。软错误率（SER）和长期可靠性是 eFPGA 在关键应用中需要解决的问题。

### 7.7 生态与标准化

eFPGA 缺乏统一的架构标准和编程接口。不同厂商的 eFPGA IP（Achronix、Flex Logix、Menta、QuickLogic）架构各异，工具链不兼容，比特流格式私有。开源框架虽推动了标准化，但与商业生态的整合仍需时间。RISC-V 自定义指令的标准化（如 RISC-V Custom 扩展、eXtension 接口）可能为 eFPGA 提供统一的集成接口。

## 八、开源 eFPGA 框架与工具链

### 8.1 OpenFPGA（哥伦比亚大学）

**论文：** OpenFPGA: An Open-Source Framework for Agile Prototyping Customizable FPGAs（IEEE Micro 2020）

**作者：** Xifan Tang, Edouard Giacomin, Aurélien Alacchi, Baudouin Chauviere, Pierre-Emmanuel Gaillardon

**源码：** https://github.com/lnis-uofu/OpenFPGA

核心特点：

- 自动化生成可定制 FPGA 架构的开源框架，支持从架构描述（XML）到 GDSII 的完整流程
- 基于 VPR（Versatile Packing, Placement and Routing）的 CAD 流程，支持技术映射、布局布线
- 生成可综合的 Verilog RTL，支持标准 ASIC 设计流程
- 支持异构架构（LUT、BRAM、DSP、自定义块）
- 广泛用于学术研究，包括 eFPGA 重写、神经形态计算等

### 8.2 PRGA（普林斯顿大学）

**论文：** PRGA: An Open-Source FPGA Research and Prototyping Framework（FPGA 2021）

**作者：** Ang Li, David Wentzlaff

**源码：** https://github.com/PrincetonUniversity/prga

核心特点：

- 高度可定制、可扩展的开源 FPGA 构建框架，明确支持 eFPGA 场景
- Python API 驱动的架构描述，生成可综合 Verilog
- 完整的 CAD 工具链（综合、技术映射、布局布线、比特流生成）
- 支持异构瓦片、部分重配置、自定义 I/O 接口
- 已用于 Duet（HPCA 2023）、CIFER（12nm）、DECADES（12nm）等硅验证芯片
- 与 OpenPiton 开源众核处理器集成，支持缓存一致的 CPU-eFPGA 系统

### 8.3 FABulous（曼彻斯特大学）

**论文：** FABulous: An Embedded FPGA Framework（FPGA 2021）

**作者：** Nguyen Cong Dao, Dirk Koch, et al.

**源码：** https://github.com/FPGA-Research-Manchester/FABulous

**文档：** https://fabulous.readthedocs.io

核心特点：

- 面向嵌入式场景的开源 eFPGA 框架
- 采用 CSV 配置文件定义架构，易于定制
- 支持异构瓦片：逻辑瓦片、算术瓦片、存储器瓦片、用户自定义瓦片
- 支持动态部分重配置（DPR）
- 已在 TSMC 180nm 和开源 45nm（SkyWater）工艺上流片验证
- 后续工作（FPGA 2022）优化了瓦片接口和配置逻辑，对比了 frame-based 和 shift-register 配置模式
- 用于粒子探测器 ML 推理（130nm/28nm）等应用

### 8.4 三大开源框架对比

| 维度 | OpenFPGA | PRGA | FABulous |
| --- | --- | --- | --- |
| 定位 | 通用 FPGA 架构原型 | eFPGA 与 CPU 集成 | 嵌入式 eFPGA |
| 架构描述 | XML | Python API | CSV |
| CAD 流程 | VPR 基 | 自研 + VPR | Yosys + 自研 |
| 部分重配置 | 有限支持 | 支持 | 原生支持 |
| 硅验证 | 多项研究 | CIFER/DECADES (12nm) | 180nm/45nm/130nm/28nm |
| CPU 集成 | 需自行集成 | OpenPiton 原生集成 | 需自行集成 |
| 异构瓦片 | 支持 | 支持 | 支持（含自定义块） |

### 8.5 其他相关开源工具

- Yosys：开源逻辑综合工具，是 FABulous、PRGA 等框架的综合前端
- VTR（Verilog-to-Routing）：开源 FPGA CAD 流程，包含 ODIN II、ABC、VPR
- NextPNR：开源 FPGA 布局布线工具，支持多种架构
- Soft/Soft++（UBC）：早期软 eFPGA 方法学，虽非完整开源框架，但奠定了标准单元 eFPGA 的基础

## 九、商业 eFPGA IP 概览

### 9.1 Achronix Speedcore

**架构：** 6 输入 LUT + LRAM（2Kb/4Kb 分布式 RAM）+ BRAM（20Kb/72Kb 块 RAM）+ DSP64（18×27 乘法器，可级联）+ MLP（机器学习处理器，每块 32 个 MAC，支持整数和浮点）

**交付形式：** GDSII 硬宏，全定制版图

**工艺：** TSMC 16FFC、12FFC、7nm

**工具链：** ACE（Achronix CAD Environment），支持 Synopsys Synplify 综合

**特点：** 高性能、高密度，支持 1GHz+ 工作频率；MLP 块专为 AI 推理优化；支持 NoC（片上网络）集成

**官网：** https://www.achronix.com/speedcore-architecture

### 9.2 Flex Logix EFLX

**架构：** 4 输入/6 输入 LUT + 可集成 RAM（基于 TSMC Memory Compiler 或客户自定义 RAM）+ DSP/MAC 选项

**核心创新：** XFLX（Boundless Radix Interconnect）互连架构，ISSCC 2014 Outstanding Paper，互连面积减少约 45%，仅使用 5–7 层金属，利用率 >90%

**阵列扩展：** ArrayLinx 阵列互连，单个 EFLX 瓦片可拼接为最大 7×7 阵列，支持在瓦片间集成 RAM

**交付形式：** 硬宏（标准单元基，非全定制）

**工艺：** TSMC 40nm、28nm、16nm、12nm、7nm（设计中）

**工具链：** EFLX Compiler，支持 Xilinx 网表映射，可直接使用 Vivado 综合结果

**特点：** TSMC 首个 eFPGA IP 联盟伙伴；已用于 SMIV（16nm）、SOC2（CEVA DSP，16nm）等硅验证；后推出 InferX AI 推理技术

**资料：** https://assets.flex-logix.com/resources/2022%2006%20EFLX%204-page%20Overview%20TGF-eFPGA.pdf

### 9.3 Menta eFPGA

**架构：** 标准单元基软 IP，工艺无关；支持定制和预定义 IP 核

**工具链：** Origami Designer（架构定制）+ Origami Programmer（比特流生成）

**工艺：** 支持任意 foundry 和节点，包括 TSMC 28nm、GlobalFoundries 22FDX+ 等

特点：

- 2005 年成立于法国 LIRMM 实验室，是最早的 eFPGA IP 公司之一
- 软 IP 路线，完全走标准 ASIC 流程，可移植性强
- 为 EPI 欧洲处理器计划提供 eFPGA IP，集成到通用处理器芯片
- 用于后量子密码学（PQRC）、航空航天、硬件安全等领域
- 2026 年推出 MFC eFPGA Chiplet，面向异构集成
- 被日本 AIST 用于密码学和硬件安全研究

**官网：** https://www.menta-efpga.com/

### 9.4 QuickLogic Australis

**架构：** eFPGA IP 生成器，支持跨 foundry 和节点

**特点：** 支持辐射加固（rad-hard）版本，面向航空航天和国防应用；低功耗优化，面向移动和 IoT

**官网：** https://www.quicklogic.com

### 9.5 其他商业 eFPGA

- Intel eFPGA for Agilex M-Series：Intel 的 eFPGA IP，基于 Agilex 架构
- SiFive 可定制指令 + eFPGA：RISC-V IP 厂商与 eFPGA 厂商合作，提供可定制指令的 RISC-V 核
- Codasip + eFPGA：RISC-V 处理器 IP 厂商，支持自定义指令和可重构扩展

### 9.6 商业 IP 对比总结

| 厂商 | 实现方式 | 工艺 | 核心优势 | 典型应用 |
| --- | --- | --- | --- | --- |
| Achronix | 全定制硬宏 | 16/12/7nm | 最高密度/性能，MLP AI 块 | 数据中心、5G、AI |
| Flex Logix | 标准单元硬宏 | 40/28/16/12/7nm | XFLX 互连，高利用率 | 网络、IoT、DSP |
| Menta | 标准单元软 IP | 任意工艺 | 工艺无关，可移植 | HPC、航天、安全 |
| QuickLogic | eFPGA 生成器 | 跨 foundry | 辐射加固，低功耗 | 国防、移动、IoT |

## 十、前景与未来研究方向

### 10.1 Chiplet 与 3D 集成中的 eFPGA

随着 Chiplet 架构的普及，eFPGA 有望以独立 chiplet 的形式通过 UCIe、BoW 等先进封装互连与 CPU、GPU、AI 加速器集成。Menta 已推出 MFC eFPGA Chiplet。3D 堆叠（如 eFPGA 层与逻辑层通过 TSV 或混合键合连接）可缓解 eFPGA 的平面面积压力，同时提供更高的互连密度和带宽。未来研究方向包括：eFPGA chiplet 的架构设计、先进封装下的热管理、3D eFPGA 的 CAD 工具链。

### 10.2 AI 时代的可重构加速

AI 模型架构（Transformer、MoE、扩散模型等）快速演进，固定 ASIC 加速器难以跟上变化。eFPGA 的可重构性使其成为 AI 加速的理想选择。Achronix Speedcore Gen4 的 MLP 块、Flex Logix InferX 已在这一方向布局。未来研究包括：

- 面向 AI 的 eFPGA 架构优化（低精度 MAC、稀疏计算支持、存算一体）
- eFPGA 上的自动 DNN 映射与编译
- 可重构 SIMD/向量指令扩展（2026 年混合精度 NN 工作是起点）
- 大模型推理中的 eFPGA 与 CPU/GPU 协同

### 10.3 RISC-V 生态融合

RISC-V 的开放指令集和可定制扩展特性与 eFPGA 天然契合。当前已有多项工作将 eFPGA 用于 RISC-V 自定义指令扩展（22nm RISC-V SoC、SLMLET、Flex Logix+CEVA）。未来方向包括：

- RISC-V 自定义指令接口的标准化（如 eXtension 接口、RoCC 接口的 eFPGA 适配）
- 自动识别代码热点并生成 eFPGA 自定义指令的编译器
- 多 RISC-V 核 + eFPGA 的异构众核架构（CIFER、DECADES 已验证）
- RISC-V 向量扩展（V 扩展）与 eFPGA 的融合

### 10.4 缓存一致的细粒度加速

Duet（HPCA 2023）提出的缓存一致 eFPGA 范式代表了 CPU 加速的前沿。未来研究需要解决：

- eFPGA 作为一致性节点的内存序和一致性协议优化
- 细粒度加速的编程模型（类似 OpenMP 的 pragma 驱动）
- eFPGA 与 CPU 的自动任务划分和调度
- 多 eFPGA 节点的分布式一致性

### 10.5 硬件安全与可信计算

eFPGA 重写已成为硬件 IP 保护的重要方向，但 FuncTeller（USENIX Security 2023）等工作揭示了其安全局限性。未来研究包括：

- 抗 SAT 攻击、抗侧信道的 eFPGA 重写算法
- eFPGA 比特流加密与认证
- 运行时动态安全策略（通过 eFPGA 重配置更新防火墙、入侵检测）
- 后量子密码学的 eFPGA 加速（EPI/Menta 已开始探索）
- DNN 加速器的 eFPGA 重写保护（REDACTOR 2025）

### 10.6 软 eFPGA 的性能逼近

软 eFPGA 的性能与硬 eFPGA 仍有显著差距。未来研究方向包括：

- 自顶向下物理设计方法学的进一步优化（FPGA 2021 工作是起点）
- 专用战术标准单元库的开发（Soft++ 的思路延续）
- 机器学习辅助的 eFPGA 架构探索和布局布线
- 先进工艺（5nm/3nm）下软 eFPGA 的特性评估

### 10.7 虚拟化与云原生 eFPGA

在云计算和数据中心场景中，eFPGA 需要支持多租户虚拟化。未来研究包括：

- eFPGA 的时间分片和空间分区机制
- 类似 FPGA 虚拟化（AmorphOS、ViTAL）的 eFPGA 适配
- eFPGA 比特流的快速加载和上下文切换
- 云原生 eFPGA 服务的编排和调度

### 10.8 近存与存内计算中的 eFPGA

eFPGA 可与新型存储器（ReRAM、MRAM、FeFET）结合，实现近存计算或存内计算。eFPGA 的配置存储器也可采用非易失性存储器，实现零功耗保持和瞬时启动。这一方向与 AI 加速和低功耗 IoT 高度相关。

## 十一、详细论文文献列表

### 11.1 架构与方法学类

#### 论文 1：Architectures and Algorithms for Synthesizable Embedded Programmable Logic Cores

- **年份/会议：** 2003，FPGA（ACM/SIGDA International Symposium on Field-Programmable Gate Arrays）
- **作者：** Alireza Akenova, Guy G.F. Lemieux, Steve J.E. Wilton（University of British Columbia）
- **摘要：** 提出一种将可编程逻辑核以"软"描述（VHDL/Verilog RTL）形式集成到 SoC 的替代方法。与传统"硬"版图不同，软 PLC 可与芯片其余部分一起综合，降低集成难度和设计时间。论文描述了软 PLC 的架构、综合算法和实验结果。
- **亮点：** 首次系统提出软 eFPGA 方法学，证明用标准单元综合实现可编程逻辑核的可行性，开创了 eFPGA 软 IP 研究方向。
- **引用数：** 约 150+（Google Scholar）
- **源码：** 无公开源码
- **全文：** http://www.ece.ubc.ca/~stevew/papers/pdf/fpga2003.pdf

#### 论文 2：Design Considerations for Soft Embedded Programmable Logic Cores

- **年份/会议：** 2005，IEEE Journal of Solid-State Circuits (JSSC)
- **作者：** Steve J.E. Wilton 等（University of British Columbia）
- **摘要：** 分析软可编程逻辑核（Soft PLC）的优势与局限性。软 PLC 以 RTL 描述，可集成到 ASIC 设计流程中，但由于使用通用标准单元，在面积、功耗和延迟上有显著开销。论文探讨了架构选择对这些开销的影响。
- **亮点：** JSSC 期刊论文，系统分析软 eFPGA 的设计权衡，是该领域的奠基性期刊文献。
- **引用数：** 约 100+
- **源码：** 无
- **全文：** http://www.ece.ubc.ca/~stevew/papers/pdf/jssc05.pdf

#### 论文 3：An Improved "Soft" eFPGA Design and Implementation Strategy

- **年份/会议：** 2005，IEEE Custom Integrated Circuits Conference (CICC)
- **作者：** Alireza Akenova, Guy G.F. Lemieux（UBC）
- **摘要：** 针对原始软 eFPGA 方法学的面积和延迟开销，提出使用架构专用的战术标准单元（tactical standard cells）来降低开销。实验表明，面积和延迟开销分别降低 58% 和 40%。同时通过结构化设计方法显著提升逻辑容量和质量。
- **亮点：** Soft++ 方法学的前身，首次证明专用标准单元可大幅降低软 eFPGA 开销。
- **引用数：** 约 80+
- **源码：** 无
- **全文：** https://people.ece.ubc.ca/lemieux/publications/akenova-cicc2005.pdf

#### 论文 4：Soft++: An Improved Embedded FPGA Methodology for SoC Designs

- **年份/会议：** 2007，IEEE Transactions on Very Large Scale Integration (TVLSI) Systems
- **作者：** Alireza Akenova, Guy G.F. Lemieux（UBC）
- **摘要：** 提出 Soft++ eFPGA 方法学，通过三种技术降低软 eFPGA 开销：（1）结构化布局，（2）瓦片化架构，（3）架构专用战术标准单元。实验表明平均面积改善 2.4 倍，延迟改善 1.6 倍，容量比原始 Soft 方法大一个数量级，与定制 eFPGA 的面积差距缩小到 3 倍以内。
- **亮点：** 软 eFPGA 方法学的集大成之作，TVLSI 期刊长文，系统验证了结构化布局+专用标准单元的有效性。
- **引用数：** 约 120+
- **源码：** 无
- **全文：** https://people.ece.ubc.ca/lemieux/publications/akenova-tvlsi2007.pdf

#### 论文 5：A Synthesizable Datapath-Oriented Embedded FPGA Fabric

- **年份/会议：** 2007，FPGA
- **作者：** Steven J.E. Wilton 等
- **摘要：** 提出一种面向数据通路的可综合 eFPGA 架构，优化信号处理和计算密集型应用中常见的总线操作。采用方向性布线架构，可使用标准 ASIC 工具综合。论文描述了概念验证版图。
- **亮点：** 面向数据通路的 eFPGA 架构，区别于通用 LUT 阵列，针对算术密集型应用优化。
- **引用数：** 约 60+
- **源码：** 无
- **全文：** https://dl.acm.org/doi/pdf/10.1145/1216919.1216924

#### 论文 6：Quantitative Analysis of Embedded FPGA-Architectures for Arithmetic

- **年份/会议：** 2006，IEEE International Conference on Application-specific Systems, Architectures and Processors (ASAP)
- **作者：** H. Schmit 等
- **摘要：** 对面向算术应用的 eFPGA 架构进行定量分析，比较不同 LUT 大小、互连结构和硬算术块配置的面积-性能权衡。
- **亮点：** 早期 eFPGA 算术架构的定量比较研究。
- **引用数：** 约 40+
- **源码：** 无
- **全文：** Internet Archive Scholar 可获取 PDF

#### 论文 7：Design Flow for Embedded FPGAs Based on a Flexible Architecture Template

- **年份/会议：** 2008，Design, Automation and Test in Europe (DATE)
- **作者：** B. Neumann 等
- **摘要：** 提出基于灵活架构模板的 eFPGA 设计流程，允许设计者根据应用需求定制 eFPGA 架构参数（LUT 大小、互连拓扑、硬块比例），并自动生成相应的综合和布局布线工具。
- **亮点：** 早期 eFPGA 架构模板化设计流程，为后续 OpenFPGA 等自动化框架提供了思路。
- **引用数：** 约 50+
- **源码：** 无

#### 论文 8：Soft-Core Embedded-FPGA Based on Multistage Switching Networks: A Quantitative Analysis

- **年份/会议：** 2015，IEEE International Symposium on Circuits and Systems (ISCAS) / IEEE Transactions
- **作者：** M. Lanuzza, S. Perri, P. Corsonello 等（STMicroelectronics / University of Calabria）
- **摘要：** 提出基于 LUT 的软核 eFPGA，采用多级交换网络（MSSN）实现可编程互连，确保可综合且无拥塞。在 STMicroelectronics CMOS 65nm 和 BCD9s 工艺上进行定量评估，展示了广泛的设计空间。
- **亮点：** MSSN 互连架构解决了软 eFPGA 布线拥塞问题，是软 eFPGA 互连设计的重要进展。
- **引用数：** 约 30+
- **源码：** 无
- **全文：** https://xplorestaging.ieee.org/document/7066971

#### 论文 9：Synthesizable Standard Cell FPGA Fabrics Targetable by the Verilog-to-Routing CAD Flow

- **年份/会议：** 2017，FPGA
- **作者：** J. Goeders, S. Wilton 等（University of British Columbia / University of Toronto）
- **摘要：** 展示可被 VTR（Verilog-to-Routing）开源 CAD 流程支持的标准单元 FPGA 阵列。通过定义架构描述文件，使 VPR 布局布线器能够针对可综合的标准单元 FPGA 架构进行优化。
- **亮点：** 将开源 VTR 流程与软 eFPGA 结合，为开源 eFPGA 工具链奠定基础。
- **引用数：** 约 50+
- **源码：** 基于 VTR 开源流程

#### 论文 10：Top-down Physical Design of Soft Embedded FPGA Fabrics

- **年份/会议：** 2021，FPGA（ACM）
- **作者：** Colin Yu Lin, Ngai Wong, 等
- **摘要：** 提出自顶向下的软 eFPGA 物理设计方法学，无需手动缓冲或布局规划。在 28nm 工业 CMOS 工艺上验证，通过层次化的综合和布局布线策略，显著提升软 eFPGA 的面积效率和时序质量。
- **亮点：** 解决软 eFPGA 物理设计的自动化问题，使软 eFPGA 能更高效地利用先进工艺。
- **引用数：** 约 20+
- **源码：** 无
- **全文：** https://dl.acm.org/doi/pdf/10.1145/3431920.3439297

---

### 11.2 开源框架类

#### 论文 11：OpenFPGA: An Open-Source Framework for Agile Prototyping Customizable FPGAs

- **年份/会议：** 2020，IEEE Micro
- **作者：** Xifan Tang, Edouard Giacomin, Aurélien Alacchi, Baudouin Chauviere, Pierre-Emmanuel Gaillardon（University of Utah / Columbia University）
- **摘要：** OpenFPGA 是一个开源框架，支持从架构描述到 GDSII 的完整 FPGA 原型设计流程。它自动化生成可定制 FPGA 架构的 Verilog RTL，支持异构逻辑块、BRAM、DSP 和自定义 I/O，并集成 VPR 布局布线器。OpenFPGA 显著降低了定制 FPGA 和 eFPGA 的设计门槛。
- **亮点：** 最广泛使用的开源 FPGA/eFPGA 生成框架，支持完整的 RTL-to-GDSII 流程，已被大量学术研究采用（包括 eFPGA 重写、神经形态计算等）。
- **引用数：** 约 200+（Google Scholar）
- **源码：** https://github.com/lnis-uofu/OpenFPGA
- **全文：** https://xplorestaging.ieee.org/document/9098028

#### 论文 12：PRGA: An Open-Source FPGA Research and Prototyping Framework

- **年份/会议：** 2021，FPGA
- **作者：** Ang Li, David Wentzlaff（Princeton University）
- **摘要：** PRGA 是一个高度可定制、可扩展的开源 FPGA 研究和原型设计框架。它提供 Python API 用于架构描述，生成可综合 Verilog，并包含完整的 CAD 工具链（综合、技术映射、布局布线、比特流生成）。PRGA 明确支持 eFPGA 场景，可与 OpenPiton 开源众核处理器集成。
- **亮点：** 唯一明确以 eFPGA 和 CPU 集成为核心目标的开源框架，已用于 Duet（HPCA 2023）、CIFER（12nm）、DECADES（12nm）等硅验证芯片。Python API 设计使其扩展性极强。
- **引用数：** 约 80+
- **源码：** https://github.com/PrincetonUniversity/prga
- **全文：** https://dl.acm.org/doi/pdf/10.1145/3431920.3439294 ；OSDA 2019 版：https://angl-dev.github.io/assets/pdfs/osda19.pdf

#### 论文 13：FABulous: An Embedded FPGA Framework

- **年份/会议：** 2021，FPGA
- **作者：** Nguyen Cong Dao, Dirk Koch, 等（University of Manchester）
- **摘要：** FABulous 是一个面向嵌入式场景的开源 eFPGA 框架。采用 CSV 配置文件定义架构，支持异构瓦片（逻辑、算术、存储器、自定义块）和动态部分重配置。已在 TSMC 180nm 和开源 SkyWater 45nm 工艺上流片验证。
- **亮点：** 流片验证最多的开源 eFPGA 框架（180nm/45nm/130nm/28nm），原生支持动态部分重配置，CSV 配置简单易用。
- **引用数：** 约 60+
- **源码：** https://github.com/FPGA-Research-Manchester/FABulous
- **全文：** https://dl.acm.org/doi/epdf/10.1145/3431920.3439302
- **文档：** https://fabulous.readthedocs.io

#### 论文 14：How to Shrink My FPGAs — Optimizing Tile Interfaces and the Configuration Logic in FABulous FPGA Fabrics

- **年份/会议：** 2022，FPGA
- **作者：** Dirk Koch 等（University of Manchester）
- **摘要：** 优化 FABulous eFPGA 框架的瓦片接口和配置逻辑，对比 frame-based 和 shift-register 两种配置模式的面积和延迟开销，提出优化策略以减小 eFPGA 面积。
- **亮点：** FABulous 的后续优化工作，深入分析配置逻辑对 eFPGA 面积的影响。
- **引用数：** 约 15+
- **源码：** 同 FABulous

#### 论文 15：The FABulous Open Source eFPGA Framework

- **年份/会议：** 2022，IEEE 特邀论文 / 综述
- **作者：** Dirk Koch（University of Manchester / FAU）
- **摘要：** 综述 FABulous 开源 eFPGA 框架的能力、架构设计、工具链和流片结果，讨论 eFPGA 在 IoT、AI、安全等领域的应用前景。
- **亮点：** FABulous 框架的系统性综述。
- **引用数：** 约 10+
- **全文：** https://www.invasic.cs.fau.de/publications/DirkKoch2022.pdf

---

### 11.3 CPU 加速与 SoC 集成类（重点）

#### 论文 16：Stretch S5000/S6000 Software Configurable Processor

- **年份/会议：** 2004–2009，工业界产品（非学术论文，BDTI 2004 报道）
- **作者/机构：** Stretch Inc.（基于 Tensilica Xtensa RISC 核）
- **摘要：** Stretch S5000/S6000 是最早商业化的 eFPGA+CPU 处理器。将 Tensilica Xtensa RISC 核与 ISEF（Instruction Set Extension Fabric）可重构计算阵列紧耦合，允许在运行时通过软件定义自定义指令。S6000 增加了运动估计、熵编码、加密等固定功能加速器。C/C++ 编译器可自动识别代码热点并将其"压缩"为单条自定义指令。
- **亮点：** eFPGA 用于 CPU 加速的先驱产品，首次实现运行时软件定义自定义指令。ISEF 分为两个区域，支持一个重配置另一个执行。主要面向视频编码和无线信号处理。
- **引用数：** 工业产品，无学术引用统计
- **源码：** 无（商业产品）
- **资料：** https://www.bdti.com/InsideDSP/2004/05/11/Stretch

#### 论文 17：Duet: Creating Harmony between Processors and Embedded FPGAs

- **年份/会议：** 2023，HPCA（IEEE International Symposium on High-Performance Computer Architecture）
- **作者：** Ang Li, August Ning, David Wentzlaff（Princeton University）
- **摘要：** 提出可扩展的众核-FPGA 架构 Duet，通过非侵入式的双向缓存一致性集成将 eFPGA 提升为与处理器对等的节点。Duet 支持两种加速范式：硬件增强（将大算法映射到多个小加速器，利用处理器处理动态控制流）和细粒度加速（利用 eFPGA 加速广泛领域中的细粒度加速机会）。基于 OpenPiton + PRGA 实现 RTL 级原型。
- **亮点：** HPCA 顶会论文，首次将 eFPGA 作为缓存一致的对等计算节点。Duet Adapter 非侵入式设计，无需修改 CPU 核。支持细粒度加速，突破了传统 FPGA 加速仅适用于完整稳定算法的限制。开源实现。
- **引用数：** 约 30+（2023 年发表，增长中）
- **源码：** https://github.com/PrincetonUniversity/duet（Duet-Dolly, OpenPiton x PRGA）
- **全文：** https://arxiv.org/pdf/2301.02785.pdf
- **DOI：** 10.1109/HPCA56546.2023.10070989

#### 论文 18：Arnold: An eFPGA-Augmented RISC-V SoC for Flexible and Low-Power IoT End-Nodes

- **年份/会议：** 2021，IEEE Journal of Solid-State Circuits (JSSC)
- **作者：** Pasquale Davide Schiavone, 等（University of Bologna / ETH Zurich）
- **摘要：** 在 GF22FDX 22nm 工艺上实现了 RISC-V MCU + eFPGA 的低功耗 IoT 节点 SoC。eFPGA 紧耦合到 MCU 的扩展接口，工作电压 0.5–0.8V，功耗 46.83 μW/MHz，算力 600 MOPS。架构灵活性允许完全利用可配置逻辑，支持智能传感器和可穿戴设备。
- **亮点：** JSSC 期刊论文，低功耗 IoT eFPGA 的代表性硅验证工作。近阈值电压（0.5V）下仍能工作，展示了 eFPGA 在电池供电设备中的可行性。
- **引用数：** 约 80+
- **源码：** 基于 PULP 平台开源
- **全文：** https://arxiv.org/pdf/2006.14256v1.pdf

#### 论文 19：CIFER: A 12nm, 16mm², 22-Core SoC with a 1541 LUT6/mm², 1.92 MOPS/LUT, Fully Synthesizable, Cache Coherent, Embedded FPGA

- **年份/会议：** 2023，CICC（IEEE Custom Integrated Circuits Conference，Best Student Paper Nominee）+ 2023 JSSC
- **作者：** Ting-Jung Chang, August Ning, 等（Cornell University / Princeton University）
- **摘要：** 全球首个开源、全缓存一致、异构多核 CPU-eFPGA SoC。12nm 工艺、16 mm² 芯片集成 4 个 64 位 RISC-V 应用核（Ariane，可运行 Linux）、3 个 TinyCore 集群（共 18 个 32 位 RISC-V 计算核）和 EDA 综合的标准单元 eFPGA（PRGA 生成）。eFPGA 密度 1541 LUT6/mm²，性能 1.92 MOPS/LUT。基于 OpenPiton+BYOC+PyMTL+PyOCN 开源工具链，疫情期间 7 个月完成设计。
- **亮点：** CICC 最佳学生论文提名。全球首个开源缓存一致 CPU-eFPGA SoC 的硅验证。证明了软 eFPGA 在 12nm 先进工艺下的可行性和密度。完整开源工具链展示了敏捷芯片开发的潜力。
- **引用数：** 约 25+
- **源码：** 基于 OpenPiton + PRGA 开源
- **全文：** https://www.csl.cornell.edu/~cbatten/pdfs/chang-cifer-cicc2023.pdf

#### 论文 20：DECADES: A 67mm², 1.46 TOPS, 55 Giga Cache-Coherent 64-bit RISC-V Instructions per second, Heterogeneous Manycore SoC with 109 Tiles including Accelerators, Intelligent Storage, and eFPGA in 12nm

- **年份/会议：** 2023，CICC
- **作者：** Y. Gao, 等（Columbia University）
- **摘要：** 12nm 工艺、67 mm² 异构众核 SoC，包含 109 个瓦片。eFPGA 部分由 PRGA 生成 RTL，再通过标准数字 EDA 工具综合到标准单元，包含 7040 个多功能 6 输入 LUT、32 个 40 位硬乘法器、32 个 16Kb 双口块 RAM。配合 64 位 RISC-V 核实现 55 Giga 缓存一致指令/秒吞吐量和 1.46 TOPS 算力。eFPGA 允许用户在流片后生成"软"加速器。
- **亮点：** 最大规模的开源 eFPGA 硅验证（7040 LUT）。eFPGA 作为"软加速器"与硬加速器、智能存储异构集成。证明 PRGA 生成的软 eFPGA 可扩展到大规模阵列。
- **引用数：** 约 20+
- **源码：** 基于 PRGA + DECADES 开源平台
- **全文：** https://sld.cs.columbia.edu/pubs/gao_cicc23.pdf

#### 论文 21：SMIV: A 16nm 25mm² SoC with a 54.5x Flexibility-Efficiency Range from Dual-Core Arm Cortex-A53 to eFPGA and Cache-Coherent Accelerators

- **年份/会议：** 2018，ISSCC（IEEE International Solid-State Circuits Conference）+ 2022 JSSC
- **作者：** Paul N. Whatmough, 等（IBM Research / Harvard University / Tufts University）
- **摘要：** 16nm 工艺、25 mm² SoC，集成双核 ARM Cortex-A53、Flex Logix eFPGA（2×2 阵列，2 逻辑瓦片 + 2 DSP 瓦片，约 5K 6-LUT）和四核缓存一致性加速器（CCA）。eFPGA 通过 ACP 接入缓存一致性互连。功耗范围 1.1 mW–1.36 W。eFPGA 实现比软件能效提升 28.9 倍、吞吐量提升 120 倍。整个 SoC 灵活性-效率范围达 54.5 倍。
- **亮点：** ISSCC 顶会论文，首个缓存一致 ARM CPU + 商业 eFPGA 的硅验证。Flex Logix eFPGA 通过 ACP 接口实现缓存一致。量化了 eFPGA 在能效和吞吐量上的收益（28.9x / 120x）。
- **引用数：** 约 150+（ISSCC 论文，高引用）
- **源码：** 无（IBM 工业研究）
- **全文：** https://www.eecs.tufts.edu/~mdonato/assets/papers/smiv.pdf
- **HotChips Slides：** https://vlsiarch.eecs.harvard.edu/sites/g/files/omnuum11281/files/vlsiarch/files/whatmough_harvard_hotchips_2018_0.7_clean.pdf

#### 论文 22：A 748 GOPS/W RISC-V SoC with Reconfigurable Custom Instructions via a Synthesized eFPGA with 1.8µs Configuration Time in 22nm FinFET

- **年份/会议：** 2023，ISSCC
- **作者：** Mohan, Das, 等
- **摘要：** 22nm FinFET 工艺上的 RISC-V SoC，将可综合 eFPGA 紧耦合到 CPU 数据通路和便签式存储器（SPM）。实现 1.8 μs 超快速配置时间，16 GB/s 并行高带宽访问 SPM，748 GOPS/W 能效。支持可重构自定义指令，eFPGA 直接接入 CPU 执行流水线。
- **亮点：** ISSCC 顶会论文，紧耦合 eFPGA 自定义指令的最新进展。1.8 μs 配置时间是目前已发表的最快 eFPGA 配置之一。748 GOPS/W 能效极高。紧耦合 SPM 提供 16 GB/s 带宽。
- **引用数：** 约 15+（2023 年发表）
- **源码：** 无
- **全文：** https://xplorestaging.ieee.org/document/10983466

#### 论文 23：A RISC-V SoC With Reconfigurable Custom Instructions on a Synthesized eFPGA Fabric in 22nm FinFET

- **年份/会议：** 2025，IEEE Journal of Solid-State Circuits (JSSC)（ISSCC 2023 的扩展期刊版）
- **作者：** Mohan, Das, 等
- **摘要：** ISSCC 2023 工作的扩展期刊版，详细描述 22nm FinFET RISC-V SoC 的架构、eFPGA 紧耦合接口、配置机制、工具链和测量结果。包含更详细的能效分析和自定义指令案例研究。
- **亮点：** JSSC 期刊长文，紧耦合 eFPGA 自定义指令的最完整技术描述。
- **引用数：** 约 5+（2025 年发表）
- **全文：** https://xplorestaging.ieee.org/document/11195177

#### 论文 24：SLMLET: A RISC-V Processor SoC with Tightly-Coupled Area-Efficient eFPGA Blocks

- **年份/会议：** 2024，COOL（IEEE International Symposium on Cool Chips）
- **作者：** Takuya Kojima（Tokyo Institute of Technology / Waseda University）
- **摘要：** 提出基于查找表式存储器（SLM, Search-Look-aside Memory）的面积高效 eFPGA 块，紧耦合到 RISC-V 处理器。SLM 逻辑块尺寸仅 106.80 μm 见方，每个瓦片包含 4 个 5 输入 SLM 逻辑单元。28nm 工艺芯片面积 4.2 mm × 4.2 mm。SLM 利用存储器编译器生成的高密度 SRAM 实现 LUT 功能，显著降低面积。
- **亮点：** 创新使用 SLM（存储器编译器生成的 SRAM）实现 LUT，大幅提升 eFPGA 面积效率。紧耦合 RISC-V 处理器，支持可重构自定义指令。
- **引用数：** 约 5+（2024 年发表）
- **源码：** 无
- **全文：** https://www.tkojima.me/papers/2024/cool_2024_kojima.pdf

#### 论文 25：Mixed-Precision Neural Networks on RISC-V CPU with Reconfigurable SIMD Instruction Extension via eFPGA

- **年份/会议：** 2026，预印本 / 期刊投稿
- **作者：** Yang, Li, 等
- **摘要：** 将 eFPGA 用于 RISC-V CPU 的可重构 SIMD 指令扩展，支持混合精度神经网络推理。设计了可配置精度的数据通路和创新的 SIMD 指令，通过 eFPGA 实现向量数据映射策略的优化。eFPGA 可动态重配置以支持不同精度（INT8/INT4/FP16）的神经网络层。
- **亮点：** 2026 年最新工作，eFPGA 用于可重构 SIMD 向量扩展的前沿探索。将 eFPGA 加速从标量自定义指令扩展到向量 SIMD 级别。面向 AI 推理的混合精度支持。
- **引用数：** 暂无（2026 年）
- **资料：** https://www.semanticscholar.org/paper/8d90493c44a1c3657f9867f2fa97918f92285530

#### 论文 26：An Open-Source eFPGA-based SoC Design for Computation Acceleration

- **年份/会议：** 2024，IEEE 国际会议
- **作者：** 多位作者
- **摘要：** 基于开源 eFPGA 构建计算加速 SoC。eFPGA 为均匀岛式风格，包含 1960 个 LUT 和 448 个 I/O，CLB 含 10 个 6-LUT，开关盒为 Wilton 风格（连接度参数 3），采用扫描链配置协议。系统通过 Wishbone B4 总线协议通信，eFPGA 作为可重构加速器连接到 CPU 总线。
- **亮点：** 完全开源的 eFPGA SoC 设计，Wishbone 总线接口，适合学术研究和教学。Wilton 风格开关盒 + 扫描链配置是经典 eFPGA 架构。
- **引用数：** 约 5+
- **全文：** https://xplorestaging.ieee.org/document/10382739

#### 论文 27：Towards Reconfigurable Accelerators in HPC: Designing a Multipurpose eFPGA Tile for Heterogeneous SoCs

- **年份/会议：** 2022，FPGA
- **作者：** 欧洲处理器计划（EPI）团队，Menta 提供 eFPGA IP
- **摘要：** 设计面向异构 SoC 的多用途 eFPGA 瓦片，用于 HPC 场景。集成 Picos（依赖检测算法的快速硬件实现），可替代传统软件运行时，显著降低运行时开销，透明加速细粒度并行应用。eFPGA 瓦片通过明确定义的互连与处理器集群和专用硬件加速器连接。
- **亮点：** eFPGA 在 HPC 场景的代表性工作。Picos 硬件依赖检测降低运行时开销。与欧洲处理器计划（EPI）关联，面向实际 HPC 芯片。
- **引用数：** 约 20+
- **全文：** https://dl.acm.org/doi/pdf/10.5555/3539845.3540000

#### 论文 28：Flex Logix + CEVA SOC2: DSP with Embedded FPGA for Flexible/Changeable ISA

- **年份/会议：** 2022，工业界硅验证（Semiconductor Digest 报道）
- **作者/机构：** Bar-Ilan University SoC Lab，CEVA，Flex Logix
- **摘要：** TSMC 16nm 工艺上流片 SOC2，将 CEVA-X2 DSP 与 Flex Logix EFLX eFPGA 集成，实现可灵活变更的 DSP 指令集架构（ISA）。允许根据不同工作负载动态添加自定义硬连线指令，eFPGA 紧耦合到 DSP 执行流水线。
- **亮点：** 工业界 eFPGA+DSP 紧耦合的硅验证。证明商业 eFPGA IP 可与 DSP 核紧耦合实现可变更 ISA。
- **引用数：** 工业产品
- **资料：** https://www.semiconductor-digest.com/flex-logix-and-ceva-announce-first-working-silicon-of-a-dsp-with-embedded-fpga-to-allow-a-flexible-changeable-isa/

#### 论文 29：EPI (European Processor Initiative) eFPGA Core

- **年份/会议：** 2019–2024，欧洲处理器计划（EPI）技术报告 / 2026 年完成
- **作者/机构：** Menta（eFPGA IP 提供方），EPI 联盟
- **摘要：** Menta 为 EPI 通用处理器芯片（GPP）提供 eFPGA IP，第五代架构。通过 Origami Designer 软件定制 eFPGA 架构，面向 HPC 和汽车控制单元应用。eFPGA 支持后生产客户定制和运行时可重构加密。特定工作负载达 18 倍加速。后量子密码（PQRC）eFPGA 在 GF22FDX+ 实现。
- **亮点：** 欧洲旗舰处理器计划中的 eFPGA 集成。Menta 软 IP 路线，工艺无关。面向 HPC 和后量子密码学。2026 年完成，最新进展。
- **引用数：** 工业项目
- **资料：** https://www.european-processor-initiative.eu/wp-content/uploads/2019/12/EPI-Technology-eFPGA.pdf

---

### 11.4 硬件安全类（eFPGA Redaction）

#### 论文 30：Exploring eFPGA-based Redaction for IP Protection

- **年份/会议：** 2021，ICCAD（IEEE/ACM International Conference on Computer-Aided Design）
- **作者：** A. S. 等（Politecnico di Milano）
- **摘要：** 首次系统探索 eFPGA 重写（redaction）用于硬件 IP 保护。将设计中的关键模块替换为 eFPGA，流片时功能未定义，只有授权用户加载正确比特流才能恢复功能。基于开源 FPGA 生成流程（OpenFPGA）进行实验，分析面积和时序开销。
- **亮点：** eFPGA 重写方向的开创性论文，ICCAD 顶会。首次将 eFPGA 与硬件 IP 保护系统结合。
- **引用数：** 约 40+
- **全文：** https://re.public.polimi.it/retrieve/handle/11311/1200375/698916/ICCAD_openfpga_assure.pdf

#### 论文 31：Not All Fabrics Are Created Equal: Exploring eFPGA Parameters For IP Redaction

- **年份/会议：** 2021，IEEE Transactions / 预印本
- **作者：** 多位作者
- **摘要：** 研究不同 eFPGA 架构参数（LUT 大小、互连拓扑、配置存储器类型）对 IP 重写安全性的影响。指出并非所有 eFPGA 都能提供足够的安全保证，需要根据威胁模型选择合适的架构参数。
- **亮点：** 首次系统分析 eFPGA 架构参数与重写安全性的关系。
- **引用数：** 约 20+
- **资料：** https://www.researchgate.net/publication/356027136

#### 论文 32：Evaluating the Security of eFPGA-based Redaction Algorithms

- **年份/会议：** 2023，IEEE 国际会议
- **作者：** Amin Rezaei 等
- **摘要：** 评估 eFPGA 重写算法对 SAT 攻击和暴力攻击的抵抗能力。分析不同重写策略（模块选择、eFPGA 大小、配置位数）下的攻击复杂度，提出增强安全性的设计建议。
- **亮点：** 首次对 eFPGA 重写进行正式的安全评估，量化抗攻击能力。
- **引用数：** 约 10+
- **全文：** https://xplorestaging.ieee.org/document/10069713

#### 论文 33：FuncTeller: How Well Does eFPGA Hide Functionality?

- **年份/会议：** 2023，USENIX Security Symposium
- **作者：** Han Zhaokun 等
- **摘要：** 揭示 eFPGA 并非天然安全。攻击者可通过查询 eFPGA 的输入输出行为，结合结构分析和机器学习推断隐藏功能。论文提出 FuncTeller 攻击框架，证明即使配置位未知，eFPGA 的功能也可被部分恢复。
- **亮点：** USENIX Security 顶会论文，首次揭示 eFPGA 重写的安全漏洞。打破了"eFPGA 配置未知即安全"的假设。对 eFPGA 安全研究有重要警示意义。
- **引用数：** 约 30+
- **全文：** https://www.usenix.org/system/files/usenixsecurity23-han-zhaokun.pdf

#### 论文 34：Predictive Model Attack for Embedded FPGA Logic Locking

- **年份/会议：** 2022，ACM CCS（Conference on Computer and Communications Security）
- **作者：** 多位作者
- **摘要：** 提出基于预测模型的攻击方法，可破解 eFPGA 逻辑锁定。利用机器学习模型预测 eFPGA 中 LUT 的功能，结合结构分析恢复原始设计。攻击成功率显著高于传统 SAT 攻击。
- **亮点：** CCS 顶会论文，首次将机器学习用于 eFPGA 逻辑锁定攻击。
- **引用数：** 约 15+
- **全文：** https://dl.acm.org/doi/fullHtml/10.1145/3531437.3539728

#### 论文 35：ARIANNA: An Automatic Design Flow for Fabric Customization and eFPGA Redaction

- **年份/会议：** 2025，arXiv 预印本
- **作者：** 多位作者
- **摘要：** 提出自动化的 eFPGA 重写设计流程 ARIANNA，包括：自动识别需要重写的模块、优化 eFPGA fabric 架构、生成完整芯片设计。采用渐进式求精策略，支持异构 fabric（不同区域使用不同 LUT 大小和互连）。
- **亮点：** 首个端到端的 eFPGA 重写自动化设计流程。支持异构 fabric 优化。2025 年最新进展。
- **引用数：** 暂无（2025 年）
- **全文：** https://arxiv.org/html/2506.00857v1

#### 论文 36：REDACTOR: eFPGA Redaction for DNN Accelerator Security

- **年份/会议：** 2025，arXiv 预印本
- **作者：** 多位作者
- **摘要：** 将 eFPGA 重写扩展到 DNN 加速器安全领域。研究 DNN 加速器中关键模块（如控制逻辑、数据通路配置）的选择策略，使用常规和可分裂 LUT（splittable LUT）实现重写。分析重写对加速器性能、面积和安全性的影响。
- **亮点：** 首次将 eFPGA 重写应用于 DNN 加速器保护。可分裂 LUT 技术提升重写灵活性。AI 硬件安全方向的前沿工作。
- **引用数：** 暂无（2025 年）
- **全文：** https://arxiv.org/html/2501.18740v1

#### 论文 37：Physical-Aware eFPGA Redaction for Secure and Efficient Hardware IP Protection

- **年份/会议：** 2026，期刊投稿
- **作者：** He 等
- **摘要：** 提出物理感知的 eFPGA 重写方法，利用完整综合和布局布线后的精确时序、空间和连接信息做出更优的分区决策。与传统的门级重写相比，物理感知方法可显著降低面积和时序开销，同时保持安全性。
- **亮点：** 2026 年最新工作，首次将物理设计信息引入 eFPGA 重写决策。提升重写的 PPA 效率。
- **引用数：** 暂无（2026 年）
- **全文：** https://youl.me/paper/he2026physical.pdf

#### 论文 38：Dynamic Security Management of Systems on Chip via Embedded FPGA in 22nm CMOS Technology

- **年份/会议：** 2024，MWSCAS（IEEE Midwest Symposium on Circuits and Systems）
- **作者：** 多位作者
- **摘要：** 在 22nm CMOS 工艺上验证通过 eFPGA 进行 SoC 动态安全管理。eFPGA 可在运行时重配置以更新安全策略、入侵检测逻辑和加密算法，提供硬件级的动态安全防护。
- **亮点：** eFPGA 用于运行时动态安全管理的硅验证。22nm 工艺实现。
- **引用数：** 约 5+
- **全文：** https://xplorestaging.ieee.org/document/10658859

---

### 11.5 应用与其他类

#### 论文 39：Embedded FPGA Developments in 130nm and 28nm CMOS for Machine Learning in Particle Detector Readout

- **年份/会议：** 2024，arXiv 预印本 / IEEE Transactions
- **作者：** 多位作者（基于 FABulous 框架）
- **摘要：** 使用 FABulous 开源 eFPGA 框架在 130nm 和 28nm 两种工艺上实现 eFPGA，用于下一代对撞机实验粒子探测器读出中的机器学习推理。eFPGA 可在前端 ASIC 中动态重配置 ML 模型架构（不仅更新权重），填补了专用 ASIC（刚性）和独立 FPGA（高功耗）之间的技术空白。
- **亮点：** eFPGA 在高能物理领域的创新应用。双工艺流片验证（130nm/28nm）。可重配置 ML 架构而非仅更新权重。
- **引用数：** 约 10+
- **全文：** https://arxiv.org/html/2404.17701v3

#### 论文 40：A Survey and Comparative Study of Embedded FPGA Architectures

- **年份/会议：** 2020，International Journal of Computer Science and Network Security (IJCSNS)
- **作者：** 多位作者
- **摘要：** 对 eFPGA 架构进行综述和比较研究，从细粒度到粗粒度分类比较不同 eFPGA 架构的特点、优势和局限性。涵盖商业 IP 和学术研究原型。
- **亮点：** eFPGA 架构的综述性论文，适合入门了解。
- **引用数：** 约 30+
- **全文：** http://paper.ijcsns.org/07_book/202008/20200825.pdf

#### 论文 41：A Perspective on the Topics from a Selection of Papers from the First Twenty Years of ARC

- **年份/会议：** 2025，ACM Transactions on Reconfigurable Technology and Systems (TRETS)
- **作者：** 多位作者
- **摘要：** 回顾可重构计算会议（ARC）20 年来的代表性论文，包括 eFPGA、可重构加速器、CGRA 等方向的发展脉络，展望未来研究方向。
- **亮点：** 可重构计算 20 年回顾，包含 eFPGA 发展的历史视角。
- **引用数：** 暂无（2025 年）
- **全文：** https://dl.acm.org/doi/10.1145/3829368

#### 论文 42：XFLX: Boundless Radix Interconnect for Embedded FPGA（ISSCC 2014 Outstanding Paper）

- **年份/会议：** 2014，ISSCC（Outstanding Paper Award）
- **作者：** Cheng Wang, 等（Flex Logix 联合创始人）
- **摘要：** 提出 XFLX（Boundless Radix Interconnect）互连架构，用于 eFPGA。传统 FPGA 互连占约 80% 面积，XFLX 通过创新的分级 radix 互连结构将互连面积减少约 45%，仅使用 5–7 层金属，利用率 >90%，使 eFPGA 能兼容大多数 ASIC 金属堆叠。
- **亮点：** ISSCC 杰出论文奖，Flex Logix EFLX 的核心技术。eFPGA 互连架构的里程碑式工作。直接推动了 Flex Logix 成为 eFPGA IP 市场领导者。
- **引用数：** 约 100+（ISSCC 杰出论文，高影响）
- **资料：** https://eepower.com/new-industry-products/dialog-to-license-mixed-signal-embedded-field-programmable-gate-array-tech/

---

### 11.6 引用说明

引用数量说明：上述引用数为基于 Google Scholar / Semantic Scholar 的估算值（截至 2026 年 8 月）。2023 年以后发表的论文引用数较少，随时间会增长。工业产品（Stretch、Flex Logix+CEVA、EPI）无学术引用统计。建议通过 Google Scholar 或 Semantic Scholar 检索精确引用数。

全文获取：大部分论文提供了直接 PDF 链接或 IEEE Xplore / ACM DL 链接。对于付费墙论文，可通过机构订阅访问，或通过作者个人主页获取预印本。

源码获取：开源框架（OpenFPGA、PRGA、FABulous）和部分研究工作（Duet、CIFER、DECADES）提供了 GitHub 源码。商业 IP（Achronix、Flex Logix、Menta）需通过厂商授权获取。
