# Digital Ocean

DigitalOcean Droplet 本质上是一台海外 VPS。如果你的目的是让自己的设备通过这台服务器访问互联网（例如在受限网络环境下访问外部网站），技术上属于搭建个人代理/VPN 通道。下面可以介绍常见方案和配置思路。
如果只是你自己使用，我建议：首选 WireGuard
原因：

Linux 内核支持
性能接近裸网络
手机/电脑客户端成熟
配置文件简单
不需要复杂的代理协议


| 方案          | 特点                  | 推荐    |
| ----------- | ------------------- | ----- |
| WireGuard   | 现代 VPN，速度快，延迟低，配置简单 | ★★★★★ |
| OpenVPN     | 成熟稳定，兼容性好，但速度略慢     | ★★★★  |
| Shadowsocks | 轻量代理，生态丰富           | ★★★★  |
| Xray/V2Ray  | 功能复杂，可做多种代理协议       | ★★★★  |

你买的 DigitalOcean Droplet 本质上是一台海外 VPS。**如果你的目的是让自己的设备通过这台服务器访问互联网（例如在受限网络环境下访问外部网站），技术上属于搭建个人代理/VPN 通道**。我可以介绍常见方案和配置思路。

不过先说明一点：不同地区对代理/VPN 的使用有不同法律和服务条款要求，你需要确保用途符合你所在地法律以及 DigitalOcean 的 Acceptable Use Policy。

---

## 方案选择（按推荐程度）

目前个人使用，常见有下面几种：

| 方案          | 特点                  | 推荐    |
| ----------- | ------------------- | ----- |
| WireGuard   | 现代 VPN，速度快，延迟低，配置简单 | ★★★★★ |
| OpenVPN     | 成熟稳定，兼容性好，但速度略慢     | ★★★★  |
| Shadowsocks | 轻量代理，生态丰富           | ★★★★  |
| Xray/V2Ray  | 功能复杂，可做多种代理协议       | ★★★★  |

如果只是你自己使用，我建议：

> **首选 WireGuard**

原因：

* Linux 内核支持
* 性能接近裸网络
* 手机/电脑客户端成熟
* 配置文件简单
* 不需要复杂的代理协议

---

# 方案一：WireGuard 搭建个人 VPN

假设：

你的 Droplet：

```
Ubuntu 22.04
公网 IP:
xxx.xxx.xxx.xxx
```

你的本地：

```
Windows / macOS / Linux / Android / iOS
```

---

## 1. 登录服务器

SSH：

```bash
ssh root@你的服务器IP
```

更新：

```bash
apt update
apt upgrade -y
```

---

## 2. 安装 WireGuard

服务器：

```bash
apt install wireguard -y
```

检查：

```bash
wg --version
```

---

## 3. 生成密钥

服务器：

```bash
cd /etc/wireguard

wg genkey | tee server_private.key | wg pubkey > server_public.key
```

查看：

```bash
cat server_private.key
cat server_public.key
```

例如：

```
server_private:
abcxxxxxxxx

server_public:
xyzxxxxxxxx
```

---

## 4. 配置服务器

创建：

```bash
nano /etc/wireguard/wg0.conf
```

写入：

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = 服务器私钥

PostUp = sysctl -w net.ipv4.ip_forward=1

```

开启 IP 转发：

编辑：

```bash
nano /etc/sysctl.conf
```

加入：

```
net.ipv4.ip_forward=1
```

执行：

```bash
sysctl -p
```

---

## 5. 配置 NAT

查看网卡：

```bash
ip a
```

通常 DigitalOcean 是：

```
eth0
```

安装 iptables：

```bash
apt install iptables -y
```

添加：

```bash
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

保存：

```bash
apt install iptables-persistent
```

---

## 6. 启动 WireGuard

```bash
systemctl enable wg-quick@wg0

systemctl start wg-quick@wg0
```

查看：

```bash
wg
```

应该看到：

```
interface: wg0
listening port: 51820
```

---

# 本地客户端配置

## Windows / macOS

安装：

WireGuard 官方客户端：

