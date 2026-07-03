#!/bin/sh
# openroot.sh
# 作者：Tyrantcwj
# 版本：v4
# 作用：一键开启 Debian/Ubuntu 上的 SSH root 登录，并自动设置密码
#       兼容 DMIT 等 cloud-init 云 VPS（处理 sshd_config.d 覆盖问题）
export PATH=$PATH:/usr/sbin

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

# 3. 修改主 SSH 配置
sed -i 's/^[# \t]*PermitRootLogin.*/PermitRootLogin yes/' "$CFG"
sed -i 's/^[# \t]*PasswordAuthentication.*/PasswordAuthentication yes/' "$CFG"
echo "已设置 PermitRootLogin yes，PasswordAuthentication yes"

# 4. 处理 cloud-init drop-in 覆盖（DMIT / AWS / DO 等云 VPS 常见）
#    sshd_config.d 后加载的配置会覆盖主文件，例如 50-cloud-init.conf 里的 PasswordAuthentication no
DROPIN_DIR="/etc/ssh/sshd_config.d"
if [ -d "$DROPIN_DIR" ]; then
  for f in "$DROPIN_DIR"/*.conf; do
    [ -f "$f" ] || continue
    case "$f" in
      */99-toolbox-root.conf) continue ;;
    esac
    if grep -qE '^(#?[ \t]*)?(PasswordAuthentication|PermitRootLogin)' "$f" 2>/dev/null; then
      cp "$f" "${f}.bak_$(date +%F_%T)"
      sed -i 's/^[# \t]*PasswordAuthentication.*/PasswordAuthentication yes/' "$f"
      sed -i 's/^[# \t]*PermitRootLogin.*/PermitRootLogin yes/' "$f"
      echo "已修正 drop-in 配置：$f"
    fi
  done
fi

# 5. 写入最高优先级 drop-in，确保覆盖 cloud-init 等后续重置
TOOLBOX_DROPIN="${DROPIN_DIR}/99-toolbox-root.conf"
cat > "$TOOLBOX_DROPIN" <<'EOF'
# toolbox: 确保 root 密码登录生效（优先级高于 50-cloud-init.conf）
PermitRootLogin yes
PasswordAuthentication yes
EOF
echo "已写入优先配置：$TOOLBOX_DROPIN"

# 6. 解锁 root 账户（若已锁定）
passwd -u root >/dev/null 2>&1 || true

# 7. 设置 root 密码为指定值
echo "root:Cwj21cwj" | chpasswd && echo "✔︎ root 密码已设置为 Cwj21cwj" || echo "✖ 设置 root 密码失败"

# 8. 重启 SSH 服务（Debian 用 ssh，部分发行版用 sshd）
if systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null; then
  echo "✔︎ SSH 服务已重启"
elif service ssh restart 2>/dev/null || service sshd restart 2>/dev/null; then
  echo "✔︎ SSH 服务已重启"
else
  echo "✖ 无法重启 SSH 服务，请手动检查。"
fi

# 9. 验证生效配置
echo ""
echo "当前 SSH 生效配置："
sshd -T 2>/dev/null | grep -E 'permitrootlogin|passwordauthentication' || true

if sshd -T 2>/dev/null | grep -qi 'passwordauthentication yes' \
  && sshd -T 2>/dev/null | grep -qi 'permitrootlogin yes'; then
  echo "✔︎ root 密码登录已开启！"
else
  echo "⚠ 配置可能未完全生效，请手动检查："
  echo "  sshd -T | grep -E 'permitrootlogin|passwordauthentication'"
fi
