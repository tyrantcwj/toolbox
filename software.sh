#!/bin/sh
# software.sh
# 作者：Tyrantcwj
# 版本：v2（2025-05-18 更新）

# 1. 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

echo "开始安装基础软件..."

apt-get update

# 2. 安装常用基础工具包，包括passwd（含chpasswd）
apt-get install -y \
    sudo \
    vim \
    curl \
    wget \
    net-tools \
    iputils-ping \
    passwd

echo "基础软件安装完成！"
