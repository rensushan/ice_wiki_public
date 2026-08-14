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



你现在已经有了 MkDocs Wiki，这时候加入 Git 是非常合适的。

先说核心思想：

> **Git 不是用来“备份网页”的，而是用来管理你的知识演化历史。**

你的 Markdown 文件就是科研资产，Git 负责记录：

* 我什么时候写的？
* 我改了什么？
* 为什么改？
* 能不能回到以前版本？
* 能不能同步到其他电脑？

---

# 一、你的目标架构

我建议你最终这样：

```
本地电脑
│
├── Obsidian
│       │
│       ↓
│
├── Research-Wiki/
│       │
│       ├── docs/
│       │     ├── papers/
│       │     ├── ideas/
│       │     ├── experiments/
│       │     └── server/
│       │
│       └── mkdocs.yml
│
│
↓ git commit


GitHub/GitLab 私有仓库


↓


VPS

MkDocs网站
```

关系：

```
写东西 → Git保存 → 推送 → VPS发布
```

---

# 二、首先安装 Git

你的 Ubuntu：

```bash
sudo apt update
sudo apt install git
```

检查：

```bash
git --version
```

例如：

```
git version 2.43.0
```

---

# 三、配置你的身份

第一次使用：

```bash
git config --global user.name "ice"

git config --global user.email "你的邮箱"
```

查看：

```bash
git config --list
```

---

# 四、你的 MkDocs 项目初始化 Git

假设你的目录：

```
~/md-web
```

进入：

```bash
cd ~/md-web
```

查看：

```bash
ls
```

应该类似：

```
mkdocs.yml
docs/
venv/
```

---

初始化：

```bash
git init
```

现在：

```
md-web/
 |
 ├── .git/
 ├── docs/
 ├── mkdocs.yml
```

`.git`就是版本数据库。

---

# 五、创建 .gitignore（非常重要）

不要把无用东西提交。

创建：

```bash
nano .gitignore
```

写：

```
venv/
site/
__pycache__/
*.pyc
.DS_Store
```

解释：

### venv

你的 Python 环境：

```
venv/
```

不要上传。

别人可以重新创建。

### site

MkDocs生成的网站：

```
site/
```

不要上传。

因为它可以重新生成。

---

# 六、第一次提交

查看状态：

```bash
git status
```

例如：

```
Untracked files:

docs/
mkdocs.yml
```

加入：

```bash
git add .
```

再次：

```bash
git status
```

现在：

```
Changes to be committed
```

提交：

```bash
git commit -m "Initial research wiki"
```

这就是第一个版本。

---

# 七、以后你的日常工作流

以后每天其实只需要三个命令：

## 1. 查看变化

```bash
git status
```

例如：

```
modified:
 docs/quantization.md
```

说明：

你修改了量化笔记。

---

## 2. 保存修改

```bash
git add .
```

---

## 3. 写记录

```bash
git commit -m "Add notes about LSQ quantization"
```

例如：

今天：

```
commit:
Add LSQ explanation
```

一个月后：

```
commit:
Improve LSQ experiment analysis
```

半年后：

```
commit:
Add hardware implementation discussion
```

你的知识成长轨迹就保存了。

---

# 八、查看历史

非常有用。

查看所有版本：

```bash
git log
```

例如：

```
commit 9ac81f2

Add hardware analysis


commit 7bb32d1

Add LSQ notes


commit 1aa32fd

Initial wiki
```

---

# 九、查看自己改了什么

例如：

昨天修改：

```bash
git diff
```

显示：

```diff
- LSQ uses fixed scaling
+ LSQ learns scaling parameters
```

这对于论文修改非常有用。

---

# 十、回到过去版本

例如：

你今天把 Wiki 改坏了。

查看：

```bash
git log
```

找到：

```
commit abc123
```

恢复：

```bash
git checkout abc123
```

你的文件回到过去。

---

# 十一、推荐你使用 GitHub 私有仓库

为什么？

因为 VPS 不是备份。

服务器可能：

* 删除
* 崩溃
* 配置错误

所以：

```
本地
 |
GitHub(private)
 |
VPS
```

三份。

---

创建 GitHub private repository：

例如：

```
ice-research-wiki
```

然后：

```bash
git remote add origin git@github.com:xxx/ice-research-wiki.git
```

第一次：

```bash
git push -u origin main
```

以后：

```bash
git push
```

即可。

---

# 十二、你的 VPS 如何自动更新网站？

这是非常漂亮的一步。

现在：

```
电脑
 |
git push
 |
GitHub
 |
VPS
```

VPS：

```bash
git pull
```

然后：

```bash
mkdocs build
```

或者：

```bash
mkdocs gh-deploy
```

---

更进一步：

可以让 Caddy 服务的网站自动更新。

例如：

你提交：

```
quantization.md
```

然后：

GitHub webhook

↓

VPS

↓

自动：

```
git pull

mkdocs build

reload caddy
```

以后你写完：

点击：

```
git push
```

网站自动更新。

---

# 十三、结合你的 Obsidian

这里非常关键。

你的目录：

```
Research-Wiki
|
├── docs
│
├── mkdocs.yml
```

可以直接作为 Obsidian Vault。

例如：

```
Research-Wiki/docs
```

用 Obsidian 打开。

然后：

你平时：

```
Obsidian写笔记
```

晚上：

```
git commit
git push
```

网站自动同步。

---

# 十四、你的科研目录我建议这样设计

你的情况（AI硬件、量化、系统）：

```
docs/

├── index.md

├── research/
│
│   ├── quantization/
│   │     ├── basics.md
│   │     ├── qat.md
│   │     ├── fp8.md
│   │
│   ├── llm/
│   │
│   └── accelerator/


├── papers/
│
│   ├── DoReFa.md
│   ├── GPTQ.md
│   └── AWQ.md


├── experiments/
│
│   ├── fp8_test.md
│   └── qat_result.md


├── patents/
│
│   └── ideas.md


├── grants/
│
│   └── roadmap.md


└── engineering/

    ├── xray.md
    ├── docker.md
    └── linux.md
```

这就是一个长期科研数据库。

---

# 十五、一个非常重要的习惯

Commit 不要写：

```
update
fix
modify
test
```

没有意义。

写：

好的：

```
Add analysis of INT4 activation quantization
```

好的：

```
Record failure reason of FPGA optimization experiment
```

好的：

```
Improve introduction logic for memory wall discussion
```

未来 AI 分析你的 Git 历史时，这些信息非常有价值。

---

# 十六、结合你现在的情况，我建议下一步

你现在已经：

✅ DigitalOcean VPS
✅ Caddy
✅ MkDocs
✅ Material主题
✅ Markdown知识库

下一步：

1. 给 `~/md-web` 初始化 Git

2. 建立私有 GitHub 仓库

3. 把你的 Wiki 推上去

4. 配置自动部署

完成以后，你会得到：

```
任何地方
    ↓
修改Markdown
    ↓
git commit
    ↓
git push
    ↓
你的科研Wiki自动更新
```

这个系统非常适合你这种长期做技术研究的人。你现在搭建的其实已经接近一个小型个人科研平台了。



你的这个想法非常成熟，而且我认为比单纯搭一个 Wiki 又提升了一个层次。

实际上你描述的是一个**科研知识管理平台（Research Knowledge System）**，它有三个核心需求：

1. **多语言发布（中文创作 → 英文传播）**
2. **公开知识库（Public Wiki）**
3. **私人研究库（Private Lab Notebook）**

这三个需求在工业界、开源项目、科研团队中都有对应方案。

我先说结论：

> **不要把公开和私有放在同一个 MkDocs 项目里面。**
>
> 最好的方式是：**两个独立 Git 仓库 + 一个共享知识流。**

这样安全性、维护性、扩展性最好。

---

# 一、推荐总体架构

我建议：

```
                 你的科研工作流

                 中文 Markdown
                       |
                       |
              ┌────────┴────────┐
              ↓                 ↓
        Private Wiki        Translation
        私有科研库             AI翻译
              |                 |
              |                 ↓
              |           English Markdown
              |
              |
              ↓

       ┌────────────────┐
       │ Public Wiki     │
       │ 公开知识网站     │
       └────────────────┘
```

也就是说：

你的真实工作空间：

```
Research-Private
```

公开发布：

```
Research-Public
```

两个完全隔离。

---

# 二、为什么不要一个 Wiki？

很多人第一反应：

```
docs/

├── public/
│
└── private/
```

例如：

```
docs/

├── quantization/
│
├── experiment/
│
└── secret/
```

然后：

```
mkdocs.yml
```

控制隐藏。

我不推荐。