[https://www.wireguard.com/install/](https://www.wireguard.com/install/)

创建：

```
client.conf
```

内容：

```ini
[Interface]

PrivateKey = 客户端私钥

Address = 10.0.0.2/24


DNS = 1.1.1.1



[Peer]

PublicKey = 服务器公钥

Endpoint = 你的服务器IP:51820

AllowedIPs = 0.0.0.0/0

PersistentKeepalive = 25
```

导入 WireGuard。

---

# 服务器添加客户端

服务器：

```bash
nano /etc/wireguard/wg0.conf
```

增加：

```ini
[Peer]

PublicKey = 客户端公钥

AllowedIPs = 10.0.0.2/32
```

重启：

```bash
systemctl restart wg-quick@wg0
```

---

# DigitalOcean 防火墙

如果你启用了 DigitalOcean Cloud Firewall，需要开放：

```
UDP
51820
0.0.0.0/0
```

否则客户端连不上。

---

# 测试

客户端连接后：

访问：

```
https://ipinfo.io
```

应该显示：

```
DigitalOcean IP
```

说明流量已经经过 VPS。

---

# 方案二：如果你只是想代理浏览器流量

那么 WireGuard 可能过重，可以使用：

* SOCKS5
* Shadowsocks

例如：

```
浏览器
 ↓
代理插件
 ↓
Droplet
 ↓
Internet
```

这种只代理浏览器，不影响系统。

---

# 我建议你的配置

你的情况：

> 已经购买 DigitalOcean Droplet，自己使用

推荐：

```
Ubuntu 22.04
+
WireGuard
+
手机客户端 WireGuard App
+
电脑客户端 WireGuard
```

这是目前最简单、性能最好、维护成本最低的方案。

如果你告诉我：

1. Droplet 系统版本（Ubuntu 20.04/22.04/24.04？）
2. 你的本地系统（Windows/macOS/Linux/iPhone/Android）
3. 你希望是「全局 VPN」还是「浏览器代理」

我可以给你一套完全对应的配置文件。



是的，**WireGuard 客户端本质上就是一个 VPN 软件**。

更准确地说：

* **WireGuard 是一种 VPN 协议**
* **WireGuard 客户端**是安装在你电脑/手机上的 VPN 应用
* 你的 DigitalOcean Droplet 运行 WireGuard 服务端
* 两者建立一条加密隧道（VPN tunnel）

结构大概是：

```
你的电脑
(Windows/macOS/Linux)
        |
        |  加密 VPN 隧道
        |
        ↓
WireGuard 客户端
        |
        |
     Internet
        |
        ↓
DigitalOcean Droplet
(WireGuard Server)
        |
        ↓
公网网站
```

连接以后：

```
网站看到的 IP
        ↓
DigitalOcean VPS 的 IP

而不是

你本地网络的 IP
```

---

## WireGuard 客户端长什么样？

例如 Windows：

安装后会有一个程序：

```
WireGuard
 ├── Add Tunnel
 ├── Activate
 └── Deactivate
```

界面非常简单：

```
+ Add Tunnel

[ My DigitalOcean VPN ]

     OFF / ON
```

打开开关即可。

---

## 它和普通 VPN 软件有什么区别？

比如你可能见过：

* NordVPN
* ExpressVPN
* Surfshark

这些是：

```
VPN 软件
     |
     |
VPN 公司服务器
```

你租用的是别人提供的节点。

而 WireGuard：

```
WireGuard客户端
       |
       |
你自己的 DigitalOcean服务器
```

服务器完全属于你。

---

## WireGuard 和传统 VPN 的区别

|     | 商业VPN     | WireGuard自建   |
| --- | --------- | ------------- |
| 服务器 | 别人提供      | 你自己的Droplet   |
| 速度  | 多人共享      | 独享            |
| 隐私  | 需要信任VPN公司 | 自己控制          |
| 价格  | 每月几十元     | Droplet约$5/月起 |
| 配置  | 简单        | 需要自己搭建        |
| 性能  | 一般        | 非常高           |

---

## 安装以后，你电脑上的网络会发生什么？

例如：

没有 WireGuard：

```
你的电脑
 ↓
本地运营商
 ↓
网站
```

网站看到：

```
你的本地IP
```

---

打开 WireGuard：

```
你的电脑
 ↓
加密隧道
 ↓
DigitalOcean
 ↓
网站
```

网站看到：

```
DigitalOcean服务器IP
```

---

## 一个重要区别：WireGuard ≠ 代理软件

很多人容易混淆：

### WireGuard

属于：

```
VPN
```

特点：

* 全系统流量走隧道
* 浏览器、微信、SSH、软件更新等都经过 VPN

---

### Shadowsocks / SOCKS5

属于：

```
代理
```

特点：

只代理指定程序：

```
Chrome
   ↓
代理

微信
   ↓
不用代理
```

---

如果你的目标是：

### 1. 在电脑和手机上都使用

例如：

* 浏览器
* AI 工具
* GitHub
* 软件更新

那么：

> WireGuard 更合适。

### 2. 只想让浏览器走服务器

那么：

> Shadowsocks + 浏览器代理插件更轻。

---

另外提醒一个实际问题：DigitalOcean 的普通 Droplet 默认没有做抗封锁优化，它就是一台普通云服务器。WireGuard 是正常的企业/个人 VPN 技术，但某些网络环境可能会对 VPN 流量进行限制。部署前最好确认你的使用场景和当地网络规则。

如果你告诉我你的电脑是 **Windows 还是 macOS**，我可以给你具体的客户端安装和导入步骤。



可以。**在同一个 DigitalOcean Droplet 上同时安装 WireGuard 和 Xray/Shadowsocks 是完全可行的**，而且这是很多人实际会采用的架构。

它们之间通常不会冲突，因为：

* WireGuard 是 **VPN 隧道协议**
* Xray/Shadowsocks 是 **代理服务**
* 它们监听不同端口、使用不同网络接口

例如：

```
                Internet
                   |
                   |
          DigitalOcean Droplet
                   |
      +------------+------------+
      |                         |
  WireGuard                 Xray/SS
  UDP 51820                 TCP 443
      |                         |
 VPN tunnel              Proxy tunnel
      |                         |
 你的电脑                 Clash客户端
```

---

## 一个 Droplet 同时运行的典型配置

### 1. WireGuard

监听：

```
UDP 51820
```

用途：

* 手机全局 VPN
* 笔记本全局 VPN
* SSH 到内网机器
* 访问服务器内部资源

配置：

```
wg0
 |
10.0.0.1/24
```

---

### 2. Xray

监听：

```
TCP 443
```

用途：

* Clash
* 浏览器代理
* 按规则分流

例如：

```
VLESS
 |
TLS
 |
Xray
```

---

### 3. Shadowsocks（如果需要）

例如：

```
TCP 8388
```

用途：

* 兼容老客户端
* 某些设备快速接入

---

## 会不会影响速度？

一般不会。

你的 Droplet：

例如：

```
2 vCPU
4GB RAM
```

同时运行：

```
WireGuard
+
Xray
```

资源占用通常非常低：

| 服务        | CPU | 内存   |
| --------- | --- | ---- |
| WireGuard | 接近0 | 几MB  |
| Xray      | 很低  | 几十MB |
| SS        | 很低  | 几十MB |

真正限制通常是：

* Droplet 带宽
* VPS 到目标网站的网络质量
* DigitalOcean 出口限制

而不是 CPU。

---

## 一个需要注意的问题：端口规划

不要让两个服务抢同一个端口。

例如：

| 服务          | 协议      | 端口    |
| ----------- | ------- | ----- |
| SSH         | TCP     | 22    |
| Xray        | TCP     | 443   |
| WireGuard   | UDP     | 51820 |
| Shadowsocks | TCP/UDP | 8388  |

这样即可。

---

## 防火墙设置

Droplet 如果启用了 DigitalOcean Firewall，需要：

开放：

```
TCP 22      SSH
TCP 443     Xray
UDP 51820   WireGuard
```

例如：

```
Inbound Rules

SSH       TCP 22
HTTPS     TCP 443
Custom    UDP 51820
```

---

## 电脑端可以同时装 WireGuard 和 Clash 吗？

可以。

例如：

### 平时：

```
Clash ON
```

用于：

* 浏览器
* AI工具
* GitHub
* 软件更新

### 需要全局：

```
WireGuard ON
```

用于：

* 整机 VPN
* 手机
* 特殊网络环境

甚至：

```
WireGuard + Clash
```

同时开启也可以，但通常没必要。

---

## 我个人更推荐的架构

如果你已经买了 Droplet，我会这样设计：

```
DigitalOcean Droplet
|
|-- WireGuard
|      UDP 51820
|
|-- Xray
       TCP 443
       |
       VLESS
       |
       Clash Verge Rev
```

原因：

* WireGuard 提供稳定 VPN 能力
* Xray 提供灵活代理能力
* 两套互为备用
* 一个出问题另一个还能用

---

不过有一个实际问题需要确认：

你的 Droplet 是哪个区域（Region）？

例如：

* 美国 San Francisco
* New York
* Singapore
* Frankfurt
* Bangalore

以及你主要在哪个地区使用？

因为**服务器位置对延迟、丢包率和可用性影响非常大**。如果你告诉我 Droplet 的区域和你的客户端系统（Windows/macOS/iPhone），我可以建议 WireGuard + Xray 的具体部署方式。


这是一个很好的问题。这里最容易混淆的是：**WireGuard 里面有两套 IP 地址体系**。

你看到的：

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = 服务器私钥
```

这里的 `Address` **不是你的 DigitalOcean 公网 IP**，而是 WireGuard 创建的**虚拟内网地址**。

---

## 1. Address 应该填什么？

保持：

```ini
Address = 10.0.0.1/24
```

即可。

不要填写你的 Droplet 公网 IP。

例如你的 Droplet：

```
公网 IP:
167.xxx.xxx.xxx
```

那么：

```
DigitalOcean 网卡:
eth0 = 167.xxx.xxx.xxx
```

而 WireGuard 会创建一个虚拟网卡：

```
wg0 = 10.0.0.1
```

关系：

```
                 Internet

                    |
                    |
        167.xxx.xxx.xxx
        DigitalOcean eth0
                    |
             WireGuard
                    |
              wg0
        10.0.0.1/24
```

---

你的客户端：

例如你的电脑：

```
10.0.0.2
```

手机：

```
10.0.0.3
```

于是形成：

```
WireGuard虚拟网络:

服务器:
10.0.0.1

电脑:
10.0.0.2

手机:
10.0.0.3
```

这个网段你可以自己定义，例如：

```
10.10.0.1/24
```

也可以：

```
192.168.50.1/24
```

但是：

```text
10.0.0.1/24
```

是最常用的。

---

## 2. PrivateKey 从哪里来？

是的，就是：

```bash
cat server_private.key
```

得到的内容。

例如：

执行：

```bash
cat /etc/wireguard/server_private.key
```

输出：

```
abc123456789xxxxxxxxxxxxx=
```

那么配置：

```ini
PrivateKey = abc123456789xxxxxxxxxxxxx=
```

注意：

不要写：

```
PrivateKey = server_private.key
```

也不要写：

```
PrivateKey = /etc/wireguard/server_private.key
```

而是写**文件里面那一长串字符**。

---

## 3. 那公网 IP 放哪里？

公网 IP 不写在 `wg0.conf`。

它出现在客户端配置：

例如你的电脑：

```ini
[Peer]

PublicKey = 服务器公钥

Endpoint = 167.xxx.xxx.xxx:51820
```

这里：

```
Endpoint
```

才是你的 DigitalOcean IP。

---

## 4. 完整服务器配置应该类似这样

假设：

服务器私钥：

```
SERVER_PRIVATE_KEY
```

那么：

`/etc/wireguard/wg0.conf`

应该：

```ini
[Interface]

Address = 10.0.0.1/24

ListenPort = 51820

PrivateKey = SERVER_PRIVATE_KEY


PostUp = sysctl -w net.ipv4.ip_forward=1
```

---

## 5. 客户端对应：

电脑：

```ini
[Interface]

Address = 10.0.0.2/24

PrivateKey = CLIENT_PRIVATE_KEY


[Peer]

PublicKey = SERVER_PUBLIC_KEY

Endpoint = 你的Droplet公网IP:51820

AllowedIPs = 0.0.0.0/0

PersistentKeepalive = 25
```

对应关系：

| 设备                | IP       |
| ----------------- | -------- |
| Droplet WireGuard | 10.0.0.1 |
| 电脑                | 10.0.0.2 |
| 手机                | 10.0.0.3 |

---

## 6. 还有一个小问题：你的 PostUp

你看到：

```ini
PostUp = sysctl -w net.ipv4.ip_forward=1
```

这个只是打开 Linux 转发功能。

不过实际完整配置通常还需要 NAT，例如：

```ini
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

否则：

* 电脑可以连接 WireGuard
* 但是访问不了公网

这是很多第一次搭 WireGuard 最容易漏掉的地方。

---

所以总结：

你的三个问题：

1. **Address = 10.0.0.1/24 保持，不填服务器公网 IP。** ✅
2. **PrivateKey = `cat server_private.key` 输出的内容。** ✅
3. **服务器公网 IP 写在客户端的 Endpoint。** ✅

你现在做到生成密钥这一步的话，下一步就是配置 `wg0.conf` 和 NAT。我建议你先执行：

```bash
ip a
```

看一下你的公网网卡名字是不是 `eth0`，因为 NAT 那一步需要用它。不同 DigitalOcean 镜像有时可能叫 `ens3`。








你说的 **“Fable 5 / ChatGPT 转发”**，我理解你想做的是：

```
你的客户端
    |
    | API 请求
    |
你的 Droplet
    |
    | 转发/代理
    |
OpenAI API / Anthropic API
```

也就是搭建一个 **AI API Reverse Proxy（反向代理）**。

这个和前面的：

* WireGuard（网络层代理）
* Xray（代理协议）

不是一类东西。

这里处理的是：

> HTTP API 请求转发、API Key 管理、模型路由。

类似：

```
Claude Code
OpenAI SDK
Cursor
Continue
自研程序

        ↓

      你的 VPS

        ↓

 OpenAI API
 Anthropic API
```

---

## 首先区分三种需求

### 需求 1：只是让 ChatGPT 网页版走 Droplet

例如：

```
chat.openai.com
claude.ai
```

这种：

不用做 API 转发。

你前面的：

```
WireGuard
或者
Clash
```

就够了。

---

### 需求 2：你有 OpenAI / Anthropic API Key，想隐藏 Key

例如：

你的程序：

```python
client = OpenAI(
    base_url="https://你的服务器/v1"
)
```

服务器：

```
你的服务器
    |
    |
OpenAI API
```

这种就是标准 API Proxy。

---

### 需求 3：想统一管理多个模型

例如：

客户端：

```
model=gpt-5
```

服务器：

自动转：

```
OpenAI GPT-5
```

或者：

```
model=claude-fable-5
```

转：

```
Anthropic API
```

这种一般用：

* LiteLLM
* One API
* New API
* 自己写 FastAPI Gateway

---

# 我最推荐你的方案：LiteLLM Proxy

因为你明显是开发用途。

架构：

```
                Claude Code
                     |
                OpenAI SDK
                     |
                     |
              LiteLLM Proxy
              (你的Droplet)
                     |
       +-------------+-------------+
       |                           |
 OpenAI API                 Anthropic API
       |                           |
 GPT-5                     Fable 5
```

LiteLLM 支持把不同厂商 API 统一成 OpenAI 格式。([GOST][1])

---

# 一、安装 Docker

你的 Ubuntu：

```bash
apt update

apt install docker.io docker-compose -y
```

检查：

```bash
docker --version
```

---

# 二、安装 LiteLLM

创建目录：

```bash
mkdir ~/litellm

cd ~/litellm
```

创建：

```bash
nano docker-compose.yml
```

内容：

```yaml
version: "3.9"

services:

  litellm:

    image: ghcr.io/berriai/litellm:main-latest

    ports:
      - "4000:4000"

    environment:

      OPENAI_API_KEY: sk-your-openai-key

      ANTHROPIC_API_KEY: sk-ant-your-key


    command:
      - "--config"
      - "/app/config.yaml"
```

---

# 三、创建配置文件

```bash
nano config.yaml
```

写：

```yaml
model_list:

  - model_name: gpt-5

    litellm_params:

      model: openai/gpt-5

      api_key: os.environ/OPENAI_API_KEY



  - model_name: fable-5

    litellm_params:

      model: anthropic/claude-fable-5

      api_key: os.environ/ANTHROPIC_API_KEY



general_settings:

  master_key: sk-your-proxy-password
```

---

# 四、启动

```bash
docker compose up -d
```

查看：

```bash
docker ps
```

应该：

```
litellm
0.0.0.0:4000
```

---

# 五、测试

你的服务器：

```
http://你的IP:4000
```

API:

```
http://你的IP:4000/v1/chat/completions
```

---

例如：

Python：

```python
from openai import OpenAI


client = OpenAI(

    api_key="sk-your-proxy-password",

    base_url="http://你的服务器IP:4000/v1"

)


response = client.chat.completions.create(

    model="gpt-5",

    messages=[
        {
            "role":"user",
            "content":"hello"
        }
    ]

)

print(response)
```

---

# 六、生产环境建议

不要直接：

```
http://IP:4000
```

应该：

```
https://ai.xxx.com
```

架构：

```
                 HTTPS

                  |
              Nginx

                  |

             LiteLLM:4000

                  |

       OpenAI / Anthropic
```

安装：

```bash
apt install nginx certbot python3-certbot-nginx
```

申请：

```
Let's Encrypt SSL
```

---

# 七、如果你的目标是 Fable 5 + ChatGPT 混合

我建议：

```
Clash Verge
       |
       |
网络代理
       |
       |
AI API Proxy
       |
       |
+-------------+
|             |
GPT-5     Fable 5
```

甚至可以：

你的程序：

```python
model="best"
```

服务器：

根据任务：

```
代码:
  GPT-5

长文本:
  Fable 5

推理:
  GPT-5
```

自动路由。

---

## 结合你现在的环境，我建议最终架构：

你的 Droplet：

```
Ubuntu
 |
 +-- WireGuard
 |
 +-- Xray
 |
 +-- LiteLLM Proxy
 |
 +-- Nginx HTTPS
```

用途：

| 服务        | 用途         |
| --------- | ---------- |
| WireGuard | 全局 VPN     |
| Xray      | Clash 网络代理 |
| LiteLLM   | AI API 转发  |
| Nginx     | 统一 HTTPS入口 |

这台 Droplet 就变成你的个人 AI Gateway。

---

不过有一个关键问题需要确认：

你说的 **“Fable 5”** 是指：

1. **Anthropic API 里的 Claude Fable 5 模型**（API 调用）
   还是
2. **Claude Code / Claude 客户端里面的 Fable 5 使用转发**？

这两个实现完全不同。

如果是 **Claude Code + Fable 5 转发**，通常需要做 **Anthropic API 兼容代理**，配置会和上面的 OpenAI 兼容代理略有区别。([Reddit][2])

你告诉我你的客户端是什么：

* Claude Code？
* Cursor？
* Continue？
* 自己 Python 程序？
* ChatGPT 网页？

我可以给你对应架构。

[1]: https://www.gost.run/en/blog/2026/llm-router/?utm_source=chatgpt.com "Smart LLM API Routing with GOST Reverse Proxy - GOST"
[2]: https://www.reddit.com/r/ClaudeAI/comments/1vkhuzh/how_do_you_use_gpt_models_within_claude_code/?utm_source=chatgpt.com "How do you use GPT models within Claude Code?"


