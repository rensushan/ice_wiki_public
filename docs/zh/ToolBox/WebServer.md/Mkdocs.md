MkDocs + Material 其实就是你现在想做的事情的**专业版**。

你现在的 Flask 方案：

```
Markdown文件
      |
    Flask
      |
    HTML
```

而 MkDocs：

```
Markdown文件
      |
    MkDocs
      |
  静态HTML网站
      |
    Caddy
      |
  浏览器
```

区别：

|         | Flask方案    | MkDocs Material |
| ------- | ---------- | --------------- |
| 运行方式    | 动态Python服务 | 生成静态网页          |
| 资源占用    | 几十MB       | 几乎0             |
| 搜索      | 自己实现       | 内置              |
| 目录导航    | 自己写        | 自动生成            |
| 代码高亮    | 需要配置       | 自带              |
| 公式LaTeX | 需要插件       | 支持              |
| 图片      | 手动处理       | 方便              |
| 适合      | 简单显示       | 个人Wiki/知识库      |

对于你的 **512MB VPS**，MkDocs 反而更合适。

---

# 一、安装 MkDocs

你已经有 Python venv，所以不要用系统 pip。

进入你的目录：

```bash
cd ~
```

创建：

```bash
mkdir my-docs
cd my-docs
```

建立虚拟环境：

```bash
python3 -m venv venv
```

进入：

```bash
source venv/bin/activate
```

安装：

```bash
pip install mkdocs mkdocs-material
```

检查：

```bash
mkdocs --version
```

应该：

```
mkdocs, version x.x.x
```

---

# 二、创建网站

执行：

```bash
mkdocs new .
```

生成：

```
my-docs/

├── mkdocs.yml
└── docs/
    └── index.md
```

---

# 三、安装 Material 主题

编辑：

```bash
nano mkdocs.yml
```

改成：

```yaml
site_name: Ice Research Notes

theme:
  name: material

nav:
  - Home: index.md
```

---

# 四、写你的Markdown

编辑：

```bash
nano docs/index.md
```

例如：

```markdown
# Ice Research Notes


欢迎来到我的研究笔记。


## AI

- [Quantization](quantization.md)

- [Xray记录](xray.md)


## Hardware

- [FPGA](fpga.md)
```

然后：

```bash
nano docs/xray.md
```

写：

````markdown
# Xray部署记录


## Reality

这里记录我的Xray配置。


```json
{
 "port":443
}
````

````

---

# 五、本地预览

运行：

```bash
mkdocs serve -a 0.0.0.0:8000
````

然后浏览：

```
http://你的IP:8000
```

你会看到：

* 左侧目录
* 搜索框
* Markdown渲染
* 代码高亮
* 夜间模式

效果类似：

