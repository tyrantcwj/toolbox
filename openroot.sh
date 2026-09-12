#!/bin/sh
# openroot.sh
# 作者：Tyrantcwj
# 版本：v5
# 作用：一键开启 Debian/Ubuntu 上的 SSH root 登录，并自动设置密码
#       兼容 Debian 12/13、DMIT 等 cloud-init 云 VPS（处理 sshd_config.d 覆盖）
export PATH=$PATH:/usr/sbin:/usr/bin

# 1. 检查是否为 root
if [ "$(id -u)" -ne 0 ]; then
  echo "请使用 root 用户或 sudo 来运行此脚本！"
  exit 1
fi

# 显示系统信息（便于确认 Debian 13 等环境）
if [ -f /etc/os-release ]; then
  . /etc/os-release
  echo "检测到系统：${PRETTY_NAME:-$ID}"
fi

# 2. 备份 sshd_config
CFG="/etc/ssh/sshd_config"
if [ ! -f "$CFG" ]; then
  echo "✖ 未找到 $CFG，请先安装 openssh-server。"
  exit 1
fi
BACKUP="${CFG}.bak_$(date +%F_%T)"
cp "$CFG" "$BACKUP"
echo "已备份原配置到：$BACKUP"

# 确保主配置会 Include drop-in（Debian 12/13 默认有，缺了就补）
if ! grep -qE '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$CFG"; then
  # Include 必须在其他指令之前才有正确优先级语义，插到文件头部更稳妥
  tmp="${CFG}.tmp_$$"
  {
    echo "Include /etc/ssh/sshd_config.d/*.conf"
    cat "$CFG"
  } > "$tmp" && mv "$tmp" "$CFG"
  echo "已补充 Include /etc/ssh/sshd_config.d/*.conf"
fi

# 在指定文件中设置 SSH 选项：有则替换，无则追加
set_sshd_option() {
  file="$1"
  key="$2"
  val="$3"
  if grep -qE "^[# \t]*${key}([[:space:]]|=)" "$file" 2>/dev/null; then
    sed -i "s|^[# \t]*${key}[[:space:]].*|${key} ${val}|" "$file"
    sed -i "s|^[# \t]*${key}=.*|${key} ${val}|" "$file"
  else
    echo "${key} ${val}" >> "$file"
  fi
}

# 3. 修改主 SSH 配置
set_sshd_option "$CFG" "PermitRootLogin" "yes"
set_sshd_option "$CFG" "PasswordAuthentication" "yes"
# Debian 13 / OpenSSH 9.x：键盘交互认证也会影响密码登录
set_sshd_option "$CFG" "KbdInteractiveAuthentication" "yes"
# 兼容旧名（部分旧配置仍在使用）
if grep -qE '^[# \t]*ChallengeResponseAuthentication' "$CFG" 2>/dev/null; then
  set_sshd_option "$CFG" "ChallengeResponseAuthentication" "yes"
fi
echo "已设置 PermitRootLogin / PasswordAuthentication / KbdInteractiveAuthentication = yes"

# 4. 处理 cloud-init drop-in 覆盖（DMIT / AWS / DO 等云 VPS 常见）
DROPIN_DIR="/etc/ssh/sshd_config.d"
mkdir -p "$DROPIN_DIR"

for f in "$DROPIN_DIR"/*.conf; do
  [ -f "$f" ] || continue
  case "$f" in
    */00-toolbox-root.conf|*/99-toolbox-root.conf) continue ;;
  esac
  if grep -qE '^[# \t]*(PasswordAuthentication|PermitRootLogin|KbdInteractiveAuthentication|ChallengeResponseAuthentication)' "$f" 2>/dev/null; then
    cp "$f" "${f}.bak_$(date +%F_%T)"
    set_sshd_option "$f" "PasswordAuthentication" "yes"
    set_sshd_option "$f" "PermitRootLogin" "yes"
    if grep -qE '^[# \t]*KbdInteractiveAuthentication' "$f" 2>/dev/null; then
      set_sshd_option "$f" "KbdInteractiveAuthentication" "yes"
    fi
    if grep -qE '^[# \t]*ChallengeResponseAuthentication' "$f" 2>/dev/null; then
      set_sshd_option "$f" "ChallengeResponseAuthentication" "yes"
    fi
    echo "已修正 drop-in 配置：$f"
  fi
done

# 5. 写入最早加载的 drop-in（Debian/OpenSSH：先出现的配置生效，00 优先于 50-cloud-init）
#    同时清理旧版 99-toolbox-root.conf，避免混淆
rm -f "${DROPIN_DIR}/99-toolbox-root.conf"
TOOLBOX_DROPIN="${DROPIN_DIR}/00-toolbox-root.conf"
cat > "$TOOLBOX_DROPIN" <<'EOF'
# toolbox: 确保 root 密码登录生效
# Debian/OpenSSH 为 first-match-wins；00 会早于 50-cloud-init.conf 生效
# 适用于 Debian 12/13 及 cloud-init 云镜像
PermitRootLogin yes
PasswordAuthentication yes
KbdInteractiveAuthentication yes
EOF
echo "已写入优先配置：$TOOLBOX_DROPIN"

# 6. 解锁 root 账户（若已锁定）
passwd -u root >/dev/null 2>&1 || true

# 7. 设置 root 密码为指定值
echo "root:Cwj21cwj" | chpasswd && echo "✔︎ root 密码已设置为 Cwj21cwj" || echo "✖ 设置 root 密码失败"

# 8. 语法检查后重启 SSH（Debian 服务名多为 ssh）
if command -v sshd >/dev/null 2>&1; then
  if ! sshd -t 2>/dev/null; then
    echo "✖ sshd 配置语法错误，已中止重启。请检查配置后手动处理。"
    sshd -t
    exit 1
  fi
fi

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
sshd -T 2>/dev/null | grep -E 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication' || true

ok_pw=$(sshd -T 2>/dev/null | awk '/^passwordauthentication / {print $2}')
ok_root=$(sshd -T 2>/dev/null | awk '/^permitrootlogin / {print $2}')

if [ "$ok_pw" = "yes" ] && [ "$ok_root" = "yes" ]; then
  echo "✔︎ root 密码登录已开启！"
else
  echo "⚠ 配置可能未完全生效，请手动检查："
  echo "  sshd -T | grep -E 'permitrootlogin|passwordauthentication|kbdinteractiveauthentication'"
fi
