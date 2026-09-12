# Toolbox

这是一个自用于 Linux 系统的多功能运维脚本集合，方便快速完成常见服务器环境配置。

目前正在根据自己需要的功能逐步添加，欢迎参考或自用。

**支持系统：** Debian 12 (bookworm)、Debian 13 (trixie)，以及常见 cloud-init 云 VPS（如 DMIT）。

## 功能介绍

该脚本目前包含以下功能：

1. 安装基础软件（自动识别 Debian 12/13，兼容 deb822 源格式，必要时写入清华镜像）
2. 开启 root 用户 SSH 登录（处理 `sshd_config.d` / cloud-init 覆盖，兼容 Debian 13 OpenSSH）
3. 安装 Docker 环境
4. 一键开启 BBR 加速
5. 安装 sing-web 面板
6. 启用群晖 root 登录（适用于 DSM，自动修改 sshd_config、设置 root 密码并重启 SSH 服务）

## 一键启动指令

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/tyrantcwj/toolbox/main/main.sh)"
```
