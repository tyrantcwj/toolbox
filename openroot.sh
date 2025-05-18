#!/bin/sh
# openroot.sh
# 作者：Tyrantcwj
# 版本：v3（2025-05-18 更新）
# 作用：开启root登录并自动设置密码（不依赖chpasswd）

# 检查是否root
if [ "$(id -u)" != "0" ]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

CFG="/etc/ssh/sshd_config"
BACKUP="${CFG}.bak_$(date +%F_%T)"
cp "$CFG" "$BACKUP"
echo "已备份原配置到：$BACKUP"

# 修改配置
sed -i 's/^[#[:space:]]*PermitRootLogin.*/PermitRootLogin yes/' "$CFG"
sed -i 's/^[#[:space:]]*PasswordAuthentication.*/PasswordAuthentication yes/' "$CFG"
echo "已设置 PermitRootLogin yes，PasswordAuthentication yes"

# 解锁 root 账户
passwd -u root >/dev/null 2>&1 || true

# 安装 expect （用于自动交互）
apt-get update
apt-get install -y expect

# 自动设置密码
PASS="Cwj21cwj"

expect <<EOF
spawn passwd root
expect "New password:"
send "$PASS\r"
expect "Retype new password:"
send "$PASS\r"
expect eof
EOF

if [ $? -eq 0 ]; then
  echo "✔ 设置 root 密码成功"
else
  echo "✖ 设置 root 密码失败"
fi

# 重启 ssh 服务
systemctl restart sshd
echo "✔︎ SSH 服务已重启，root 登录已开启！"
