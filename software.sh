#!/bin/bash

# software.sh - 安装基础软件脚本

# 本次更新：自动注释掉 /etc/apt/sources.list 中所有 cdrom:// 开头的源，并刷新 apt 缓存

# 检测是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 用户运行该脚本！"
  exit 1
fi

echo "开始安装基础软件..."

# --- 新增代码开始（本次对话更新） ---
# 自动注释掉 cdrom:// 源，避免安装时因 cdrom 源导致错误
if grep -q "^deb cdrom:" /etc/apt/sources.list; then
  echo "检测到 cdrom 源，正在注释掉以避免更新错误..."
  sed -i 's/^deb cdrom:/#deb cdrom:/g' /etc/apt/sources.list
  echo "已注释掉 cdrom 源。"
fi

# 更新 apt 软件包索引
apt-get update
# --- 新增代码结束 ---

# 安装基础软件包
apt-get install -y vim curl wget net-tools iputils-ping passwd sudo

echo "基础软件安装完成！"