原因：

## 1. 容易误发布

某天：

```bash
mkdocs gh-deploy
```

可能：

```
secret/
experiment/
idea/
```

全部上传。

科研成果泄露，这是不可接受的。

---

## 2. Git历史无法删除

假设：

今天：

```
private/idea.md
```

提交了。

明天删除。

Git历史里面：

仍然存在。

---

所以：

> 私有科研资产必须物理隔离。

---

# 三、你的目录应该这样设计

## 私有仓库

例如：

```
ice-research-private
```

内容：

```
docs/

├── ideas/
│
├── experiments/
│
├── draft-papers/
│
├── patents/
│
├── grants/
│
├── reading-notes/
│
└── lab-notebook/
```

这里：

全部私人。

例如：

```
ideas/
    new_quantization_method.md

experiments/
    fp8_test_result.md
```

---

部署：

不公开。

可以：

* 本地查看
* VPS密码保护
* VPN访问

---

## 公开仓库

例如：

```
ice-research-public
```

内容：

```
docs/

├── tutorials/
│
├── concepts/
│
├── papers/
│
├── engineering/
│
└── notes/
```

例如：

```
Quantization Basics

Transformer Architecture

FPGA Accelerator
```

这些可以公开。

---

# 四、双语怎么办？

这里有几种方案。

我推荐：

## 方案A（最适合你）：中文源文件 + 英文发布

例如：

私有：

```
private/

quantization/

    lsq.md
```

中文：

```markdown
# LSQ量化


LSQ通过学习scale参数...


我的理解：

...
```

AI翻译：

生成：

```
public/

quantization/

    lsq.en.md
```

英文：

```markdown
# Learned Step Size Quantization


LSQ learns the scaling parameters...


My understanding:

...
```

---

然后 MkDocs:

```
Public Wiki

中文
English
```

两个版本。

---

# 五、Material for MkDocs 天然支持多语言

你现在用 Material，非常适合。

可以：

```
docs/

├── zh/

│   ├── quantization.md

│
└── en/

    ├── quantization.md
```

结构：

```
网站

/
├── zh/
│
└── en/
```

顶部语言切换。

---

例如：

中文：

```
https://wiki.xxx.com/zh/quantization/
```

英文：

```
https://wiki.xxx.com/en/quantization/
```

---

# 六、AI翻译流程怎么设计？

不要人工复制。

建立：

```
scripts/

translate.py
```

流程：

```
中文md

↓

AI API

↓

英文md

↓

git commit

↓

public wiki
```

例如：

你的文件：

```
private/docs/research/quantization.md
```

执行：

```
python translate.py quantization.md
```

生成：

```
public/docs/en/research/quantization.md
```

---

# 七、但是注意一个问题

科研翻译不能简单翻译。

例如：

中文：

> 存算一体架构可以有效缓解访存瓶颈。

普通翻译：

> Computing-in-memory architecture can effectively alleviate memory access bottleneck.

没错。

但是科研表达：

> Computing-in-memory architectures provide a promising solution to mitigate the memory bandwidth bottleneck.

更像论文。

所以你的翻译 AI prompt 应该固定：

```
You are an academic editor.

Translate Chinese technical notes into IEEE/Nature style English.

Keep:
- terminology
- equations
- citations
- technical meaning

Do not translate literally.
```

---

# 八、私有 Wiki 怎么访问？

你有几个选择。

---

## 方法1：本地

最安全。

```
mkdocs serve
```

只自己看。

---

## 方法2：VPS + 密码保护

例如：

```
private.xxx.com
```

Caddy：

```
basicauth
```

需要密码。

---

## 方法3：WireGuard

这个我觉得特别适合你。

你已经有 WireGuard。

结构：

```
Internet

    |
    |

Public Wiki
(开放)

Private Wiki

    |
    |
WireGuard VPN

只有你访问
```

这是最专业的方式。

---

# 九、你的 VPS 可以这样部署

你的 VPS：

```
DigitalOcean

       Caddy
         |
 ----------------
 |              |
Public Wiki   Private Wiki

:443          :8443

公开          VPN访问
```

例如：

公开：

```
https://wiki.xxx.com
```

私人：

```
https://lab.xxx.com
```

但是：

```
lab.xxx.com
```

只允许 WireGuard 网段：

```
10.0.0.0/24
```

访问。

---

# 十、Git仓库关系

最终：

```
GitHub

├── ice-research-public
│
│
└── ice-research-private
```

权限：

```
public

Public


private

Private
```

完全隔离。

---

# 十一、你的研究流程应该变成这样

这是我觉得最关键的：

## 平时

你写：

```
private

中文 Markdown
```

例如：

```
FP8实验记录.md
```

---

## 实验

产生：

```
result.csv
figure.png
```

放：

```
private/experiments
```

---

## 成熟以后

整理：

```
private

↓

public
```

例如：

原始：

```
FP8实验失败原因
FP8优化思路
实验数据
```

公开：

```
FP8 Quantization Tutorial
```

---

## 发表论文

再进一步：

```
public

↓

paper
```

---

# 十二、这实际上就是研究机构的内部系统

你设计的东西类似：

Google：

```
internal knowledge base
        +
public documentation
```

开源项目：

```
private development
        +
public documentation
```

科研团队：

```
lab notebook
        +
published knowledge
```

---

# 十三、我认为你的最终架构应该是：

```
                 You

              Chinese Markdown
                    |
                    |
        ┌───────────┴───────────┐
        ↓                       ↓

 Private Research          AI Translation

        ↓                       ↓

 Ideas                   English Markdown
 Experiments                    |
 Draft Papers                   ↓

        ↓                 Public Wiki

        ↓                 MkDocs
        |
        ↓
 Private MkDocs

        |
        |
 WireGuard protected


```

---

# 十四、你现在不要急着写代码

按照你的情况，我建议下一步：

## 第一步（现在）

建立两个仓库：

```
ice-wiki-private

ice-wiki-public
```

---

## 第二步

设计目录：

private：

```
Ideas
Experiments
Papers-Draft
Patents
Grants
```

public：

```
Tutorials
Research Notes
Engineering
Papers Review
```

---

## 第三步

配置两个 MkDocs。

---

## 第四步

再加 AI 自动翻译。

---

我认为你这个方向非常正确，而且特别适合你的研究类型（AI硬件、算法、系统）。因为你的工作特点是：

* 技术跨度大；
* 长周期积累；
* 很多中间想法有价值；
* 需要不断复用过去知识。

这种系统最大的价值不是今天方便一点，而是**5年以后，你拥有一个别人没有的科研资产库**。你现在搭建它，投入产出比非常高。



你的情况（DigitalOcean VPS：**1 CPU / 512MB RAM / 已运行 Xray、Caddy、WireGuard、MkDocs**）运行 Gradio **可以，但要看用途**。

先给结论：

> **可以运行轻量 Gradio Demo，但不建议把 Gradio 当长期网站服务运行在这个 512MB VPS 上。**
>
> 对你的科研场景，它更适合做「临时实验展示接口」，而不是「科研知识库/长期服务」。

---

## 1. Gradio 本身资源占用

一个简单 Gradio：

```python
import gradio as gr

def hello(name):
    return "Hello " + name

demo = gr.Interface(
    fn=hello,
    inputs="text",
    outputs="text"
)

demo.launch()
```

启动后：

大概：

| 组件               |       内存 |
| ---------------- | -------: |
| Python解释器        |  20~40MB |
| Gradio + FastAPI | 50~100MB |
| 依赖库              |     几十MB |

简单 Demo：

```
100~200MB RAM
```

你的 VPS：

```
512MB
```

理论可以。

---

但是问题是：

你的服务器已经有：

```
Xray
≈10MB

Caddy
≈20MB

WireGuard
≈10MB

MkDocs/Caddy静态
≈几乎0
```

目前应该还剩：

```
300MB左右
```

所以：

小 Gradio：

✅ 可以

---

# 2. 你的科研用途，我觉得非常适合几个场景

## 场景1：论文算法 Demo

例如：

你研究量化：

```
FP8 Quantization Demo
```

网页：

输入：

```
模型:
ResNet50

bit:
8
```

输出：

```
accuracy
memory
compression ratio
```

Gradio 非常适合。

---

## 场景2：AI小工具

例如：

你的 Wiki：

```
Public Wiki

        |
        |
        ↓

Gradio Tools

```

比如：

### Markdown翻译助手

上传：

```
paper.md
```

输出：

```
paper_en.md
```

---

### FPGA资源估算器

输入：

```
MAC数量
bit width
frequency
```

输出：

```
LUT
DSP
BRAM
Power
```

