#!/bin/bash

# 群晖开启root SSH登录 一键脚本
# 创建时间：2025-06-05
# 功能：
# 1. 检查是否为root权限
# 2. 修改sshd配置允许root登录
# 3. 设置root密码
# 4. 重启SSH服务

# 1. 检查是否为root
if [[ "$EUID" -ne 0 ]]; then
  echo "❌ 本脚本需要root权限，请使用sudo或切换为root用户运行。"
  exit 1
fi

# 2. 修改 sshd_config 权限并设置 PermitRootLogin yes
chmod 755 /etc/ssh/sshd_config

# 修改配置：如果已经有 PermitRootLogin 行则替换，否则添加
if grep -q "^#PermitRootLogin prohibit-password" /etc/ssh/sshd_config; then
  sed -i 's|^#PermitRootLogin prohibit-password|PermitRootLogin yes|' /etc/ssh/sshd_config
elif grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
  sed -i 's|^PermitRootLogin.*|PermitRootLogin yes|' /etc/ssh/sshd_config
else
  echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
fi

# 3. 设置 root 密码
synouser --setpw root Cwj21cwj

# 4. 重启 SSH 服务
echo "🔁 正在重启 SSH 服务..."
synoservicectl --restart sshd

echo "✅ 已启用 root 登录，密码已设置为：Cwj21cwj"
