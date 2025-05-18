#!/bin/sh
# openroot.sh
# 作者：Tyrantcwj
# 版本：v2（更新于本次对话）
# 作用：一键开启 Debian 12 上的 SSH root 登录

# 1. 检查是否以 root 身份运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

# 2. 备份 sshd_config
CFG="/etc/ssh/sshd_config"
BACKUP="${CFG}.bak_$(date +%F_%T)"
cp "$CFG" "$BACKUP"
echo "已备份原配置到：$BACKUP"

# 3. 修改 PermitRootLogin 和 PasswordAuthentication
sed -i 's/^[# \t]*PermitRootLogin.*/PermitRootLogin yes/' "$CFG"
sed -i 's/^[# \t]*PasswordAuthentication.*/PasswordAuthentication yes/' "$CFG"
echo "已设置 PermitRootLogin yes，PasswordAuthentication yes"

# 4. 解锁 root 账户（若已锁定）
passwd -u root >/dev/null 2>&1 || true

# 5. 交互式设置 root 密码
echo
echo "请为 root 账户输入新密码（输入为空则跳过设置）："

# 读取密码
stty -echo
printf "新密码: "
read password1
echo
printf "确认密码: "
read password2
stty echo
echo

if [ -z "$password1" ] || [ "$password1" != "$password2" ]; then
  echo "密码为空或不一致，跳过设置 root 密码。"
else
  echo "root:$password1" | chpasswd && echo "密码设置成功。" || echo "密码设置失败。"
fi

# 6. 重启 SSH 服务
if systemctl restart sshd 2>/dev/null; then
  echo "✔︎ SSH 服务已重启，root 登录已开启！"
else
  echo "✖ 无法重启 sshd，请手动检查 SSH 服务状态。"
fi