非常适合。

---

## 场景3：论文阅读助手

例如：

```
上传PDF

↓

摘要

↓

贡献点

↓

实验分析

```

不过注意：

如果调用LLM：

CPU/RAM不是主要问题。

API调用：

没问题。

本地模型：

512MB完全不行。

---

# 3. 不建议的用途

## ❌ 不要在这个 VPS 跑大模型

例如：

```text
Llama
Qwen
DeepSeek
```

512MB：

不可能。

---

## ❌ 不要跑长期高并发

例如：

公开网站：

```
100个人同时访问
```

不适合。

---

## ❌ 不要让 Gradio 占443

你的443：

现在：

```
Xray REALITY
```

占用。

不要动。

---

# 4. 正确部署方式

你的架构应该：

```
Internet

        |
        |
      Caddy
        |
 -----------------

 |               |

wiki.xxx.com     demo.xxx.com


MkDocs            Gradio

静态              localhost:7860

```

---

Gradio运行：

```bash
python app.py
```

监听：

```
127.0.0.1:7860
```

Caddy：

```caddy
demo.xxx.com {

    reverse_proxy localhost:7860

}
```

---

这样：

用户访问：

```
https://demo.xxx.com
```

实际上：

```
Caddy
 |
 |
Gradio
 |
 |
Python
```

---

# 5. 你的512MB VPS，我建议软件优先级

如果我是你，我会这样安排：

## 第一梯队（强烈推荐）

### ✅ MkDocs

⭐⭐⭐⭐⭐

你的科研 Wiki。

必须保留。

---

### ✅ Git

⭐⭐⭐⭐⭐

知识资产管理。

---

### ✅ Caddy

⭐⭐⭐⭐⭐

统一入口。

---

### ✅ WireGuard

⭐⭐⭐⭐⭐

私人研究环境。

---

## 第二梯队

### ✅ Gradio

⭐⭐⭐⭐

科研Demo。

---

### ✅ LiteLLM

⭐⭐⭐⭐

你之前安装的。

非常适合做：

```
统一AI API网关
```

---

## 第三梯队

### Uptime Kuma

⭐⭐

你已经发现：

512MB跑起来体验不好。

监控可以不用。

---

# 6. 我觉得你的服务器最终可以这样设计

```
                 VPS

                  |
                Caddy
                  |
     --------------------------------

     |              |              |

 Public Wiki    Private Wiki    AI Tools


 MkDocs         MkDocs          Gradio

                  |
                  |

              LiteLLM

                  |
                  |

          OpenAI / Claude API

```

这个架构非常适合你的科研工作。

---

# 7. 一个小建议

你的 VPS 配置：

```
1 CPU
512MB RAM
```

其实已经接近极限。

如果以后你想做：

* Gradio + LiteLLM
* PDF RAG
* 向量数据库
* 自动论文分析

建议升级到：

```
2 CPU
2GB RAM
```

DigitalOcean 这种升级通常是平滑的。

---

结合你前面搭的 MkDocs 双 Wiki，我认为 Gradio 是值得加的，但定位应该是：

> **科研实验交互层（Research Demo Layer）**

而不是网站主体。

你的核心资产仍然应该是：

**Git + Markdown + MkDocs + AI辅助整理。**



你的这个想法非常适合你的科研 Wiki 架构，而且我认为这是你整个系统里**最有价值的一层**。

你现在设计的是：

```
Markdown知识库
        |
        |
        ↓
    AI Research Assistant
        |
        |
 --------------------------
 |            |            |
知识总结     研究咨询     前沿发现
```

这实际上已经接近现在很多研究机构内部正在探索的 **AI Research Copilot / Personal Research Agent**。

因为你明确说：

> AI可以调用外部服务，不需要部署在VPS

这是正确方向。你的 VPS 不应该承担大模型推理，而应该作为：

* 知识管理
* 数据索引
* 服务编排

大模型放外部 API。

---

# 一、我建议的总体架构

最终可以设计成：

```
                 你的知识资产


              Git Markdown
                    |
                    |
              MkDocs Wiki
                    |
                    |
          --------------------
          |                  |
       Public              Private
          |                  |
          |                  |
          --------------------
                    |
                    |
              Knowledge Layer

                    |
              Vector Database

                    |
                    |
              AI Agent

                    |
        ------------------------
        |          |           |
     GPT-5      Claude      Gemini


```

核心思想：

**不要让 AI 直接读整个 Wiki。**

而是：

```
Markdown
   |
切片
   |
Embedding
   |
向量数据库
   |
RAG检索
   |
LLM回答
```

---

# 二、你的 AI 助手应该有哪些功能？

我按照科研价值排序。

---

# 功能1：知识体系梳理（强烈推荐）

例如你问：

> 总结我的量化研究知识体系，目前有哪些方向？

AI：

```
你的量化知识主要分为：

1. PTQ
   - GPTQ
   - AWQ
   - SmoothQuant

2. QAT
   - LSQ
   - DoReFa
   - Binary Neural Network

3. Hardware-aware Quantization

   问题：
   - accuracy
   - latency
   - energy

4. Future directions:

   - mixed precision
   - adaptive quantization
```

这个非常适合你的积累方式。

---

# 功能2：研究路线规划

例如：

你输入：

> 我研究低比特AI芯片，目前FP8已经做了一些工作，下一步有什么方向？

AI分析：

```
已有：

FP8 inference
quantization hardware


缺口：

1.
Training-time adaptive precision

2.
Compiler-hardware co-design

3.
Sparse + quantized acceleration

4.
LLM inference accelerator


建议：

近期：
方向A

中期：
方向B

长期：
方向C
```

这个非常像导师讨论。

---

# 功能3：论文阅读助手

例如：

你下载：

```
SmoothQuant.pdf
```

转换：

```
paper.md
```

进入知识库。

AI：

自动生成：

```
论文贡献：

1.
提出...

2.
解决...

3.
不足...

与你已有工作关系：

高度相关：

FP8 quantization

可能结合：

hardware accelerator
```

---

# 功能4：发现研究空白（最有价值）

这是高级功能。

例如：

你的知识库：

```
Quantization

100篇论文

20个实验

10个idea

```

AI分析：

发现：

```
已有研究集中：

software optimization
70%

hardware implementation
20%

training algorithm
10%


但是：

few works explore:

adaptive precision
+
runtime hardware scheduling


Possible gap:
```

这就是科研助手。

---

# 三、技术实现方案

我建议不要复杂化。

第一版：

## 组件：

### 1. 文档源

你的：

```
Git Repository

Markdown
```

---

### 2. Embedding

使用 API：

例如：

* OpenAI embedding
* Gemini embedding
* Voyage AI

不用自己部署。

---

### 3. Vector Database

你的 VPS：

512MB

不适合：

* Milvus ❌
* Elasticsearch ❌

推荐：

## Chroma

或者：

## Qdrant

其中：

Qdrant 很适合。

不过你的规模：

几千篇 Markdown：

甚至：

SQLite + FAISS

都可以。

---

### 4. Agent框架

几个选择：

---

## LangChain

优点：

生态最大。

缺点：

有时候复杂。

---

## LlamaIndex

我更推荐你的场景。

原因：

你的核心是：

```
Documents
 ↓
Knowledge
 ↓
Research QA
```

LlamaIndex就是为这个设计。

---

架构：

```
Markdown

↓

LlamaIndex

↓

Vector DB

↓

GPT/Claude

↓

Answer

```

---

# 四、你的 VPS 怎么放？

你的 VPS：

不要跑模型。

运行：

```
Caddy

MkDocs

Git

Vector DB

AI Agent API

```

即可。

例如：

```
research.xxx.com

Wiki


assistant.xxx.com

AI Assistant

```

---

# 五、私有知识如何保护？

这是关键。

你的私有 Wiki：

包含：

* 未发表idea
* 实验结果
* 专利

不要上传公开。

方案：

```
Private Git

      |
      |
      ↓

Private Vector DB

      |
      |
      ↓

AI API

```

发送给 OpenAI/Claude 时：

需要考虑：

* 数据隐私
* 企业协议

如果非常敏感：

以后可以：

本地 embedding + API LLM。

---

# 六、我建议你分三个阶段实现

不要一开始搞 Agent。

---

## Phase 1（现在）

建立知识库：

```
Markdown
+
MkDocs
+
Git
```

你已经完成80%。

---

## Phase 2

加入搜索：

实现：

```
问：

FP8有哪些问题？

答：

从你的文档中找到相关内容
```

这是 RAG。

---

## Phase 3

高级Agent：

增加：

```
自动阅读论文

自动生成研究报告

自动发现gap

自动提出idea
```

