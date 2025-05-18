# Debian12-Tools

这是一个自用于 Debian 12 系统的多功能运维脚本集合，方便快速完成常见服务器环境配置。
目前正在根据自己需要的功能逐步添加。

## 功能介绍

该脚本目前包含以下功能：

- 安装基础软件（包括常用工具和依赖）
- 开启 root 用户 SSH 登录（自动配置 sshd 并设置 root 密码）
- 安装 Docker 环境

## 一键启动指令

```bash
sh -c "$(wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/main.sh)"