![Image](https://images.openai.com/static-rsc-4/igEvhJ8cyizitzD2f_rK1iR3kQ708GrR_uN2h_9bMpctUUoSr4BXCgH0-kkDP8b380-R57qZG2XJEKV24R7zPbWwCy1BniS3QEtAKzuoF6SoBUlRm3x7sy6r9FZYlnMd3IrtGKe61iUvGzUJcoqz-OA0momjRz9Qr3dW4Zxiq-707VkQRSZclkoTH_3_xoMj?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/T7c9pig7KAugIYahpt0f1wluhCqq3LrG2ddZ5riS5lfSFQxgSWIRrha1asWGNzFv5HxMkczvplC896obGG_en-DTQTjt-EObgdiIGYGm9i075W0eL__AYhzcYql6KhY21qgDck_cNrNNijv8Qim4kbpT3puvf-VuwmikfnS0Qbz0nVPOLmJCaWeKS-EhdwjI?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/cVWU_ZyjT-fwsJ7J38OZgSa_8fpwiesVPipJzccll7M4vuV4LV9fS5UaNie50LkxP-2mBgiKqQ4udwr16e4Nbi-eghQqf6dAP8MpeoOCvZaR9mB_Zf3blbuYlH2fvN2x-5Lzwk4rAjzaf24hvbhJ3P0Zz5WIr1MC8s_9HJFwCuJ1woc0CMYEyHFR0pTSffMv?purpose=fullsize)

![Image](https://images.openai.com/static-rsc-4/t-BiVt9x0Oj-YhHIzikaRzFdXCWBjgVlr5tSMgKasNYnmExb9E5uHVJgQ0tZj2vI38MF9bU6jJarTFltgyAxfgALOK1EBVUZb2UiAu6BuBqZHDDsjDP4Sc-ILikgewlMkCGMGxz62AeaQx_-dH_2o2czkdVmiauS5LCik3mwM4ThKHKhEwPK_nwiMdTc-rQF?purpose=fullsize)

---

# 六、正式部署到你的 Caddy

这里是关键。

MkDocs不需要一直运行。

生成静态网站：

```bash
mkdocs build
```

生成：

```
site/

├── index.html
├── assets/
├── search/
└── ...
```

然后：

```
Caddy
 |
 |
 site/
```

即可。

---

## Caddy配置

例如：

```caddy
http://174.138.46.11 {

    root * /home/ice/my-docs/site

    file_server

}
```

然后：

```bash
sudo systemctl reload caddy
```

访问：

```
http://174.138.46.11
```

就是你的知识库。

---

# 七、以后更新流程

非常简单：

修改：

```
docs/*.md
```

例如：

```
docs/
├── ai/
│   ├── quant.md
│   └── llm.md
│
├── hardware/
│   └── fpga.md
│
└── linux/
    └── server.md
```

然后：

```bash
mkdocs build
```

刷新网页。

---

# 八、自动化（推荐）

可以写一个脚本：

`update.sh`

```bash
#!/bin/bash

cd ~/my-docs

source venv/bin/activate

mkdocs build

sudo systemctl reload caddy
```

以后：

```bash
./update.sh
```

完成发布。

---

# 九、你的场景我更推荐这个架构

结合你现在已有：

```
DigitalOcean VPS

        |
        |
     Caddy :80
        |
        |
  MkDocs静态网站


     Xray :443


     WireGuard UDP
```

资源：

```
MkDocs运行时：
0 MB

Caddy:
20 MB

Xray:
10 MB

WireGuard:
5 MB
```

512MB完全足够。

而且非常适合你这种用途：

* 博士论文资料整理
* AI论文笔记
* FPGA/芯片设计记录
* Linux运维记录
* Xray部署文档
* 实验数据说明

实际上很多研究组内部文档就是这个模式。

你现在已经有 Flask 方案的话，我建议**不要继续维护 Flask Markdown Viewer，直接迁移 MkDocs Material**，它更接近你想要的「个人研究知识库」。



很好，你现在已经进入 MkDocs 的真正玩法了。你的用途（论文、AI、芯片、Linux、服务器笔记）其实非常适合 Material for MkDocs。

下面给你几个**值得研究的精品网站**，你可以直接看它们的目录设计、主题配置、Markdown写法。

---

## 1. Material for MkDocs 官方示例（强烈推荐）

这是 Material 主题作者自己维护的示例库：

[Material for MkDocs Examples](https://mkdocs-material.github.io/examples/?utm_source=chatgpt.com)

重点看：

* 左侧导航栏设计
* Tabs
* Admonition 提示框
* 代码块
* 图片
* 数学公式
* Mermaid 图

它基本展示了 Material 能做到的所有效果。([MkDocs Material][1])

---

# 2. Kubernetes 官方文档风格（大型技术文档）

Kubernetes 的文档设计理念非常值得学习：

[https://kubernetes.io/docs/](https://kubernetes.io/docs/)

虽然不是 MkDocs，但它体现了：

```
主页
 |
 +-- Concepts
 |
 +-- Tasks
 |
 +-- Reference
 |
 +-- Tutorials
```

你的研究笔记可以模仿：

```
Ice Research Wiki

|
+-- AI
|    |
|    +-- Quantization
|    +-- LLM
|    +-- Accelerator
|
+-- Hardware
|    |
|    +-- FPGA
|    +-- Architecture
|
+-- Linux
|
+-- Network
```

---

# 3. Python Developer Documentation 风格

例如：

[MkDocs Official Site](https://www.mkdocs.org/?utm_source=chatgpt.com)

它体现了一个重要思想：

> 文档不是文件集合，而是知识结构。

MkDocs 本身就是为这种结构设计的。([MkDocs][2])

---

# 4. 你应该重点学习的功能

你的方向（博士论文、芯片、AI）我建议重点掌握下面几个。

---

## (1) 自动目录 nav

不要所有链接自己写。

例如：

```yaml
nav:

  - Home: index.md

  - AI:
      - Quantization: AI/quantization.md
      - LLM: AI/llm.md

  - Hardware:
      - FPGA: Hardware/fpga.md

  - Server:
      - Xray: Server/xray.md
```

网页自动变：

```
AI
 |
 + Quantization
 + LLM

Hardware
 |
 + FPGA
```

---

## (2) Admonition（非常适合论文笔记）

例如：

```markdown
!!! note

这是一个重要结论。

```

效果：

> 💡 Note
> 这是一个重要结论。

论文阅读笔记特别适合：

```markdown
!!! warning

这个方法存在硬件实现困难。
```

---

## (3) 代码高亮

例如：

````markdown
```verilog
module alu();

endmodule
````

````

显示：

```verilog
module alu();

endmodule
````

你的 FPGA / Verilog 笔记会很好看。

---

## (4) 数学公式

你的量化论文：

```markdown
$$
Q(x)=round(\frac{x}{s})
$$
```

直接显示：

[
Q(x)=round(\frac{x}{s})
]

---

## (5) Mermaid画架构图

这个对你非常有用。

例如你的 Xray 架构：

````markdown
```mermaid
graph LR

A[Client]
-->B[Xray Reality]

B-->C[VPS]

C-->D[Internet]

````

```

自动生成：

```

Client
|
Xray
|
VPS
|
Internet

```

---

# 5. 我认为你最适合模仿的结构

结合你的背景，我建议：

```

docs/

├── index.md

├── Research/
│
│   ├── AI/
│   │    ├── quantization.md
│   │    ├── qat.md
│   │    └── llm.md
│
│   ├── Architecture/
│   │    ├── accelerator.md
│   │    └── memory.md
│
│   └── FPGA/
│        ├── verilog.md
│        └── synthesis.md
│

├── Papers/
│
│   ├── CVPR2018_DoReFa.md
│   ├── GPTQ.md
│   └── FlashAttention.md

├── Server/
│
│   ├── xray.md
│   ├── wireguard.md
│   └── docker.md

└── Notes/

```
├── ideas.md
└── todo.md
```

````

这实际上就是一个**私人博士研究数据库**。

---

# 6. 你现在可以升级几个插件

安装：

```bash
pip install mkdocs-material
pip install mkdocs-git-revision-date-localized-plugin
pip install mkdocs-glightbox
````

然后：

```yaml
plugins:

  - search

  - git-revision-date-localized:
      enable_creation_date: true
```

效果：

每篇文章显示：

```
Created:
2026-08-12

Updated:
2026-08-15
```

非常适合长期积累。

---

# 7. 一个小建议

你现在不要急着美化。

先建立内容体系。

你的 VPS + MkDocs 可以成为：

> 一个长期维护的个人科研操作系统。

以后：

* 读论文 → 写 Markdown
* 做实验 → 写 Markdown
* 配环境 → 写 Markdown
* 产生想法 → 写 Markdown

几年以后，它的价值可能超过论文本身。

你现在这个 512MB VPS，其实已经足够搭一个非常漂亮的个人科研 Wiki。

[1]: https://mkdocs-material.github.io/examples/?utm_source=chatgpt.com "Material for MkDocs"
[2]: https://www.mkdocs.org/?utm_source=chatgpt.com "MkDocs"



有，而且我现在比较清楚你真正想搭的东西了。

你不是单纯想找几个“效率软件”，而是想逐渐搭一个**自己的科研基础设施（Personal Research Infrastructure）**：

> **论文 → 阅读 → 笔记 → 实验 → 代码 → 结果 → 知识沉淀 → 最终形成自己的 Wiki**

你现在的 **MkDocs + Markdown** 正好可以作为这个系统的“知识中枢”。我建议不要再堆很多重量级服务，而是围绕它搭几个轻量工具。

### 我最推荐的组合

| 工具                    | 作用                    | 适合你   |
| --------------------- | --------------------- | ----- |
| **MkDocs + Material** | 最终知识库 / Research Wiki | ⭐⭐⭐⭐⭐ |
| **Zotero**            | 论文、PDF、文献管理           | ⭐⭐⭐⭐⭐ |
| **Obsidian**          | 本地 Markdown 知识编辑、双向链接 | ⭐⭐⭐⭐⭐ |
| **Git**               | Wiki 历史版本、备份          | ⭐⭐⭐⭐⭐ |
| **JupyterLab**        | 实验、Python、数据分析        | ⭐⭐⭐⭐⭐ |
| **Paperless-ngx**     | PDF/扫描件长期归档           | ⭐⭐⭐   |
| **LiteLLM**           | 统一管理各种 LLM/API        | ⭐⭐⭐⭐  |

其中真正值得你马上研究的是前 **5 个**。

---

## ① Zotero：你的“论文数据库”

[Zotero 官方网站](https://www.zotero.org/?utm_source=chatgpt.com)

如果你以后继续做 AI / 芯片 / 量化研究，我认为 **Zotero 几乎是必装的**。

它负责：

```text
论文
 ↓
Zotero
 ├── PDF
 ├── 作者
 ├── DOI
 ├── 会议
 ├── 标签
 ├── 引用
 └── Notes
```

而 MkDocs 不应该承担“管理几千篇 PDF”的任务。

比较理想的关系是：

```text
             Zotero
          /          \
       PDF            文献元数据
        |
        ↓
   阅读 / 标注
        |
        ↓
   Markdown
        |
        ↓
     MkDocs
        |
        ↓
  Personal Research Wiki
```

这样你以后写博士论文、论文综述的时候，会非常舒服。

---

# ② Obsidian：你的“科研工作台”

[Obsidian 官方网站](https://obsidian.md/?utm_source=chatgpt.com)

这个和 MkDocs **不是竞争关系**。

我反而建议你：

> **Obsidian负责写，MkDocs负责展示。**

因为它们都以 Markdown 为核心。

例如：

```text
research/
│
├── AI/
│   ├── quantization.md
│   ├── QAT.md
│   └── FP8.md
│
├── Papers/
│   ├── DoReFa.md
│   ├── GPTQ.md
│   └── SmoothQuant.md
│
└── Experiments/
    ├── exp001.md
    └── exp002.md
```

你可以在 Obsidian 里面快速建立：

```text
Quantization
      ↓
    QAT
   ↙   ↘
FP8     DoReFa
  ↓
Hardware Accelerator
```

然后同一批 Markdown 文件由 MkDocs 发布成漂亮的网站。

这其实是一个非常漂亮的架构：

> **Obsidian = IDE**
>
> **MkDocs = Web UI**

---

# ③ Git：这个我强烈建议你装

你的 Wiki 最终一定会越来越重要。

所以：

```bash
git init
```

然后：

```text
第一次修改
↓
git commit

第二次修改
↓
git commit

半年以后
↓
可以看到自己的知识是怎么演化的
```

甚至可以直接：

```text
Windows
   ↓
Git
   ↓
GitHub/GitLab

       ↕
       
VPS
   ↓
MkDocs
```

于是你修改 Markdown：

```text
写 Markdown
     ↓
git push
     ↓
VPS 自动更新
     ↓
https://你的wiki
```

这时候你的 VPS 就真正变成了一个**私人科研网站**。

---

# ④ JupyterLab：实验记录

这个我觉得非常适合你。

你经常做：

* Python
* 模型量化
* 性能分析
* 数据处理
* FPGA/硬件实验
* IPC 分析
* 能耗估算
* benchmark

可以建立：

```text
Experiments/

2026-08-12-quantization/
│
├── experiment.ipynb
├── data.csv
├── result.png
└── README.md
```

最后把结论整理进：

```text
docs/Research/Quantization/
```

这样：

```text
Jupyter
   ↓
实验
   ↓
数据
   ↓
图
   ↓
结论
   ↓
MkDocs
```

就形成闭环。

---

# ⑤ Paperless-ngx：你的“资料仓库”

这个不是现在最急的。

但以后你如果积累了大量：

* PDF
* 论文
* 说明书
* datasheet
* 芯片手册
* 会议资料
* 扫描文档

可以考虑它。

Paperless-ngx 可以进行 OCR、标签、全文搜索，而且资料可以保存在自己的服务器上。它甚至已经提供可选的 LLM/RAG 功能。([Paperless NGX Documentation][1])

不过：

**你的 512MB VPS 我暂时不建议部署这个。**

它比 MkDocs 重很多。

---

# ⑥ 还有一个非常适合你的东西：AI Research Assistant

这个方向我觉得你以后会非常喜欢。

最终可以变成：

```text
                  ┌──────────────┐
                  │   Zotero     │
                  │   Papers     │
                  └──────┬───────┘
                         ↓
                    PDF / Notes
                         ↓
                  ┌──────────────┐
                  │     AI       │
                  │   Research   │
                  │   Assistant  │
                  └──────┬───────┘
                         ↓
                ┌─────────────────┐
                │   Markdown      │
                │   Research Note │
                └────────┬────────┘
                         ↓
                  ┌──────────────┐
                  │    MkDocs    │
                  │ Research Wiki│
                  └──────────────┘
```

现在已经有人在做类似 **Zotero → AI阅读/总结 → Obsidian** 的开源工作流；社区里也有把 Zotero、论文总结和 Obsidian 串起来的实践。([Reddit][2])

这个方向甚至可以成为你自己的一个小项目。

---

# 我反而不建议你现在装太多

你这个 VPS：

```text
1 CPU
512 MB RAM
10 GB Disk
```

非常适合做：

```text
             VPS
              │
       ┌──────┴──────┐
       │             │
    MkDocs          Git
       │
       │
      Caddy
       │
       ↓
  Research Wiki
```

而：

```text
Zotero
Obsidian
Jupyter
```

主要运行在你的 Windows 电脑上。

这样 VPS 非常轻。

---

# 最终我建议你形成这样的体系

```text
                    我的科研系统
                         │
        ┌────────────────┼────────────────┐
        ↓                ↓                ↓
      Zotero          Obsidian           Git
    管理论文          写知识             版本
        │                │
        ↓                ↓
       PDF          Markdown
        │                │
        └────────┬───────┘
                 ↓
              MkDocs
                 ↓
          Research Wiki
                 │
        ┌────────┼────────┐
        ↓        ↓        ↓
       AI      Hardware  Server
   Quantization FPGA     Xray
       LLM      Verilog  Docker
       QAT      ASIC     Linux
```

这就不是“装几个软件”了。

这是一个真正的：

> **Personal Research Knowledge Base**

而且最重要的是：**这些东西大部分都基于普通文件和 Markdown，不会把你的知识锁死在某个商业平台里。**

你现在已经把 MkDocs 跑起来了，我建议下一步就做一件非常有价值的事情：

**我可以直接帮你设计一套“博士/科研人员专用的 MkDocs Wiki 目录 + `mkdocs.yml` + Material 主题配置 + 首页 + 搜索 + 数学公式 + Mermaid + 论文笔记模板 + 实验记录模板”。**

这样你可以直接把现在这个 Wiki 升级成一个真正能长期使用的**个人科研知识系统**。

[1]: https://docs.paperless-ngx.com/?pubDate=20250704&utm_source=chatgpt.com "Home - Paperless-ngx"
[2]: https://www.reddit.com/r/zotero/comments/1uywutx/i_built_an_opensource_ai_assistant_that_reads/?utm_source=chatgpt.com "I built an open-source AI assistant that reads papers, organizes them in Zotero, and generates Obsidian notes"




当然。其实我现在觉得，你前面折腾 MkDocs 的过程中，真正找到的不是一个“网页工具”，而是一个很适合你长期科研工作的**知识基础设施**。

而且我认真想了一下：以你的使用方式，**不应该追求“装很多科研软件”**，而应该建立一个简单、稳定、可迁移的系统。

我给你从头讲。

---

# 一、先说我理解的你的真实需求

你真正需要的不是：

> “我有一个 VPS，能不能部署一个漂亮的网站？”

而是：

> **我做研究这么多年产生的论文、代码、实验、想法、服务器配置、技术理解，能不能逐渐积累成一个属于我自己的知识系统？**

这两者差别非常大。

传统科研工作经常是这样的：

```text
论文 PDF
   ↓
下载到某个文件夹

实验
   ↓
某个 Python 文件

实验结果
   ↓
Excel / 图片

突然想到一个问题
   ↓
微信 / Notepad / Word

服务器配置
   ↓
某个终端历史记录

半年以后
   ↓
“我当时到底怎么搞的？”
```

最大的问题不是**知识不存在**。

而是：

> **知识没有形成结构。**

你现在做 MkDocs，实际上是在解决这个问题。

---

# 二、我建议你建立一个“三层科研系统”

我认为最适合你的结构是：

```text
                  ┌─────────────────────┐
                  │      Research       │
                  │        Wiki         │
                  │      MkDocs         │
                  └──────────┬──────────┘
                             │
                       知识沉淀层
                             │
              ┌──────────────┴──────────────┐
              ↓                             ↓
       Obsidian / Markdown              Git
         知识编辑层                    版本管理层
              │
              │
      ┌───────┴────────┐
      ↓                ↓
   Zotero          Jupyter / Code
   论文层            实验层
```

分别理解。

---

# 三、第一层：Zotero —— “我看过什么”

Zotero 是你的**文献数据库**。

它解决的是：

> 我到底看过哪些论文？

例如你研究量化：

```text
Quantization
│
├── DoReFa-Net
├── PACT
├── LSQ
├── QAT
├── GPTQ
├── AWQ
├── SmoothQuant
├── FP8
└── ECI
```

每篇论文都有：

```text
Title
Author
Year
Conference
DOI
PDF
Tags
Notes
```

这里千万不要让 MkDocs 去管理 PDF。

**MkDocs 管“知识”。**

**Zotero 管“文献”。**

这是一个非常重要的边界。

---

# 四、第二层：Obsidian —— “我怎么理解”

这是我觉得你会特别喜欢的部分。

Obsidian 的核心不是漂亮。

它真正厉害的是：

> **Markdown + 双向链接 + 本地文件**

例如你读了一篇论文：

```text
DoReFa-Net
```

你可以写：

```markdown
# DoReFa-Net

## 核心思想

提出低比特训练方法。

## 我自己的理解

核心问题是梯度量化。

## 与 LSQ 的关系

[[LSQ]]

## 与 ECI 的关系

[[ECI]]

## 硬件影响

[[Quantization Hardware]]
```

突然之间，你的知识开始形成网络。

---

# 五、这和普通文件夹最大的区别

普通文件夹：

```text
Quantization/
    DoReFa.md
    LSQ.md
    GPTQ.md
```

这是**树状知识**。

而 Obsidian 可以形成：

```text
             Quantization
              /    |    \
             /     |     \
         DoReFa    LSQ    GPTQ
            \       |      /
             \      |     /
              Hardware
                  |
                FPGA
```

这是**知识网络**。

科研特别适合这种结构。

因为科研知识本身就不是线性的。

---

# 六、第三层：MkDocs —— “我最终整理好的知识”

这就是你刚刚已经跑起来的东西。

我建议你把 MkDocs 理解成：

> **自己的科研百科全书。**

不是：

> “我今天想到什么就往里面扔什么。”

而是：

```text
Obsidian
    ↓
思考
    ↓
整理
    ↓
成熟知识
    ↓
MkDocs
```

所以：

### Obsidian 是实验室

### MkDocs 是图书馆

这个比喻非常准确。

---

# 七、那么 Git 是干什么的？

Git 是整个系统的“时间机器”。

假设你今天写：

```text
LSQ.md
```

一个月以后你修改：

```text
LSQ.md
```

半年以后：

> “我以前为什么这么理解？”

Git 可以告诉你。

```text
2026-08-12
    ↓
初稿

2026-09-03
    ↓
修改

2026-10-11
    ↓
加入实验

2027-01-08
    ↓
加入硬件分析
```

这对科研非常有价值。

因为你的知识本身也是会进化的。

---

# 八、然后是 Jupyter：让“实验”和“知识”连接起来

这个对你尤其重要。

假设你研究：

> INT4 vs INT8

你做实验：

```text
experiment.ipynb
```

里面：

```python
accuracy = ...
latency = ...
energy = ...
```

得到：

```text
accuracy
latency
energy
```

然后画：

```text
accuracy vs bit-width
```

实验结束以后，不应该让这个 Notebook 成为孤岛。

你应该写：

```text
Quantization/
    INT4-vs-INT8.md
```

里面记录：

```text
实验目的
实验环境
实验方法
实验结果
结论
```

最后：

```text
Jupyter
    ↓
Experiment
    ↓
Result
    ↓
Markdown
    ↓
MkDocs
```

这才形成闭环。

---

# 九、这样你的 Wiki 就不是“笔记”

这是我特别想强调的一点。

普通笔记：

> “今天学到了 X。”

科研 Wiki：

> “X 是什么 → 为什么 → 怎么证明 → 实验是什么 → 与 Y 什么关系 → 对硬件有什么影响。”

例如：

```text
Quantization
│
├── Basic Concepts
│
├── PTQ
│
├── QAT
│
├── Integer Quantization
│
├── FP8
│
├── INT4
│
└── Hardware
      │
      ├── MAC
      ├── Memory
      ├── SRAM
      └── Accelerator
```

几年以后，这会变成非常有价值的东西。

---

# 十、我甚至建议你把“服务器知识”也放进去

你现在已经遇到一个非常好的例子。

你最近折腾：

```text
Xray
Caddy
Docker
MkDocs
Flask
Nginx
VPS
DNS
TLS
Reality
WireGuard
```

以后你一定会忘。

所以你可以建立：

```text
Server/
│
├── VPS/
│   ├── DigitalOcean.md
│   └── Ubuntu.md
│
├── Network/
│   ├── Xray.md
│   ├── WireGuard.md
│   └── DNS.md
│
├── Web/
│   ├── Caddy.md
│   ├── Nginx.md
│   └── Flask.md
│
└── Docker/
    └── Docker.md
```

比如 `Xray.md`：

```markdown
# Xray

## VPS 信息

...

## Reality 配置

...

## 常见问题

### handshake did not complete successfully

原因：

...

解决方法：

...

### client-fingerprint

...

### public-key

...
```

这其实就是你的**个人运维手册**。

---

# 十一、然后还有一个非常重要的东西：README / Index

我建议你的 Wiki 首页不要做得太花。

而是做成：

```text
# Ice Research Wiki

我的科研、工程与技术知识库。

---

## Research

- AI
- Quantization
- LLM
- Hardware
- FPGA
- Architecture

## Papers

- Paper Notes
- Literature Review

## Experiments

- Benchmark
- Quantization Experiments
- Hardware Experiments

## Engineering

- Linux
- Docker
- Server
- Network

## Ideas

- Research Ideas
- Future Work
- Open Problems
```

**越简单越好。**

---

# 十二、你最终甚至可以把它和你的论文连接起来

这个是我最喜欢的地方。

假设你论文里有：

> 第三章 低比特量化算法

你的 Wiki 可以有：

```text
Research
└── Quantization
    ├── Quantization Basics
    ├── PTQ
    ├── QAT
    ├── DoReFa
    ├── LSQ
    └── ECI
```

论文写：

```text
第三章
    ↓
Wiki 中对应知识
    ↓
实验
    ↓
代码
    ↓
数据
```

以后你写下一篇论文的时候，很多东西已经准备好了。

---

# 十三、再往前一步：AI

这时候 AI 才真正开始发挥作用。

假设你有：

```text
500 篇论文
200 篇 Markdown
100 个实验
50 个代码项目
```

你可以让 AI 帮你回答：

> “我以前有没有研究过 INT4 activation quantization？”

AI 去你的 Wiki 中搜索：

```text
Quantization
INT4
Activation
GPTQ
AWQ
LSQ
```

然后告诉你：

```text
你在 2026-07-03 的笔记中讨论过……
```

这就开始变成：

> **Personal Research Assistant**

而不是简单的 ChatGPT。

---

# 十四、所以我最推荐你的最终架构

如果让我替你设计，我会做成：

```text
                         ┌─────────────────┐
                         │   AI Assistant  │
                         └────────┬────────┘
                                  │
                                  ↓
                     ┌─────────────────────┐
                     │   Research Wiki     │
                     │       MkDocs        │
                     └──────────┬──────────┘
                                │
                    ┌───────────┴───────────┐
                    │                       │
                Markdown                  Git
                    │                       │
             ┌──────┴──────┐                │
             ↓             ↓                │
         Obsidian       Jupyter             │
             │             │                │
             ↓             ↓                ↓
         思考/知识       实验/数据        历史版本
             │             │
             └──────┬──────┘
                    ↓
                  Zotero
                    │
                    ↓
                  Papers
```

而你的 VPS：

```text
                  DigitalOcean VPS
                         │
                 ┌───────┴────────┐
                 ↓                ↓
              MkDocs             Git
                 │
                 ↓
          Research Wiki
```

就够了。

**不要把所有东西都塞进 VPS。**

这是我特别建议你的地方。

---

# 十五、你的 512MB VPS 其实刚刚好

你这个 VPS：

```text
1 CPU
512 MB RAM
10 GB
```

不适合：

```text
❌ 大型数据库
❌ Elasticsearch
❌ 重型 RAG
❌ 大型 AI 模型
❌ 很多 Docker 服务
```

但非常适合：

```text
✅ MkDocs
✅ Caddy
✅ Git
✅ Flask
✅ 小型 API
✅ 静态网站
```

而真正需要计算的：

```text
Python
Jupyter
LLM
Embedding
大型实验
```

放在你的本地电脑或者以后更强的机器。

这是一种非常好的**轻服务器架构**。

---

# 十六、如果让我给你一个“现在就开始”的路线

我不会建议你一下子安装十几个东西。

按照这个顺序：

### 第一阶段：现在

你已经完成：

```text
Ubuntu
  ↓
MkDocs
  ↓
Material
  ↓
Caddy
  ↓
Research Wiki
```

很好。

---

### 第二阶段

加入 Git：

```text
Markdown
   ↓
Git
   ↓
VPS
```

做到**任何修改都有历史记录**。

---

### 第三阶段

本地安装 Obsidian。

然后：

```text
Obsidian
   ↓
Markdown
   ↓
Git
   ↓
VPS
   ↓
MkDocs
```

这一步完成以后，你就已经有一个非常成熟的个人知识系统了。

---

### 第四阶段

加入 Zotero。

建立：

```text
Zotero
   ↓
论文
   ↓
阅读
   ↓
Markdown
```

---

### 第五阶段

加入 Jupyter：

```text
论文
 ↓
假设
 ↓
实验
 ↓
Jupyter
 ↓
数据
 ↓
Markdown
 ↓
Wiki
```

---

### 第六阶段

最后再考虑 AI：

```text
你的全部知识
       ↓
   AI Assistant
       ↓
“我以前研究过什么？”
“这个问题有哪些相关实验？”
“帮我总结过去三个月的研究”
“哪些问题我还没有解决？”
```

这时候才真正有意思。

---

# 最后，我特别想告诉你一件事

你现在做的这个东西，**不要把它当成一个网站项目**。

它更像是在给自己建立一个：

> **数字化的第二大脑 + 科研实验室 + 技术档案馆。**

而且你现在选择 Markdown 是非常好的。

因为哪怕十年以后：

* MkDocs 不用了；
* Obsidian 不用了；
* VPS 换了；
* GitHub 不用了；
* AI 工具换了一轮；

你的核心资产仍然只是：

```text
.md
.py
.ipynb
.pdf
.csv
.png
```

这些东西依然属于你。

**软件可以换，知识不应该被软件锁住。**

所以，如果是我替你继续往下做，我下一步不会再给你推荐更多软件了。

我会直接帮你把现在这个 MkDocs Wiki **设计成一套真正适合博士研究/工程研究的模板**：包括目录结构、首页、Material 配置、论文笔记模板、实验模板、Research Idea 模板、代码/图片组织方式、Git 工作流，以及以后如何让 AI 搜索你的整个 Wiki。

这一步做好之后，你就可以开始往里面真正积累东西了。



你这个问题其实已经从“工具选择”进入到了**科研生产力体系设计**。

而且结合你前面的实践（VPS、MkDocs、Xray、硬件设计、量化算法、论文整理），我觉得你现在真正需要提升的不是某一个软件，而是：

> **如何把一个科研人员从“做一次性任务”，升级为“持续积累、复用、迭代的研究系统”。**

我按照科研生命周期来讲。

---

# 一、先建立一个核心思想：科研不是项目，而是流水线

很多科研人员工作模式：

```
接项目
 ↓
查资料
 ↓
做实验
 ↓
写论文
 ↓
结束
 ↓
重新开始
```

最大的问题：

**每个项目都是从零开始。**

高效科研应该是：

```
知识库
  ↓
研究方向
  ↓
论文
  ↓
专利
  ↓
基金
  ↓
项目
  ↓
新知识
  ↓
回流知识库
```

形成循环。

你的 MkDocs Wiki 正好可以成为这个循环的核心。

---

# 二、建立“科研资产库”

我建议你的 Wiki 不应该只有：

```
论文
代码
实验
```

还应该包括下面这些。

---

# 1. Concept Library（概念库）

这是最重要的。

例如你研究 AI 芯片：

```
Concepts/

├── Quantization
│
├── Transformer
│
├── Attention
│
├── Memory Wall
│
├── Compute Density
│
├── Sparse Computing
│
├── Near Memory Computing
│
└── Hardware Accelerator
```

每个概念不是简单定义。

而应该有：

```markdown
# Memory Wall


## Why important?

为什么成为瓶颈


## Historical evolution

CPU cache
GPU HBM
Near Memory


## Current solutions

1.
2.
3.


## My ideas

未来可能方向
```

几年以后：

你会发现自己拥有一本自己的教材。

---

# 2. Method Library（方法库）

科研最大的价值不是结果。

而是：

> 解决问题的方法。

例如：

```
Methods/

├── Quantization Method

├── Hardware Optimization

├── FPGA Design

├── RTL Optimization

├── Benchmark Method

├── Experimental Design

└── Paper Writing
```

比如：

```markdown
# 如何证明硬件优化有效


## Baseline

必须包含


## Metrics

Latency
Energy
Area


## Fair Comparison

...


## Common mistakes

...
```

以后写论文、基金，会大量复用。

---

# 三、论文写作效率提升

很多博士生写论文很痛苦，因为：

论文 = 从空白 Word 开始。

错误。

论文应该是：

```
已有知识
 +
实验记录
 +
图表
 +
观点

↓

论文
```

---

## 建议建立 Paper Factory

目录：

```
Papers/

├── Published/

├── Draft/

├── Ideas/

└── Reviews/
```

---

每个论文想法建立：

```
Idea-001.md
```

里面：

```markdown
# Idea

## Problem

当前问题是什么？


## Observation

我观察到了什么？


## Hypothesis

我的猜想


## Method

怎么解决？


## Experiment

如何证明？


## Expected contribution

贡献点
```

这个东西非常重要。

因为很多优秀想法死在：

> “当时觉得不错，但是没记录。”

---

# 四、论文写作模板化

不要每次重新设计论文结构。

建立：

```
Templates/

├── IEEE Paper.md

├── Nature Style.md

├── Conference Paper.md

├── Patent.md

├── Grant Proposal.md
```

例如论文：

```
Abstract

1 Introduction

2 Related Work

3 Motivation

4 Method

5 Experiment

6 Discussion

7 Conclusion
```

但是你的模板里面应该有提醒：

```
Introduction:

□ 为什么重要？
□ 现有方法不足？
□ 为什么现在解决？
□ 我的贡献？
```

这相当于一个自动检查表。

---

# 五、专利写作效率提升

这个很多科研人员没有系统。

实际上专利和论文完全不同。

论文：

> 我证明我先进。

专利：

> 我保护一个可实施的技术方案。

---

建议建立：

```
Patent/

├── Ideas

├── Filed

├── Granted

└── Technology Map
```

---

每个专利想法：

```
Patent Idea.md
```

模板：

```markdown
# 发明名称


## 技术领域

属于什么领域


## 背景问题

现在有什么不足


## 核心创新点

一句话描述


## 技术方案

系统结构：

模块1

模块2

模块3


## 与已有技术区别

Difference


## 可保护范围

核心权利要求


## 实施例

Example
```

---

注意：

很多论文内容其实可以转化专利。

例如你做：

```
低比特训练芯片
```

论文：

强调：

> accuracy improvement

专利：

强调：

> 一种基于xxx的数据通路优化方法

完全不同。

---

# 六、基金申请效率提升

基金申请其实最适合知识库。

因为基金不是突然写出来的。

优秀基金：

通常来自：

3-5 年积累。

---

建立：

```
Grant/

├── National Fund

├── Industry Project

├── Proposal Ideas

├── Review Comments

└── Research Roadmap
```

---

基金核心：

不是技术细节。

而是：

```
国家需求
 ↓
科学问题
 ↓
关键技术
 ↓
研究内容
 ↓
路线
 ↓
预期成果
```

建议建立：

## Research Roadmap

例如：

```
AI Hardware

2025
低比特计算


2026
自适应量化


2027
存算融合


2030
智能计算系统
```

以后申请基金非常有帮助。

---

# 七、建立“失败数据库”

这个非常少有人做。

但是顶级研究人员经常做。

建立：

```
Failures/

├── Failed Experiments

├── Wrong Hypothesis

├── Rejected Papers

└── Reviewer Comments
```

例如：

```markdown
# Why Method X Failed


Hypothesis:

增加PE数量提升性能


Experiment:

性能没有提升


Reason:

Memory bandwidth bottleneck


Lesson:

不要只优化compute
```

几年以后：

这个数据库价值非常高。

因为：

失败经验不可搜索，但非常宝贵。

---

# 八、建立 Reviewer Comment Database

这个对论文、基金特别有效。

例如：

```
Reviewer/

├── IEEE Reviews

├── Nature Reviews

├── Grant Reviews

└── Common Criticism
```

记录：

```
Reviewer:

"The novelty is unclear"


Meaning:

创新点没有突出


Solution:

Introduction重新组织
```

几年以后你会发现：

审稿意见高度重复。

---

# 九、建立自动化工具链

你的 VPS 可以继续发挥作用。

例如：

## 1. 自动论文提醒

每天：

```
arxiv
↓
关键词过滤
↓
发送摘要
```

关键词：

```
quantization
LLM accelerator
AI hardware
FPGA
```

---

## 2. 自动实验记录

例如：

你的实验：

```
python run.py
```

自动生成：

```
Experiment/

2026-08-12/

config.yaml

result.csv

figure.png

log.txt
```

---

## 3. 自动生成报告

例如：

实验结束：

```
result.csv

↓

Markdown Report

↓

MkDocs
```

---

# 十、时间管理：科研人员最容易犯的问题

不要把每天时间全部用于：

```
回复邮件
改格式
开会
处理杂事
```

应该分：

---

## Deep Work

每天固定：

2-4小时

只做：

```
思考
阅读
写作
设计实验
```

---

## Maintenance

处理：

```
邮件
会议
行政
```

---

## Knowledge Capture

每天 15 分钟：

记录：

```
今天学到了什么？
有什么想法？
下一步？
```

这 15 分钟长期收益巨大。

---

# 十一、AI 如何真正帮助科研

不要把 AI 当：

“帮我写论文”。

价值更大的是：

---

## 1. Literature Assistant

输入：

```
100篇论文
```

问：

```
这个领域有哪些技术路线？
```

---

## 2. Reviewer Simulation

把论文给 AI：

问：

```
你作为DAC/ISCA reviewer，
指出问题。
```

---

## 3. Idea Generator

输入：

```
我的研究方向
已有工作
限制
```

问：

```
未来三个可能突破方向？
```

---

## 4. Knowledge Search

未来：

你的 Wiki：

```
5000 markdown
```

AI：

```
帮我找所有关于memory bottleneck的研究。
```

---

# 十二、我认为最值得你现在做的10件事

按照收益排序：

| 优先级   | 系统             |
| ----- | -------------- |
| ⭐⭐⭐⭐⭐ | MkDocs科研Wiki   |
| ⭐⭐⭐⭐⭐ | Git版本管理        |
| ⭐⭐⭐⭐⭐ | 论文阅读模板         |
| ⭐⭐⭐⭐⭐ | Research Idea库 |
| ⭐⭐⭐⭐  | Zotero文献管理     |
| ⭐⭐⭐⭐  | 实验自动记录         |
| ⭐⭐⭐⭐  | 专利模板库          |
| ⭐⭐⭐⭐  | 基金路线图          |
| ⭐⭐⭐   | Reviewer意见库    |
| ⭐⭐⭐   | AI知识助手         |

---

# 最后给你一个我认为非常适合你的个人科研架构

```
                 AI Assistant
                       |
                       |
              Research Wiki
                 MkDocs
                       |
        -----------------------------
        |             |             |
    Literature    Experiment    Ideas
      Zotero       Jupyter      Markdown
        |             |             |
        -----------------------------
                       |
                     Git
                       |
                    Backup
```

你的 VPS：

```
Caddy
 |
MkDocs
 |
Git repository
```

你的本地：

```
Obsidian
Jupyter
Zotero
VS Code
```

这套系统的目标不是让你“今天效率提高10%”。

而是：

> **五年后，你拥有一个别人无法复制的个人科研数据库。**

对于博士后、青年教师、研究员，这种长期积累的复利价值，往往比单纯学会某个工具大得多。你现在开始搭这个系统，其实时间点非常好。