---

# 七、结合你的研究方向，我认为最适合的AI助手人格

不要做：

“万能聊天机器人”。

应该定义：

```
AI Research Partner
```

Prompt：

```
You are my research assistant.

My research fields:
- AI accelerator
- neural network compression
- quantization
- computer architecture

Your tasks:

1. Organize my knowledge.
2. Identify missing connections.
3. Suggest research directions.
4. Challenge my assumptions.
5. Compare with latest literature.
```

---

# 八、一个很有潜力的扩展

你的 Wiki + AI 可以形成：

```
Personal Research OS
```

每天：

自动：

```
arXiv
 |
 |
AI筛选
 |
 |
与你知识库匹配
 |
 |
生成：

"Today you should read these 3 papers"
```

例如：

每天早上：

```
Good morning.

Based on your work on FP8 accelerator:

New papers:

1. Adaptive Precision LLM Accelerator
Similarity: 92%

Potential impact:
High

Suggested question:
Can your FQT method extend to this?
```

这个非常适合你的研究模式。

---

# 我的建议（结合你现在已经搭好的环境）

你的路线：

```
阶段1:
MkDocs + Git
        ↓
阶段2:
Private/Public Wiki
        ↓
阶段3:
RAG AI Assistant
        ↓
阶段4:
Research Agent
        ↓
阶段5:
自动科研情报系统
```

不要急着做 AI Agent。

你现在最重要的是：

**把知识结构化。**

因为 AI 的能力上限，很大程度取决于你的知识库质量。

以你目前的方向（AI硬件、量化、芯片架构），这个系统如果持续维护 2~3 年，价值会远超过单纯记笔记。它会逐渐变成一个“第二大脑”。



这其实是一个非常重要的信息。你现在不是“从零搭知识库”，而是已经有了一个**6年的科研资产库**。这会改变设计思路。

你的 Overleaf 笔记、论文草稿、实验记录、LaTeX 文档，本质上已经是一个成熟的科研知识系统，只是它目前是：

* 面向写作（paper-oriented）
* 面向项目（project-oriented）
* 存储格式偏 LaTeX
* 知识之间的连接弱

而 MkDocs + AI 的目标是：

* 面向知识（knowledge-oriented）
* 面向复用（reuse-oriented）
* Markdown 化
* 可检索、可推理

所以最合理的路线不是替代 Overleaf，而是：

> **Overleaf 继续负责“科研生产”，MkDocs 负责“知识沉淀”，AI 负责“连接二者”。**

---

## 1. 推荐你的最终科研知识架构

我建议设计成三层：

```
                 Research OS


        ┌───────────────────┐
        │   Writing Layer    │
        │                    │
        │  Overleaf / LaTeX  │
        │  Papers            │
        │  Patents           │
        │  Proposals         │
        └─────────┬─────────┘
                  │
                  │ extract knowledge
                  ↓

        ┌───────────────────┐
        │ Knowledge Layer    │
        │                    │
        │ MkDocs Wiki        │
        │ Markdown           │
        │ Concepts           │
        │ Methods            │
        │ Experiments        │
        └─────────┬─────────┘
                  │
                  │ RAG
                  ↓

        ┌───────────────────┐
        │ AI Research Agent  │
        │                    │
        │ Search             │
        │ Summarize          │
        │ Connect ideas      │
        │ Find gaps          │
        └───────────────────┘

```

---

# 2. Overleaf 不应该直接作为 Wiki

很多科研人员会犯一个错误：

把：

```
paper.tex
```

直接变成知识库。

问题：

LaTeX 文档通常包含：

* 引言
* 相关工作
* 方法
* 实验

但是知识结构不是这样。

例如你的论文：

```
FQT-II
```

里面可能包含：

* Quantization
* FPGA implementation
* Hardware architecture
* Training optimization

这些知识点会散落在不同章节。

未来 AI 很难理解：

“这个方法和三年前某个实验有什么关系”。

---

# 3. 正确方式：建立知识抽取层

例如：

你的 Overleaf：

```
papers/

├── FQT-II/
│
│   main.tex
│   fig/
│   bib/
│
├── FP8/
│
└── Accelerator/
```

不要动。

新增：

```
research-wiki-private/

docs/

├── concepts/
│
├── methods/
│
├── experiments/
│
├── ideas/
│
└── papers/
```

---

例如：

你的论文：

```
FQT-II.tex
```

对应：

Wiki：

```
methods/

quantization/

FQT-II.md
```

里面：

```markdown
# FQT-II

## Motivation

为什么提出？

## Key Idea

核心创新：

## Relation

相关方法：

- LSQ
- DoReFa
- FP8


## Hardware Impact

面积：

功耗：

性能：


## Future Extension

可能方向：
```

这个才是知识资产。

---

# 4. 你的6年笔记怎么迁移？

不要一次性迁移。

建议分三批。

## 第一批：高价值内容

例如：

你的：

* 博士论文
* 已发表论文
* 核心算法
* 关键实验

优先整理。

例如：

```
博士论文
    |
    |
    ↓

Wiki

AI Accelerator
 ├── Quantization
 ├── Architecture
 └── Memory System

```

---

## 第二批：论文阅读笔记

你可能有：

```
paper1.tex
paper2.tex
paper3.tex
```

转换：

```
papers/

├── GPTQ.md
├── SmoothQuant.md
├── AWQ.md
```

---

## 第三批：碎片笔记

例如：

```
2021 idea.tex

2022 experiment.tex

old_notes.tex
```

这些不要人工整理。

直接：

AI：

```
总结：

1. 已完成工作
2. 未解决问题
3. 潜在idea
```

---

# 5. LaTeX 如何进入 AI 知识库？

这里其实很方便。

你的 `.tex`：

经过：

```
pandoc
```

转换：

```
.tex

↓

.md
```

例如：

```bash
pandoc paper.tex -o paper.md
```

然后：

AI整理。

但是注意：

不要直接发布转换结果。

转换结果只是：

```
raw knowledge
```

需要 AI 二次整理。

---

# 6. Git 怎么管理 Overleaf？

我建议：

不要依赖 Overleaf Git。

自己统一管理：

```
research/

├── papers/
│
│   ├── latex/
│
├── wiki/
│
├── experiments/
│
└── scripts/

```

例如：

```
research
│
├── papers
│   └── FQT-II
│       ├── main.tex
│       └── reference.bib
│
├── wiki
│   └── quantization
│       └── FQT-II.md
│
└── data

```

这样：

论文和知识关联。

---

# 7. 你的 AI 助手未来可以做非常有价值的事情

例如问：

> 我2019-2026年关于低比特计算做过哪些工作？有哪些演化路线？

AI 可以回答：

```
2019:

FPGA inference acceleration

2021:

INT8 quantization


2023:

Mixed precision


2025:

FP8/FQT-II


Evolution:

reduce memory
      ↓
reduce computation
      ↓
hardware-aware optimization


Potential next step:

adaptive precision accelerator
```

这个能力普通文献管理软件做不到。

---

# 8. 我甚至建议你加入一个“研究时间轴”

你的 Wiki 可以有：

```
timeline.md
```

例如：

```
2019
 |
 FPGA CNN Accelerator

2021
 |
 Quantization

2023
 |
 Transformer Accelerator

2025
 |
 FP8

2026
 |
 AI Research OS
```

AI 非常容易基于时间线发现：

“你的研究自然演化方向”。

---

# 9. 你现在的优势其实很明显

很多人开始 AI 知识管理时：

```
没有历史数据
```

所以 AI 没东西可学习。

而你：

* 6年笔记
* 博士论文
* 实验记录
* 代码
* LaTeX
* 论文阅读

这些都是高质量科研数据。

你的任务不是“记录”。

而是：

> **把已有6年的科研积累重新组织成机器可以理解的知识图谱。**

---

我觉得你的下一步非常值得做：

**先设计 Private Wiki 的目录结构，并考虑如何接入你已有的 Overleaf。**

因为 Public Wiki 是展示层，而 Private Wiki 才是你的真正科研大脑。你目前最大的资产其实在那里。


结合你的背景（AI accelerator + quantization + 博士论文积累），我不建议按“日期”组织，也不建议按“论文”组织。

最好的方式是：

主题作为第一层，论文作为第二层，语言作为第三层。

因为未来 AI 最容易理解这种结构。你实际上是在搭建一个“科研知识图谱”的第一步。


对，这里恰好是 **MkDocs 最容易让人第一次困惑的地方**。

一句话先说清楚：

