#!/bin/sh

# 必须是 root
if [ "$(id -u)" != "0" ]; then
  echo "请用 root 用户执行此脚本！"
  exit 1
fi

echo "更新软件包列表..."
apt-get update

echo "安装 bash curl wget git vim unzip bash-completion net-tools dnsutils"
apt-get install -y bash curl wget git vim unzip bash-completion net-tools dnsutils

echo "基础工具安装完成！"
