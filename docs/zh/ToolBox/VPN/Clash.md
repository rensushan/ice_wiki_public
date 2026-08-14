# Clash

## 推荐的客户端

FlClash

Clash For Windows

Clash X

Clash Party

Clash Verge Rev 


名称	客户端	操作
Mihomo / Clash Meta
https://update.glados-config.com/mihomo/**/**/**/glados.yaml
Mihomo Universal, Clash Meta, FLClash	显示复制QR
Stash
https://update.glados-config.com/stash/**/**/**/glados.yaml
iOS, macOS	显示复制QR
Surge
https://update.glados-config.com/surge/**/**/glados.network.conf
iOS, macOS	显示复制QR
Surfboard
https://update.glados-config.com/surfboard/**/**/glados.network.conf
Android	显示复制QR
Shadowrocket (Servers only)
https://update.glados-config.com/subscribe/**/**/**/servers
iOS	显示复制QR
Clash Standard
https://update.glados-config.com/clash/**/**/**/glados.yaml
Clash, ClashX, CFA, CFW	显示复制QR
Mihomo (Backup)
https://www.glados-config.com/mihomo/**/**/**/glados.yaml
主地址不可用时使用	显示复制QR
Clash (Backup)
https://www.glados-config.com/clash/**/**/**/glados.yaml
主地址不可用时使用	显示复制QR
Singbox
https://update.glados-config.com/singbox/**/**
iOS, macOS, Windows, Linux	显示复制
Singbox for tvOS
https://update.glados-config.com/sft/**/**
tvOS	显示复制
Singbox for Android
https://update.glados-config.com/sfa/**/**
Android	显示复制
QuantumultX
https://update.glados-config.com/quantumultx/**/**
iOS	显示复制
Danger Zone




# Linux中使用Clash 命令行终端程序

第一步：下载 Clash 并在终端运行

user@localhost:~$ curl https://glados.one/tools/clash-linux.zip -o clash.zip #下载 Clash
user@localhost:~$ unzip clash.zip
user@localhost:~$ cd clash
user@localhost:~$ curl https://update.glados-config.com/clash/82339/fe2c843/53432/glados-terminal.yaml > glados.yaml #下载配置文件
user@localhost:~$ chmod +x ./clash-linux-amd64-v1.10.0
user@localhost:~$ ./clash-linux-amd64-v1.10.0 -f glados.yaml -d .
Clash 启动成功后，会看到如下日志：

INFO[0000] HTTP proxy listening  at: [::]:7890
INFO[0000] SOCKS proxy listening at: [::]:7891
INFO[0000] RESTful API listening at: 127.0.0.1:9090
这意味着 Clash 已经在 7890 端口启动了 HTTP 代理，在 7891 端口启动了 SOCKS 代理。

现在您可以在应用程序中使用这些代理端口。

第二步：在终端应用中使用代理

1. 示例：在 Git 中使用代理

打开新的终端窗口:

user@localhost:~$ git clone https://github.com/twbs/bootstrap.git --config "http.proxy=127.0.0.1:7890"
当 Clash 工作时，你会看到这样的日志：

INFO[0007] [TCP] 127.0.0.1:54875 --> github.com:443 match DomainKeyword(github) using Proxy
2. 示例：在 NPM 中使用代理

user@localhost:~$ npm config set proxy http://127.0.0.1:7890
user@localhost:~$ npm install pm2 -g
user@localhost:~$ npm config delete proxy  #取消代理设置
3. 示例：使用环境变量设置代理

user@localhost:~$ export http_proxy="127.0.0.1:7890"
user@localhost:~$ apt update
user@localhost:~$ apt install wget
user@localhost:~$ export http_proxy="" #取消代理设置
user@localhost:~$ export http_proxy="127.0.0.1:7890"
user@localhost:~$ curl https://ifconfig.me
user@localhost:~$ export http_proxy="" #取消代理设置
4. 示例：在 SSH 中使用代理

编辑 ~/.ssh/config 文件，添加：

Host 1.1.1.1
User root
ProxyCommand /usr/bin/nc -X5 -x 127.0.0.1:7891  %h %p
然后使用 SSH 连接：

ssh root@1.1.1.1
5. 示例：在 Linux 桌面设置系统级代理

注意：ping 命令不支持代理，请使用 curl 或 wget 测试连通性。

第三步：通过 Web 界面管理 Clash

您可以使用 Web UI 来管理 Clash, Port 默认端口是9090

项目地址: https://github.com/Dreamacro/clash

更多下载: https://github.com/Dreamacro/clash/releases



# MacOS中使用CLash 命令行终端程序

Step 1. 安装 ClashX 并确保 HTTP 代理端口为 7890，SOCKS 代理端口为 7891

您可以在 ClashX 菜单 -> 配置 -> 端口设置中检查这些设置

Step 2. 通过代理使用终端应用

1. 临时 SSH 代理（一次性使用）