> **`mkdocs serve` 和 `mkdocs build` 是两种完全不同的运行方式。正式部署时通常只需要 `mkdocs build`，不需要 `mkdocs serve`。HTTP 响应由 Caddy/Nginx 这样的 Web 服务器负责。**

你可以把它理解成：

```text
你写 Markdown
     │
     ▼
  mkdocs build
     │
     ▼
生成一堆 HTML/CSS/JS/图片
     │
     ▼
site/
     │
     ▼
Caddy
     │
     ▼
浏览器
```

---

# 1. `mkdocs serve` 到底是什么？

当你执行：

```bash
mkdocs serve
```

实际上 MkDocs 做了两件事情：

```text
Markdown
   ↓
实时生成网页
   ↓
启动一个临时 HTTP Server
   ↓
127.0.0.1:8000
```

所以你看到：

```text
INFO    -  Building documentation...
INFO    -  Documentation built in 0.XX seconds
INFO    -  [14:30:00] Watching paths for changes: 'docs', 'mkdocs.yml'
INFO    -  Serving on http://127.0.0.1:8000/
```

这里的：

```text
Serving on :8000
```

就是 MkDocs 自己在提供 HTTP 服务。

因此：

```text
mkdocs serve
```

实际上是：

**编译 + HTTP服务器 + 自动重新编译**

非常适合你写 Wiki 的时候使用。

---

# 2. `mkdocs build` 完全不一样

执行：

```bash
mkdocs build
```

它只做：

```text
docs/*.md
    ↓
Markdown解析
    ↓
HTML
    ↓
site/
```

例如：

```text
~/public-wiki/

├── mkdocs.yml
├── docs/
│   ├── index.md
│   ├── quantization.md
│   └── xray.md
│
└── site/
    ├── index.html
    ├── quantization/
    │   └── index.html
    ├── xray/
    │   └── index.html
    ├── assets/
    ├── stylesheets/
    └── javascript/
```

**到这里 MkDocs 的工作就结束了。**

它不会监听任何端口。

---

# 3. 那么谁负责 HTTP？

就是你之前已经在使用的：

**Caddy。**

这才是正式网站的正确架构。

比如：

```text
浏览器
   │
   │ HTTP/HTTPS
   ▼
Caddy :80 / :443
   │
   │ 静态文件
   ▼
/home/ice/public-wiki/site/
```

Caddy收到：

```http
GET /quantization/
```

然后直接从：

```text
site/quantization/index.html
```

读取文件并返回。

**整个过程根本不需要 MkDocs。**

---

# 4. 这也是为什么静态网站特别适合你的 VPS

你的 VPS 只有：

```text
1 CPU
512 MB RAM
```

如果你运行：

```bash
mkdocs serve
```

那么：

```text
Python
MkDocs
Markdown解析器
文件监控
HTTP server
```

都一直运行着。

没必要。

而正式网站：

```text
Caddy
   ↓
HTML
CSS
JS
图片
```

几乎不需要什么 CPU 和内存。

这对你的 512 MB VPS **非常合适**。

---

# 5. 你的正式部署应该这样

假设：

```text
~/public-wiki/
```

里面：

```text
mkdocs.yml
docs/
```

先：

```bash
cd ~/public-wiki
```

然后：

```bash
mkdocs build
```

生成：

```text
~/public-wiki/site/
```

然后 Caddy：

```text
你的IP
  ↓
Caddy
  ↓
~/public-wiki/site/
```

例如 Caddyfile 可以写成：

```caddyfile
你的IP {
    root * /home/ice/public-wiki/site
    file_server
}
```

然后：

```bash
sudo systemctl restart caddy
```

浏览器访问：

```text
http://你的IP
```

就可以看到 MkDocs 网站。

---

# 6. 以后修改 Markdown 怎么办？

这才是你真正关心的地方。

比如你修改：

```text
docs/zh/concepts/quantization.md
```

然后：

```bash
mkdocs build
```

MkDocs重新生成：

```text
site/
```

Caddy不需要改变。

因为 Caddy 永远只是：

> **把 `site/` 目录里的文件发送给浏览器。**

所以流程就是：

```text
修改 Markdown
      ↓
git commit
      ↓
mkdocs build
      ↓
site/更新
      ↓
Caddy自动提供新网页
```

**不需要重启 Caddy。**

---

# 7. 那 `mkdocs serve` 什么时候用？

你平时写东西的时候。

比如你正在修改：

```text
docs/zh/concepts/quantization.md
```

执行：

```bash
mkdocs serve
```

然后电脑浏览器打开：

```text
http://127.0.0.1:8000
```

你修改 Markdown：

```text
保存
 ↓
MkDocs检测到文件变化
 ↓
自动重新build
 ↓
刷新浏览器
```

这就是它最大的价值。

---

# 8. 你甚至可以在 VPS 上这样工作

如果你不想每次：

```bash
mkdocs build
```

那么开发阶段：

```bash
mkdocs serve --dev-addr 0.0.0.0:8000
```

然后：

```text
浏览器
   ↓
VPS:8000
   ↓
MkDocs serve
   ↓
docs/
```

但是**正式网站不要这么做**。

---

# 9. 你的最终架构应该是

你现在实际上已经有了一个非常漂亮的架构：

```text
                    VPS
                     │
        ┌────────────┴────────────┐
        │                         │
     Caddy                     Xray
     :80/:443                  :443
        │
        │
        ▼
  Static Website
        │
        ▼
 public-wiki/site/
        ▲
        │
   mkdocs build
        ▲
        │
     docs/*.md
```

其中：

**MkDocs = 编译器**

**Caddy = Web服务器**

**Markdown = 源代码**

**HTML = 编译产物**

这和你写程序其实非常类似：

```text
main.c
   ↓
gcc
   ↓
program
   ↓
运行
```

MkDocs：

```text
index.md
   ↓
mkdocs build
   ↓
index.html
   ↓
Caddy
   ↓
浏览器
```

所以你问的这个问题，本质上就是：

> **“如果编译器退出了，程序为什么还能运行？”**

答案是：**MkDocs已经把网站“编译”成静态文件了，运行网站的是 Caddy，不是 MkDocs。**

而对于你的 **512MB VPS**，我非常建议正式部署就采用这种方式。



对，**你的判断很可能是对的**。这不是 MkDocs 的问题，而是 Linux 的文件权限问题。

Caddy 通常不是以 `ice` 用户运行，而是以 `caddy` 用户运行。因此：

```text
/home/ice/my-docs/site
```

即使 `ice` 自己可以访问，`caddy` 未必有权限进入 `/home/ice`。

### 先确认 Caddy 用户

执行：

```bash
ps aux | grep caddy
```

或者：

```bash
systemctl cat caddy | grep -E 'User|Group'
```

通常会看到：

```text
User=caddy
Group=caddy
```

---

## 最简单、也最推荐你的解决方案

**不要把正式网站放在 `/home/ice` 下面。**

把 MkDocs 的 `site` 放到专门的 Web 目录，例如：

```text
/var/www/my-docs/
```

然后：

```bash
sudo mkdir -p /var/www/my-docs
```

把生成的网站复制过去：

```bash
sudo cp -r ~/my-docs/site/* /var/www/my-docs/
```

然后：

```bash
sudo chown -R caddy:caddy /var/www/my-docs
```

Caddy：

```caddyfile
http://174.138.46.11 {
    root * /var/www/my-docs
    file_server
}
```

然后检查配置：

```bash
sudo caddy validate --config /etc/caddy/Caddyfile
```

如果显示：

```text
Valid configuration
```

再：

```bash
sudo systemctl restart caddy
```

---

## 但是你还有一个更好的选择

实际上**不需要让 Caddy 拥有网站文件的所有权**。

更合理的是：

```text
ice       → 管理/生成网站
caddy     → 只读网站
```

也就是说：

```text
~/my-docs/
     │
     ├── docs/       ← ice 修改
     │
     ├── mkdocs.yml  ← ice 修改
     │
     └── site/       ← mkdocs build生成
```

然后把 `site` 的权限设置成：

```text
ice   → read/write
caddy → read
```

这样安全性更好。

不过由于 `/home/ice` 本身可能限制 `caddy` 进入，所以最干净的架构仍然是：

```text
/home/ice/my-docs/
        │
        │ mkdocs build
        ↓
/var/www/my-docs/
        │
        ↓
      Caddy
```

也就是：

> **源代码放 `/home/ice`，编译产物放 `/var/www`。**

这其实非常符合 Linux 服务器的习惯。

---

### 你的最终工作流就会变成

平时：

```bash
cd ~/my-docs
```

修改：

```text
docs/
```

然后：

```bash
mkdocs build
```

再：

