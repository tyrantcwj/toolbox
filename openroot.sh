#!/usr/bin/env bash
# enable-root-login.sh
# 版本：v1 （更新于本次对话）
# 作用：一键开启 Debian 12 上的 SSH root 登录

set -e

# 1. 检查是否以 root 身份运行
if [[ $EUID -ne 0 ]]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

# 2. 备份 sshd_config
CFG="/etc/ssh/sshd_config"
BACKUP="${CFG}.bak_$(date +%F_%T)"
cp "$CFG" "$BACKUP"
echo "已备份原配置到：$BACKUP"

# 3. 修改 PermitRootLogin 和 PasswordAuthentication
sed -i 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' "$CFG"
sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' "$CFG"
echo "已设置 PermitRootLogin yes，PasswordAuthentication yes"

# 4. 解锁 root 账户（若已锁定）
passwd -u root >/dev/null 2>&1 || true

# 5. 交互式设置 root 密码
echo
echo "请为 root 账户输入新密码："
passwd root

# 6. 重启 SSH 服务
systemctl restart sshd
echo
echo "✔︎ SSH root 登录已开启！"
