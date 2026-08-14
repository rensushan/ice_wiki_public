你选择的是 **Windows 上配置 WireGuard 客户端（GUI 方式）**。下面按你的场景一步一步来。

假设：

* Droplet 已经安装 WireGuard
* 服务器端：

  * WireGuard 地址：`10.0.0.1`
  * 监听端口：`51820`
* 你的 Windows 电脑作为客户端：

  * WireGuard 地址：`10.0.0.2`

---

## 第一步：安装 Windows WireGuard 客户端

下载并安装官方客户端：

[https://www.wireguard.com/install/](https://www.wireguard.com/install/)

安装后打开：

```
WireGuard
```

---

## 第二步：生成客户端密钥

打开 WireGuard 主界面：

点击：

```
Add Tunnel
        ↓
Add empty tunnel...
```

你会看到类似：

```
[Interface]

PrivateKey = 
PublicKey =
```

点击：

```
Generate Keypair
```

WireGuard 会自动生成：

```
PrivateKey
PublicKey
```

例如：

```
PrivateKey = abcxxxxxxxx=
PublicKey  = xyzxxxxxxxx=
```

---

## 第三步：填写客户端配置

假设生成：

```
客户端私钥:
CLIENT_PRIVATE_KEY

客户端公钥:
CLIENT_PUBLIC_KEY
```

Windows 配置：

```ini
[Interface]

PrivateKey = CLIENT_PRIVATE_KEY

Address = 10.0.0.2/24


[Peer]

PublicKey = SERVER_PUBLIC_KEY

Endpoint = 你的Droplet公网IP:51820

AllowedIPs = 0.0.0.0/0

PersistentKeepalive = 25
```

解释：

### Interface 部分

这是你的电脑身份：

```ini
PrivateKey = CLIENT_PRIVATE_KEY
```

必须是：

> Windows WireGuard 生成的私钥

```ini
Address = 10.0.0.2/24
```

表示：

你的电脑在 VPN 网络中的地址。

---

### Peer 部分

这里填写服务器：

```ini
PublicKey = SERVER_PUBLIC_KEY
```

这个来自：

服务器：

```bash
cat /etc/wireguard/server_public.key
```

例如：

```
xxxxxxxxxxxx=
```

复制进去。

---

## 第四步：把客户端公钥告诉服务器

现在你有：

Windows：

```
PublicKey = CLIENT_PUBLIC_KEY
```

复制它。

登录 Droplet：

```bash
nano /etc/wireguard/wg0.conf
```

增加：

```ini
[Peer]

PublicKey = CLIENT_PUBLIC_KEY

AllowedIPs = 10.0.0.2/32
```

例如：

```ini
[Peer]

PublicKey = abcdefg123456=

AllowedIPs = 10.0.0.2/32
```

保存。

---

## 第五步：重启服务器 WireGuard

服务器：

```bash
systemctl restart wg-quick@wg0
```

检查：

```bash
wg
```

应该看到：

```
interface: wg0
listening port: 51820

peer:
    public key: 客户端公钥
```

---

## 第六步：Windows 开启 VPN

回到 WireGuard：

点击：

```
Activate
```

如果成功：

状态：

```
Active
```

---

## 第七步：测试连接

服务器：

执行：

```bash
wg
```

正常情况下：

会出现：

```
latest handshake: 10 seconds ago
transfer:
```

例如：

```
peer:
    endpoint: xxx.xxx.xxx.xxx
    latest handshake: 15 seconds ago
```

说明：

✅ Windows 已连接 Droplet。

---

## 一个非常容易漏的地方：DigitalOcean 防火墙

如果你启用了 DigitalOcean Firewall，需要开放：

```
UDP 51820
```

否则：

Windows 会一直显示：

```
Activating...
```

但是没有 handshake。

---

## 你现在应该有 4 个关键东西：

| 位置      | 内容                 |
| ------- | ------------------ |
| 服务器     | server_private.key |
| 服务器     | server_public.key  |
| Windows | client_private.key |
| Windows | client_public.key  |

关系：

```
服务器配置:
PrivateKey = server_private
Peer PublicKey = client_public


Windows配置:
PrivateKey = client_private
Peer PublicKey = server_public
```

---

建议你下一步先不要急着开 NAT。

先完成：

1. Windows 生成密钥
2. Droplet 添加 `[Peer]`
3. 双方启动
4. `wg` 看 handshake

**只要 handshake 成功，说明 WireGuard 隧道已经建立。**

然后再配置 NAT，让电脑通过 Droplet 出口访问互联网。



可以，而且**如果你现在是 WireGuard 已经能连通，但明显很慢，先不要急着换 Xray/Clash**。WireGuard 本身通常很快，慢往往是下面几个环节的问题。

我们可以很快定位到底是**服务器出口慢、线路慢、MTU 不合适，还是 DNS/IPv6 问题**。

### 先做一个最简单的检查

在你的 **Windows 电脑**上，打开 PowerShell，执行：

```powershell
ping 10.0.0.1
```

然后再：

```powershell
ping 1.1.1.1
```

把结果贴给我。

同时在 Droplet 上执行：

```bash
curl -4 https://speed.cloudflare.com/__down?bytes=10000000 -o /dev/null
```

以及：

```bash
curl -4 https://www.google.com -o /dev/null -w "%{time_connect} %{time_starttransfer}\n"
```

如果第二个很快、下载速度也正常，而 Windows 经过 WireGuard 很慢，问题大概率在 **WireGuard 配置/MTU/NAT**。

---

### 另外一个非常值得先检查的东西：MTU

你的 WireGuard 客户端配置目前可能是：

```ini
[Interface]
PrivateKey = ...
Address = 10.0.0.2/24
```

可以尝试加：

```ini
MTU = 1380
```

例如：

```ini
[Interface]
PrivateKey = ...
Address = 10.0.0.2/24
MTU = 1380
```

然后重新 Activate。

如果没有改善，可以进一步测试：

```text
1420
1400
1380
1360
```

**不要一次改很多东西**，否则很难判断到底是什么造成改善。

---

### 还有一个很重要的区别

你说的是：

> 「可以翻墙，但是很慢」

如果你的意思是：

```text
WireGuard
   ↓
Google / YouTube / ChatGPT 等海外网站
```

访问很慢，那么**最值得怀疑的是 DigitalOcean Droplet 所在区域与你当前网络之间的线路质量**。

这时候即使：

```text
WireGuard
↓
服务器
```

本身没有问题，服务器到海外网站也没问题，**你 → DigitalOcean 这一段线路丢包/延迟高，整体仍然会很慢。**

---

### 你可以先告诉我这三个结果

**Windows：**

```powershell
ping 10.0.0.1
ping 1.1.1.1
```

**服务器：**

```bash
curl -4 https://speed.cloudflare.com/__down?bytes=10000000 -o /dev/null
```

另外告诉我：

> **你的 DigitalOcean Droplet 是哪个 Region？**

例如 `Singapore`、`San Francisco`、`New York`、`Frankfurt` 等。

有了这几个数据，我基本可以判断是**服务器带宽、线路、MTU，还是 WireGuard 配置**导致的，而不是盲目让你换软件。


你现在其实已经完成了一半：**你的电脑 → Droplet 的 WireGuard 隧道已经建立**。

你说的“把我的请求通过 Droplet 中转转发”，本质上有两种不同需求，我先区分一下，因为实现方式不同。

---

## 方案 A：全局流量都经过 Droplet（你现在的 WireGuard 方向）

目标：

```
你的电脑
   |
   | WireGuard
   |
Droplet
   |
   |
Internet
```

也就是：

* 浏览器
* GitHub
* 软件更新
* 所有 TCP/UDP 流量

都从 Droplet 出口。

你现在只差 **服务器开启转发 + NAT**。

---

## 方案 B：像 Clash 一样，只让部分请求走 Droplet

目标：

```
Chrome
   |
Clash
   |
代理协议
   |
Droplet
   |
Internet


国内网站
   |
直连
```

这个需要：

* Xray
* Shadowsocks
* SOCKS5
* HTTP Proxy

WireGuard 不擅长规则分流。

---

你现在已经有 WireGuard，所以我先讲 **方案 A：让 WireGuard 成为完整出口 VPN**。

---

# 第一步：确认服务器开启 IP 转发

Droplet：

```bash
sudo sysctl net.ipv4.ip_forward
```

应该看到：

```
net.ipv4.ip_forward = 1
```

如果是：

```
=0
```

执行：

```bash
sudo nano /etc/sysctl.conf
```

加入：

```ini
net.ipv4.ip_forward=1
```

然后：

```bash
sudo sysctl -p
```

---

# 第二步：配置 NAT

你的 WireGuard：

```
wg0
10.0.0.1
```

你的公网出口：

通常：

```
eth0
```

确认：

```bash
ip route
```

应该类似：

```
default via xxx dev eth0
```

然后：

```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

意思：

```
10.0.0.x
    |
    |
转换成
    |
Droplet公网IP
```

---

# 第三步：修改 wg0.conf

服务器：

```bash
sudo nano /etc/wireguard/wg0.conf
```

改成：

```ini
[Interface]

Address = 10.0.0.1/24

ListenPort = 51820

PrivateKey = 服务器私钥


PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -A FORWARD -o wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


PostDown = iptables -D FORWARD -i wg0 -j ACCEPT
PostDown = iptables -D FORWARD -o wg0 -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```

保存。

重启：

```bash
sudo systemctl restart wg-quick@wg0
```

---

# 第四步：修改 Windows WireGuard 配置

你的客户端：

```ini
[Interface]

PrivateKey = 客户端私钥

Address = 10.0.0.2/24


[Peer]

PublicKey = 服务器公钥

Endpoint = 174.138.46.11:51820


AllowedIPs = 0.0.0.0/0


PersistentKeepalive = 25
```

关键是：

```ini
AllowedIPs = 0.0.0.0/0
```

这个意思：

> 所有 IPv4 流量都送给 WireGuard。

---

# 第五步：测试

打开 WireGuard。

访问：

```
https://ipinfo.io
```

如果成功：

显示：

```
DigitalOcean
New York
```

而不是你的本地运营商。

---

# 但是！你现在有一个更大的问题

你的测试显示：

```
你 → NYC Droplet
225ms
```

所以即使配置正确：

```
电脑
 |
225ms
 |
NYC
 |
网站
```

体验仍然会慢。

---

## 如果你的真正目标是：

> “我想让请求经过海外服务器，然后访问国外网站”

更合理的架构是：

```
你的电脑
    |
    |
亚洲 VPS
    |
    |
国外网站
```

比如：

```
Singapore
Tokyo
Seoul
```

通常比：

```
中国 → New York
```

体验好很多。

---

## 另外，你之前提到 Clash

如果你最终想达到：

```
Chrome → Clash → Droplet → Internet
```

而不是：

```
整个电脑 → VPN
```

那么下一步应该安装：

```
Xray
+
VLESS
+
Clash Verge
```

而不是继续折腾 WireGuard。

---

所以我建议你先确认一个问题：

你说的“请求通过 Droplet 中转”具体想要哪一种？

**A. 整台电脑所有流量经过 Droplet（类似 VPN）**

还是

**B. 像 Clash 一样，只让指定网站/软件经过 Droplet？**

如果是 B，我建议直接转 Xray/Clash 架构。你现在的 WireGuard 可以保留作为备用。





你现在的情况比较适合从 **WireGuard 切换到 Xray + Clash Verge Rev**：

* WireGuard：全局 VPN，简单，但你现在 NYC 延迟 225ms，体验不佳。
* Xray + Clash：代理模式，可以：

  * 规则分流（国内直连、国外代理）
  * 多节点切换
  * 更适合日常浏览和开发环境

下面给你一套**从零开始 DigitalOcean Ubuntu Droplet → Xray(VLESS+Reality) → Clash Verge Rev** 的完整流程。

> 说明：Xray 是一个开源代理核心，官方项目提供安装脚本和示例配置。([GitHub][1])
> 下面采用目前较常见的 **VLESS + TCP + Reality** 架构。

---

# 总体架构

最终：

```
Windows/macOS
      |
      |
Clash Verge Rev
      |
      |
VLESS + Reality
      |
      |
Xray Server
      |
      |
DigitalOcean Droplet
      |
      |
Internet
```

---

# 一、服务器准备

假设：

你的 Droplet:

```
Ubuntu 22.04
IP:
174.138.46.11
```

登录：

```bash
ssh root@174.138.46.11
```

更新：

```bash
apt update
apt upgrade -y
```

安装工具：

```bash
apt install curl wget unzip uuid-runtime -y
```

---

# 二、安装 Xray

使用官方安装脚本：

```bash
bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
```

安装完成检查：

```bash
xray version
```

应该看到：

```
Xray 1.x.x
```

---

# 三、生成 UUID

VLESS 使用 UUID 作为用户身份。

执行：

```bash
uuidgen
```

例如：

```
8f2c1d30-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

保存。

后面叫：

```
UUID
```

---

# 四、生成 Reality 密钥

执行：

```bash
xray x25519
```

输出：

类似：

```
Private key:
xxxxxxxxxxxxxxxx

Public key:
yyyyyyyyyyyyyyyy
```

保存：

服务器：

```
PRIVATE_KEY
```

客户端：

```
PUBLIC_KEY
```

---

# 五、选择 Reality 伪装网站

Reality 需要一个真实 TLS 网站。

例如：

```
www.microsoft.com
```

或者：

```
www.apple.com
```

要求：

* HTTPS
* TLS 1.3
* 稳定

---

# 六、生成 shortId

执行：

```bash
openssl rand -hex 8
```

例如：

```
a1b2c3d4e5f67890
```

保存：

```
SHORT_ID
```

---

# 七、配置 Xray

打开：

```bash
nano /usr/local/etc/xray/config.json
```

写入：

```json
{
  "log": {
    "loglevel": "warning"
  },

  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",

      "settings": {
        "clients": [
          {
            "id": "你的UUID",
            "flow": "xtls-rprx-vision"
          }
        ],

        "decryption": "none"
      },


      "streamSettings": {

        "network": "tcp",

        "security": "reality",

        "realitySettings": {

          "show": false,

          "dest": "www.microsoft.com:443",

          "xver": 0,

          "serverNames": [
            "www.microsoft.com"
          ],

          "privateKey": "你的PRIVATE_KEY",

          "shortIds": [
            "你的SHORT_ID"
          ]

        }

      }
    }
  ],


  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
```

替换：

```
你的UUID
你的PRIVATE_KEY
你的SHORT_ID
```

---

# 八、启动 Xray

检查配置：

```bash
xray run -test -config /usr/local/etc/xray/config.json
```

如果：

```
Configuration OK
```

启动：

```bash
systemctl restart xray
```

查看：

```bash
systemctl status xray
```

应该：

```
active(running)
```

---

# 九、开放端口

DigitalOcean Firewall：

打开：

```
TCP 443
```

如果服务器 Ubuntu 有 ufw：

```bash
ufw allow 443/tcp
```

---

# 十、安装 Clash Verge Rev

Windows：

安装：

Clash Verge Rev

启动。

---

# 十一、生成 Clash 配置

Clash 需要：

```
server
port
uuid
public-key
short-id
```

节点：

```yaml
proxies:

- name: DO-NYC
  type: vless

  server: 174.138.46.11

  port: 443

  uuid: 你的UUID

  network: tcp

  tls: true

  udp: true


  flow: xtls-rprx-vision


  servername: www.microsoft.com


  reality-opts:

    public-key: 你的PUBLIC_KEY

    short-id: 你的SHORT_ID
```

---

# 十二、Clash Verge 添加节点

打开：

```
Profiles
   |
Import
   |
New Profile
```

导入 yaml。

然后：

```
Proxies
```

应该看到：

```
DO-NYC
```

---

# 十三、测试连接

打开 Clash：

模式：

推荐：

```
Rule
```

然后访问：

```
https://ipinfo.io
```

应该显示：

```
DigitalOcean
New York
```

---

# 十四、性能优化（针对你的情况）

你现在：

```
中国 → NYC
225ms
```

所以 Xray 不会改变物理距离。

建议：

创建第二个 Droplet：

测试：

```
Singapore
San Francisco
```

然后 Clash 里面：

```
DO-NYC
DO-SG
DO-SF
```

三个节点。

自动选择：

```yaml
proxy-groups:

- name: Auto
  type: url-test

  proxies:
    - DO-NYC
    - DO-SG
    - DO-SF
```

Clash 自动选最快。

---

# 十五、建议你的最终架构

我建议：

```
DigitalOcean

   Singapore Droplet
          |
          |
       Xray
          |
          |
   Clash Verge Rev


同时保留：

WireGuard
(备用)
```

原因：

你的 NYC：

```
225ms
```

已经证明不是软件问题，而是线路问题。

---

## 你现在其实已经有一个优势

你已经成功：

✅ 创建 Droplet
✅ SSH 登录
✅ 配置 WireGuard
✅ 理解密钥体系
✅ 理解 NAT/路由

所以 Xray 这一套你不会像第一次搭的人那么困难。

下一步我建议不要直接部署 NYC，而是：

1. 新建一个 **Singapore Droplet**
2. 测 ping
3. 如果延迟降低，再部署 Xray

因为你的主要瓶颈已经确定：**Region，而不是协议。**

[1]: https://github.com/XTLS/Xray-core?utm_source=chatgpt.com "GitHub - XTLS/Xray-core: Xray, Penetrates Everything. Also the best v2ray-core. Where the magic happens. An open platform for various uses. · GitHub"