```bash
sudo rm -rf /var/www/my-docs/*
sudo cp -r site/* /var/www/my-docs/
```

Caddy **完全不用重启**。

甚至以后我们可以给你写一个小脚本：

```bash
./deploy.sh
```

自动完成：

```text
修改 Markdown
     ↓
mkdocs build
     ↓
复制 site
     ↓
完成
```

这样你以后更新 Wiki 就只需要一条命令。



可以。既然我们已经确定了你的结构是 **语言 → 主题**，我建议不要一开始把 `mkdocs.yml` 搞得太复杂。先做一个稳定的基础版本，之后再加搜索、语言切换、Git、AI 等功能。

不过有一点需要先纠正：**如果你使用 `zh/` 和 `en/` 两套完整目录，Material 本身不会自动把它们理解成语言版本。** 如果希望真正实现语言切换，最好使用 `mkdocs-static-i18n` 插件。

## 1. 先给你一个可以直接用的版本

你的目录：

```text
my-docs/
├── mkdocs.yml
└── docs/
    ├── zh/
    │   ├── index.md
    │   ├── concepts/
    │   │   ├── quantization.md
    │   │   └── accelerator.md
    │   ├── methods/
    │   └── papers/
    │
    └── en/
        ├── index.md
        ├── concepts/
        │   ├── quantization.md
        │   └── accelerator.md
        ├── methods/
        └── papers/
```

那么 `mkdocs.yml` 可以先写：

```yaml
site_name: Research Wiki
site_description: Personal Research Knowledge Base
site_author: ICE

theme:
  name: material

  language: zh

  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.highlight
    - search.share

plugins:
  - search

markdown_extensions:
  - admonition
  - attr_list
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight
  - pymdownx.arithmatex:
      generic: true

extra:
  alternate:
    - name: 中文
      link: /zh/
      lang: zh
    - name: English
      link: /en/
      lang: en
```

但是这里有一个问题：

**上面的 `extra.alternate` 只是告诉 Material 有两个语言入口，并不会自动帮你维护两套文档之间的对应关系。**

所以如果你希望顶部出现真正漂亮的语言切换，我建议安装插件。

---

# 2. 安装多语言插件

在你的虚拟环境中：

```bash
pip install mkdocs-static-i18n
```

然后 `mkdocs.yml`：

```yaml
site_name: Research Wiki
site_description: Personal Research Knowledge Base
site_author: ICE

theme:
  name: material

  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.highlight
    - search.share

plugins:
  - search
  - i18n:
      docs_structure: folder

      languages:
        - locale: zh
          name: 中文
          default: true
          build: true

        - locale: en
          name: English
          build: true

markdown_extensions:
  - admonition
  - attr_list
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight

  - pymdownx.arithmatex:
      generic: true
```

这时候你的目录：

```text
docs/
├── zh/
└── en/
```

就被插件理解成两个语言版本。

---

# 3. 但是这里有一个非常重要的问题

你现在这个结构：

```text
zh/
    concepts/
        quantization.md

en/
    concepts/
        quantization.md
```

实际上要求：

```text
zh/concepts/quantization.md
```

和：

```text
en/concepts/quantization.md
```

**路径保持完全对应。**

这恰恰非常适合你前面说的：

> 中文写 → AI翻译 → 英文

比如你以后让 AI 做一个脚本：

```text
扫描 docs/zh/
        ↓
找到所有 md
        ↓
判断 en/ 是否存在
        ↓
不存在 → 翻译
存在 → 判断中文是否更新
        ↓
更新英文
```

这会非常舒服。

---

# 4. 导航栏怎么办？

这里也要注意。

我建议你**不要在 `mkdocs.yml` 里把所有文章写死**。

例如不要一开始写：

```yaml
nav:
  - Home:
      - ...
      - ...
      - ...
```

因为你未来可能有几百篇文章。

让 MkDocs 根据目录自动生成导航更加适合你的 Wiki。

因此先不要写 `nav:`。

目录本身：

```text
zh/
├── index.md
├── concepts/
├── methods/
└── papers/
```

就自然对应：

```text
Concepts
Methods
Papers
```

以后文章增加：

```text
concepts/
├── quantization.md
├── transformer.md
├── sparsity.md
├── pruning.md
└── distillation.md
```

不用修改 `mkdocs.yml`。

---

# 5. 我尤其建议你开启数学公式

因为你的 Wiki 是科研 Wiki，而不是普通博客。

你以后肯定会写：

```latex
Q(x) = \operatorname{round}\left(\frac{x}{s}\right)
```

所以：

```yaml
markdown_extensions:
  - pymdownx.arithmatex:
      generic: true
```

然后再给 Material 配 MathJax。

例如：

```yaml
extra_javascript:
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
```

这样 Markdown 里面可以直接：

```markdown
$$
Q(x)=\operatorname{round}\left(\frac{x}{s}\right)
$$
```

---

# 6. 我给你一个更完整的最终版

如果这是我帮你搭你的科研 Wiki，我现在会直接用这个：

```yaml
site_name: Research Wiki
site_description: Personal Research Knowledge Base
site_author: ICE

theme:
  name: material

  language: zh

  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - navigation.tracking

    - search.suggest
    - search.highlight
    - search.share

    - content.code.copy
    - content.code.annotate

plugins:
  - search

  - i18n:
      docs_structure: folder

      languages:
        - locale: zh
          name: 中文
          default: true
          build: true

        - locale: en
          name: English
          build: true

markdown_extensions:

  - admonition
  - attr_list

  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight

  - pymdownx.tabbed:
      alternate_style: true

  - pymdownx.arithmatex:
      generic: true

extra_javascript:
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js

extra:

  alternate:
    - name: 中文
      link: /zh/
      lang: zh

    - name: English
      link: /en/
      lang: en

copyright: "© 2026 ICE"
```

---

## 7. 你现在可以先不要急着部署

我建议你现在在 VPS 上测试：

```bash
cd ~/my-docs

mkdocs build --strict
```

如果没有错误：

```bash
mkdocs serve
```

然后浏览器打开：

```text
http://你的VPS-IP:8000
```

看看：

```text
Research Wiki

中文
English

Concepts
Methods
Papers
```

是不是你想要的效果。

**等这个版本跑通以后，我们再处理 Caddy。**

而且我建议下一步就做一个很重要的东西：**把你的 `mkdocs.yml` + `docs/zh` + `docs/en` + Caddy + Git 整理成一个完整的“科研 Wiki 工程模板”**。这样你以后只需要往 `zh/` 里面扔 Markdown，整个网站、英文翻译、Git 版本管理都可以逐渐自动化。



这个问题非常关键。实际上，**MkDocs 并不是通过你在 `yml` 里写某个规则来“识别” `index.md` 的**，而是它有一个约定：

> **每个目录下的 `index.md` 默认就是这个目录对应的首页。**

不过你现在的双语目录结构需要稍微区分一下。

### 1. 普通 MkDocs

例如：

```text
docs/
├── index.md
├── quantization.md
└── xray.md
```

MkDocs 会自动把：

```text
docs/index.md
```

作为网站首页：

```text
/
```

而：

```text
docs/quantization.md
```

对应：

```text
/quantization/
```

---

### 2. 你的双语结构

你现在是：

```text
docs/
├── zh/
│   ├── index.md
│   ├── concepts/
│   │   └── quantization.md
│   └── papers/
│       └── gptq.md
│
└── en/
    ├── index.md
    ├── concepts/
    │   └── quantization.md
    └── papers/
        └── gptq.md
```

这里：

```text
zh/index.md
```

对应中文首页：

```text
/zh/
```

而：

```text
en/index.md
```

对应英文首页：

```text
/en/
```

这个行为是 **MkDocs + 目录结构 + i18n 插件**共同决定的，不需要你在 `mkdocs.yml` 里面写：

```yaml
nav:
  - 首页: index.md
```

---

### 3. `index.md`还有一个很重要的特点

假设：

```text
docs/zh/concepts/index.md
```

那么它就是：

```text
/zh/concepts/
```

的首页。

所以你可以利用这个特性建立非常漂亮的层级：

```text
docs/
└── zh/
    ├── index.md
    │
    ├── concepts/
    │   ├── index.md
    │   ├── quantization.md
    │   └── transformer.md
    │
    ├── methods/
    │   ├── index.md
    │   ├── fqt.md
    │   └── qat.md
    │
    └── papers/
        ├── index.md
        ├── gptq.md
        └── awq.md
```

最终网站就可以形成：

```text
Research Wiki
│
├── Concepts
│   ├── Quantization
│   └── Transformer
│
├── Methods
│   ├── FQT
│   └── QAT
│
└── Papers
    ├── GPTQ
    └── AWQ
```

