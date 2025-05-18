#!/bin/sh
# openroot.sh
# 作者：Tyrantcwj
# 版本：v4（使用 sh 支持语法，自动设置 root 密码）

# 1. 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

# 2. 备份 sshd_config
CFG="/etc/ssh/sshd_config"
BACKUP="${CFG}.bak_$(date +%F_%T)"
cp "$CFG" "$BACKUP"
echo "已备份原配置到：$BACKUP"

# 3. 修改 SSH 配置
sed -i 's/^[# \t]*PermitRootLogin.*/PermitRootLogin yes/' "$CFG"
sed -i 's/^[# \t]*PasswordAuthentication.*/PasswordAuthentication yes/' "$CFG"
echo "已设置 PermitRootLogin yes，PasswordAuthentication yes"

# 4. 解锁 root 账户（若已锁定）
passwd -u root >/dev/null 2>&1 || true

# 5. 设置 root 密码为 Cwj21cwj
echo "root:Cwj21cwj" | chpasswd && echo "✔︎ root 密码已设置为iTyc的初始密码" || echo "✖ 设置 root 密码失败"

# 6. 重启 SSH 服务
if systemctl restart sshd 2>/dev/null; then
  echo "✔︎ SSH 服务已重启，root 登录已开启！"
else
  echo "✖ 无法重启 sshd，请手动检查 SSH 服务状态。"
fi