ssh root@1.1.1.1 -o Proxycommand="nc -x 127.0.0.1:7890 %h %p"
2. 永久 SSH 代理配置

编辑 ~/.ssh/config 文件，添加：

Host 1.1.1.1
User root
ProxyCommand /usr/bin/nc -x 127.0.0.1:7890  %h %p
然后使用 SSH 连接：

ssh root@1.1.1.1
3. 示例：在 curl 中使用代理

curl --socks5 127.0.0.1:7890  https://ifconfig.me
4. 示例：在 Git 中使用代理

打开新的终端窗口:

user@localhost:~$ git clone https://github.com/twbs/bootstrap.git --config "http.proxy=127.0.0.1:7890"






如果你想用 **Clash 这类软件**，思路和 WireGuard 不一样。

Clash 本质上不是 VPN，而是一个**代理客户端（Proxy Client）**。它需要连接一个代理服务器，而你的 DigitalOcean Droplet 可以作为这个代理服务器。

整体结构：

```
你的电脑
    |
    |  Clash 客户端
    |
    |  (HTTP/SOCKS/VMess/VLESS/Shadowsocks 等代理协议)
    |
    ↓
DigitalOcean Droplet
    |
    ↓
Internet
```

也就是说：

* WireGuard：电脑 ↔ VPS 建立 VPN 隧道
* Clash：电脑 ↔ VPS 建立代理连接

---

## 你需要在 Droplet 上部署什么？

Clash 本身**不能装在服务器上作为服务端**。

你需要安装一个代理服务端，例如：

### 方案 1：Shadowsocks（简单）

```
Clash
  |
  | Shadowsocks协议
  |
Droplet
  |
Internet
```

优点：

* 配置简单
* Clash 原生支持
* 性能高

---

### 方案 2：VLESS + Reality（目前更常见）

结构：

```
Clash
 |
 | VLESS
 |
Xray Server
 |
Internet
```

优点：

* 功能强
* 支持 TLS/Reality
* 配置灵活

缺点：

* 配置复杂一些

---

## 如果你想使用 Clash，推荐架构

比较常见：

```
DigitalOcean Droplet
        |
        |
     Xray
        |
        |
    VLESS/Reality
        |
        |
      Clash
```

你的电脑：

```
Windows
 |
Clash Verge Rev
 |
127.0.0.1:7890
 |
浏览器/软件
```

---

# Clash 客户端部分

现在 Windows 常用：

* Clash Verge Rev
* Clash Meta

安装后：

启动 Clash：

它会监听：

```
127.0.0.1:7890
```

然后：

浏览器：

```
HTTP Proxy:
127.0.0.1
Port:
7890
```

或者开启：

```
System Proxy
```

整个系统自动使用。

---

# Droplet 端需要做什么？

以 Xray 为例：

服务器：

```
Ubuntu
 |
安装 Xray
 |
生成 UUID
 |
配置 inbound
 |
开放端口
```

例如：

```
端口:
443

协议:
VLESS

传输:
TCP

TLS:
Reality
```

然后生成 Clash 配置：

类似：

```yaml
proxies:
  - name: my-server
    type: vless
    server: xxx.xxx.xxx.xxx
    port: 443
    uuid: xxxxxxxx
    tls: true
```

导入 Clash：

```
Profiles
   |
Import
   |
config.yaml
```

即可。

---

# Clash 和 WireGuard 的区别

|        | WireGuard | Clash |
| ------ | --------- | ----- |
| 类型     | VPN       | 代理    |
| 系统级    | 是         | 可选    |
| 配置难度   | 低         | 中     |
| 速度     | 非常快       | 快     |
| 协议伪装   | 弱         | 强     |
| 适合移动设备 | 很好        | 很好    |
| 规则分流   | 弱         | 强     |
| 国内外分流  | 不方便       | 非常方便  |

---

## 为什么很多人选择 Clash？

因为它可以：

例如：

```
Google
   ↓
代理

GitHub
   ↓
代理

国内网站
   ↓
直连
```

通过规则：

```yaml
rules:
 - DOMAIN-SUFFIX,google.com,Proxy
 - GEOIP,CN,DIRECT
```

实现智能分流。

WireGuard 做不到这么方便。

---

## 对你的情况（DigitalOcean Droplet）

如果你的目标是：

> "我买了一台海外 VPS，希望电脑安装 Clash 使用"

那么典型路线：

```
Droplet
 Ubuntu
    |
    |
 Xray
    |
    |
 VLESS
    |
    |
Clash Verge Rev
    |
Windows/macOS
```

这是目前非常常见的个人代理架构。

---

如果你愿意，我可以进一步给你一份**从零开始的 DigitalOcean Ubuntu Droplet → Xray → Clash Verge Rev 完整部署流程**，包括：

1. 服务器安装命令
2. 防火墙设置
3. Clash 配置文件生成
4. Windows/macOS 导入方法。