其中：

```text
/zh/              → zh/index.md
/zh/concepts/     → zh/concepts/index.md
/zh/methods/      → zh/methods/index.md
/zh/papers/       → zh/papers/index.md
```

---

### 4. 但我要纠正我上一条回答中的一个地方

我上一条给你的：

```yaml
extra:
  alternate:
    - name: 中文
      link: /zh/
      lang: zh
    - name: English
      link: /en/
      lang: en
```

**不能单独实现完整的双语文档切换。**

它只是 Material 的语言切换配置，并不会自动把：

```text
zh/concepts/quantization.md
```

和：

```text
en/concepts/quantization.md
```

关联起来。

你既然明确希望以后：

> 中文 → AI 翻译 → 英文

那么我们最好把 `mkdocs-static-i18n` 的配置单独设计好，而不是把几个配置项混在一起。

---

### 5. 还有一个问题：你现在未必需要 i18n 插件

其实按照你目前的需求，我反而建议你**先不用 `mkdocs-static-i18n`**。

因为你现在最核心的需求是：

```text
中文 Wiki
   +
英文 Wiki
   +
两个目录严格镜像
```

完全可以先做到：

```text
docs/
├── zh/
│   └── index.md
└── en/
    └── index.md
```

然后把它们当作两个普通的 MkDocs 页面体系。

等你真正需要：

> “在中文页面点击 English，自动跳到对应英文页面”

的时候，再加入 i18n。

这样你的系统会简单很多。

---

**所以目前最重要的结论是：**

```text
mkdocs.yml
     │
     └── 不需要告诉 MkDocs index.md 是首页
                             
index.md
     │
     └── MkDocs 的目录约定自动识别
```

你可以把 `index.md` 理解成 Web 开发里面的：

```text
index.html
```

**放在哪里，哪个目录就以它作为默认首页。**



可以。现在我们把架构定死为：

```text
/        → Caddy 重定向到 /zh/
/zh/     → 中文 Wiki
/en/     → English Wiki
```

并且：

```text
/zh/concepts/quantization/
/en/concepts/quantization/
```

是一对对应的页面。

不过我建议你**先不要急着上 i18n 插件**。因为你现在的目标是先把 Wiki 跑稳定；双语切换可以用 Material 的语言选择功能逐步完善。否则一开始很容易陷入插件配置问题。

---

# 一、目录结构

你的项目：

```text
~/my-docs/
├── mkdocs.yml
└── docs/
    ├── zh/
    │   ├── index.md
    │   ├── concepts/
    │   │   ├── index.md
    │   │   ├── quantization.md
    │   │   └── transformer.md
    │   ├── methods/
    │   │   ├── index.md
    │   │   └── fqt.md
    │   └── papers/
    │       ├── index.md
    │       ├── gptq.md
    │       └── awq.md
    │
    └── en/
        ├── index.md
        ├── concepts/
        │   ├── index.md
        │   ├── quantization.md
        │   └── transformer.md
        ├── methods/
        │   ├── index.md
        │   └── fqt.md
        └── papers/
            ├── index.md
            ├── gptq.md
            └── awq.md
```

---

# 二、我建议你现在使用的 `mkdocs.yml`

直接把 `/home/ice/my-docs/mkdocs.yml` 改成：

```yaml
site_name: Research Wiki
site_description: Personal Research Knowledge Base
site_author: ICE

theme:
  name: material

  # Material 界面语言
  language: zh

  features:

    # 导航
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - navigation.tracking

    # 搜索
    - search.suggest
    - search.highlight
    - search.share

    # Markdown
    - content.code.copy
    - content.code.annotate

plugins:
  - search

markdown_extensions:

  # 基础 Markdown 扩展
  - admonition
  - attr_list

  # 折叠内容
  - pymdownx.details

  # 更强的代码块
  - pymdownx.superfences

  # 代码高亮
  - pymdownx.highlight

  # Tab
  - pymdownx.tabbed:
      alternate_style: true

  # 数学公式
  - pymdownx.arithmatex:
      generic: true

# MathJax
extra_javascript:
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js

# 网站信息
extra:
  generator: false

copyright: "© 2026 ICE"
```

这个版本**不包含 i18n 插件**。

原因是我想让你先把最基础的 Wiki 跑起来。

---

# 三、但是这里有一个关键问题

上面的 `mkdocs.yml` 并不会自动把：

```text
zh/
en/
```

变成两个语言站点。

MkDocs 本身看到的只是：

```text
docs/
├── zh/
└── en/
```

两个普通目录。

所以你运行：

```bash
mkdocs serve
```

之后，页面结构会是：

```text
/zh/
/en/
```

这没问题。

但是**Material 顶部不会自动出现“中文 / English”的语言切换按钮**。

如果你希望：

```text
中文 Wiki
        ↓
右上角 English
        ↓
对应英文页面
```

我们需要真正加入多语言插件。

---

# 四、因此，如果你现在就要完整实现双语切换

我更推荐下面这个版本。

先安装：

```bash
pip install mkdocs-static-i18n
```

然后 `mkdocs.yml`：

```yaml
site_name: Research Wiki
site_description: Personal Research Knowledge Base
site_author: ICE

theme:
  name: material

  language: zh

  features:

    # -------------------------
    # Navigation
    # -------------------------
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - navigation.tracking

    # -------------------------
    # Search
    # -------------------------
    - search.suggest
    - search.highlight
    - search.share

    # -------------------------
    # Content
    # -------------------------
    - content.code.copy
    - content.code.annotate


# ============================================================
# Plugins
# ============================================================

plugins:

  # 普通搜索
  - search

  # 中英文
  - i18n:
      docs_structure: folder

      languages:

        # -------------------------
        # Chinese
        # -------------------------
        - locale: zh
          name: 中文
          default: true
          build: true

        # -------------------------
        # English
        # -------------------------
        - locale: en
          name: English
          build: true


# ============================================================
# Markdown Extensions
# ============================================================

markdown_extensions:

  # 基础
  - admonition
  - attr_list

  # 折叠
  - pymdownx.details

  # SuperFences
  - pymdownx.superfences

  # Syntax highlighting
  - pymdownx.highlight

  # Tabs
  - pymdownx.tabbed:
      alternate_style: true

  # 数学公式
  - pymdownx.arithmatex:
      generic: true


# ============================================================
# MathJax
# ============================================================

extra_javascript:

  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js


# ============================================================
# Other
# ============================================================

extra:
  generator: false

copyright: "© 2026 ICE"
```

**如果你已经安装了 `mkdocs-static-i18n`，我建议直接使用这个版本。**

---

# 五、然后 Caddy 负责默认进入中文

你的 Caddy：

```caddyfile
http://174.138.46.11 {

    @root path /
    redir @root /zh/ 302

    root * /var/www/my-docs
    file_server
}
```

于是：

```text
http://174.138.46.11
```

自动：

```text
/
 ↓
/zh/
 ↓
zh/index.md
```

---

# 六、最终你的网站逻辑

最终结构非常清晰：

```text
                       VPS
                        │
                        ▼
                      Caddy
                        │
              ┌─────────┴─────────┐
              │                   │
              ▼                   ▼
             /zh/                /en/
              │                   │
              ▼                   ▼
       中文 Wiki             English Wiki
              │                   │
              └─────────┬─────────┘
                        │
                  对应页面切换
                        │
                        ▼
       zh/papers/gptq.md
                ↕
       en/papers/gptq.md
```

而你的日常工作流就是：

```text
修改中文 Markdown
        ↓
        Git
        ↓
     AI 翻译
        ↓
英文 Markdown
        ↓
   mkdocs build
        ↓
      Caddy
        ↓
      网站
```

这套架构非常适合你前面说的**“中文作为主创作语言，AI 自动维护英文版本”**。

---

### 一个小提醒

你之前的 Caddy 已经遇到过 `443` 被 Xray 占用的问题，所以这里继续使用：

```caddyfile
http://174.138.46.11
```

**不要写 `https://174.138.46.11`**，否则 Caddy 会尝试监听 443，又会和 Xray 冲突。

等你的 Wiki 结构和双语切换完全跑通后，再考虑是否需要给它套 HTTPS。



对，**很有可能不是 Python 3.8 vs 3.13 本身导致的，而是你两台机器上的 `mkdocs` / `mkdocs-material` / YAML 解析相关依赖版本不同**。

尤其你这里已经确认：

* 开发机：Python 3.8 + `mkdocs-static-i18n 0.4.6`
* 部署机：Python 3.13 + `mkdocs-static-i18n 0.4.6`

但出现：

> 一台要求 `languages` 是 list
> 另一台要求 `languages` 是 dict

这种情况，**首先怀疑依赖栈不一致，而不是 Python 版本。**

---

## 1. 为什么同一个 i18n 版本还会不一样？

因为：

```bash
pip install mkdocs-static-i18n==0.4.6
```

只锁定了这个插件。

但它依赖的：

```text
MkDocs
PyYAML
mkdocs-material
其他依赖
```

可能完全不同。

例如：

```text
开发机

Python 3.8
├── mkdocs 1.x
├── mkdocs-static-i18n 0.4.6
├── PyYAML x.x
└── mkdocs-material x.x


部署机

Python 3.13
├── mkdocs 2.x
├── mkdocs-static-i18n 0.4.6
├── PyYAML y.y
└── mkdocs-material y.y
```

于是同一个：

```yaml
languages:
```

可能被不同版本的插件/框架按照不同 schema 解释。

---

# 2. 你现在最应该做的事情

**不要猜。**

在开发机和部署机分别执行：

```bash
python --version
```

```bash
mkdocs --version
```

然后：

```bash
pip show mkdocs
pip show mkdocs-static-i18n
pip show mkdocs-material
pip show PyYAML
```

更推荐直接：

```bash
pip freeze | sort
```

两台机器各执行一次。

---

# 3. 最关键的是比较 `mkdocs`

我尤其怀疑你两边的：

```bash
mkdocs --version
```

不一样。

因为 `mkdocs-static-i18n` 0.4.6 并不意味着整个运行环境就是一样的。

例如如果开发机：

```text
mkdocs 1.x
```

而部署机：

```text
mkdocs 2.x
```

那么插件兼容性就非常值得怀疑。

---

# 4. Python 3.8 → 3.13 本身不是最优先怀疑对象

你的情况不是：

> Python 3.8 可以解析 YAML，Python 3.13 不可以。

而是：

> **同一个插件版本，对同一个配置结构要求不同。**

这种情况更像：

```text
插件
  ↓
MkDocs API
  ↓
依赖版本
  ↓
配置 schema / validation
```

发生了兼容性差异。

Python 版本可能是**间接原因**：

```text
Python 3.13
    ↓
pip 安装了更新的 MkDocs / 依赖
    ↓
与 Python 3.8 环境不同
    ↓
最终行为不同
```

而不是 Python 自己改变了 YAML 的 list/dict 语义。

---

# 5. 还有一个非常重要的事情

你前面贴的配置：

```yaml
languages:

  - locale: zh
    name: 中文
    default: true
    build: true

  - locale: en
    name: English
    build: true
```

这里：

```yaml
languages:
  - ...
  - ...
```

**明确是 YAML list。**

如果你的某台机器报错类似：

```text
languages must be a mapping/dict
```

那就意味着**你当前安装的那个 i18n 插件版本所期待的配置格式并不是这个格式**。

所以不要为了迁就部署机，把：

```yaml
languages:
  - locale: zh
    ...
```

随便改成 dict。

我们应该先确定：

> **你安装的到底是哪一个 i18n 插件，以及它的配置 schema 到底是什么。**

---

# 6. 我还注意到一个可能的问题

你说的是：

> `mkdocs-i18n 0.4.6`

但我们之前讨论的是：

> `mkdocs-static-i18n`

这两个**不是一个名字**。

请你在两台机器执行：

```bash
pip list | grep -i i18n
```

看看究竟是：

```text
mkdocs-static-i18n
```

还是：

```text
mkdocs-i18n
```

或者两个都有。

这非常重要。

---

## 我建议你现在不要继续修改 YAML

直接把**开发机和部署机下面这几条命令的输出分别贴给我**：

```bash
python --version
mkdocs --version
pip list | grep -Ei "mkdocs|i18n|yaml|material"
```

我可以直接帮你把两个环境逐项对比。

**大概率我们最后会发现不是 Python 3.8/3.13 的问题，而是 MkDocs 或 i18n 插件实际版本/插件名称不一致。**

而且一旦确认版本，我可以给你一个**确定能在两台机器保持一致的 `requirements.txt`**，以后你开发机和 VPS 都：

```bash
pip install -r requirements.txt
```

就不会再出现“我的电脑能跑，VPS不能跑”的问题。



这下问题已经**完全定位了**。不是 Python 3.8 vs 3.13，也不是 PyYAML。

你的两个环境实际上装的是**两个不同的 i18n 插件**。

| 组件       | 开发机               | 部署机                            |
| -------- | ----------------- | ------------------------------ |
| Python   | 3.8               | 3.12                           |
| MkDocs   | 1.6.1             | 1.6.1                          |
| Material | 9.7.7             | 9.7.7                          |
| PyYAML   | 6.0.3             | 6.0.3                          |
| **i18n** | **`mkdocs-i18n`** | **`mkdocs-static-i18n` 1.3.1** |

所以你之前遇到的：

> 一台要求 `languages` 是 list，另一台要求 `languages` 是 dict

**根本原因就是插件不同。**

---

# 关键区别

你开发机：

```text
mkdocs-i18n
```

部署机：

```text
mkdocs-static-i18n
```

而我们之前讨论的：

```yaml
plugins:
  - i18n:
      docs_structure: folder
      languages:
        ...
```

实际上对应的是**某一个特定插件的配置格式**，不能把两个插件混用。

---

# 我建议你现在统一使用 `mkdocs-static-i18n`

原因很简单：

你现在的目标就是：

```text
docs/
├── zh/
│   ├── index.md
│   └── ...
└── en/
    ├── index.md
    └── ...
```

也就是你一直强调的：

> **语言 → 主题**

而 `mkdocs-static-i18n` 就是专门针对这种**静态翻译 Markdown 文件**的方案。

你部署机已经安装：

```text
mkdocs-static-i18n 1.3.1
```

所以我建议**不要再折腾 Python 版本**。

---

# 但是现在要注意一个地方

你当前 `mkdocs.yml` 里面写的是：

```yaml
- i18n:
    docs_structure: folder

    languages:

      - locale: zh
        name: 中文
        default: true
        build: true

      - locale: en
        name: English
        build: true
```

这是我们之前针对另一个插件讨论的配置。

对于你现在确定使用的：

```text
mkdocs-static-i18n 1.3.1
```

**配置格式需要按照这个插件的 schema 来写。**

不要再拿 `mkdocs-i18n` 的配置格式来试。

---

# 另外一个非常重要的发现

你开发机虽然：

```bash
pip show mkdocs-static-i18n
```

显示不存在：

```text
WARNING: Package(s) not found
```

但：

```bash
pip show mkdocs
```

却显示：

```text
Required-by: ... mkdocs-i18n
```

所以开发机真正运行的是：

```text
mkdocs-i18n
```

不是：

```text
mkdocs-static-i18n
```

---

# 最干净的解决方案

我建议你现在**把开发机也统一成部署机的环境**。

开发机：

```bash
pip uninstall mkdocs-i18n
```

然后：

```bash
pip install mkdocs-static-i18n==1.3.1
```

然后检查：

```bash
pip list | grep -Ei "mkdocs|i18n"
```

最好最终两台机器都是：

```text
mkdocs                  1.6.1
mkdocs-material         9.7.7
mkdocs-static-i18n      1.3.1
PyYAML                  6.0.3
```

这样我们就不用再怀疑环境差异。

---

## Python 3.8 要不要升级？

**暂时不用。**

你现在开发机：

```text
Python 3.8
MkDocs 1.6.1
Material 9.7.7
```

既然这些都已经能正常安装运行，就没有必要为了这个问题升级 Python。

真正需要统一的是：

```text
插件
```

而不是：

```text
Python
```

---

# 最后还有一个问题需要修正

你之前看到：

```text
site/
├── HPC/
│   └── benchmark/
│       └── index.html
```

而没有：

```text
site/zh/
```

现在我们知道为什么了：

**你部署机使用的是 `mkdocs-static-i18n`，它的默认语言构建策略和我们之前假设的行为有关。**

所以接下来我们不要再猜。

---

### 你现在先做一件事

在**两台机器都统一成 `mkdocs-static-i18n 1.3.1`以后**，把你现在的：

```yaml
plugins:
```

部分贴给我。

我会严格按照 **`mkdocs-static-i18n 1.3.1` 的配置格式**给你整理一次。

然后我们再解决：

```text
docs/
   ↓
mkdocs build
   ↓
site/
   ↓
Caddy
   ↓
/
```

到底应该是什么 URL 结构。

**这次根因已经找到了，不需要再从 Python、Caddy、权限这些方向绕了。**



