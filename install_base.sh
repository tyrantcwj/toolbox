#!/bin/bash
# install_base.sh - 安装基础软件脚本
# 版本：v2（2026-09-12）
# 支持：Debian 12 (bookworm) / Debian 13 (trixie)，兼容 deb822 源格式

if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 用户运行该脚本！"
  exit 1
fi

echo "开始安装基础软件..."

# 读取发行版信息
. /etc/os-release 2>/dev/null || true
CODENAME="${VERSION_CODENAME:-}"
ID_LIKE_LOWER="$(echo "${ID:-} ${ID_LIKE:-}" | tr '[:upper:]' '[:lower:]')"

if [ -z "$CODENAME" ] && [ -f /etc/debian_version ]; then
  case "$(cut -d. -f1 /etc/debian_version)" in
    12) CODENAME="bookworm" ;;
    13) CODENAME="trixie" ;;
    *) CODENAME="trixie" ;;
  esac
fi

case "$CODENAME" in
  bookworm|trixie) ;;
  *)
    if echo "$ID_LIKE_LOWER" | grep -q debian; then
      echo "⚠ 未识别的 Debian 代号「${CODENAME:-unknown}」，将按 trixie 处理镜像源。"
      CODENAME="trixie"
    else
      echo "⚠ 非 Debian 系统，跳过镜像源自动配置，直接安装软件包。"
      CODENAME=""
    fi
    ;;
esac

# 注释 cdrom 源（传统 sources.list）
if [ -f /etc/apt/sources.list ] && grep -qE '^[[:space:]]*deb[[:space:]]+cdrom:' /etc/apt/sources.list; then
  echo "检测到 cdrom 源，正在注释掉以避免更新错误..."
  sed -i 's|^[[:space:]]*deb[[:space:]]\+cdrom:|# deb cdrom:|g' /etc/apt/sources.list
  echo "已注释掉 cdrom 源。"
fi

# 注释 cdrom（.list / .sources）
for f in /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do
  [ -f "$f" ] || continue
  if grep -qE '(^|[[:space:]])cdrom:' "$f" 2>/dev/null; then
    sed -i '/cdrom:/s/^/# /' "$f"
    echo "已处理 cdrom 相关源：$f"
  fi
done

# 是否已有有效网络源（传统 .list 或 deb822 .sources）
has_valid_source() {
  if [ -f /etc/apt/sources.list ] && grep -qE '^[[:space:]]*deb[[:space:]]+https?://' /etc/apt/sources.list; then
    return 0
  fi
  for f in /etc/apt/sources.list.d/*.list; do
    [ -f "$f" ] || continue
    if grep -qE '^[[:space:]]*deb[[:space:]]+https?://' "$f"; then
      return 0
    fi
  done
  for f in /etc/apt/sources.list.d/*.sources; do
    [ -f "$f" ] || continue
    if grep -qiE '^[[:space:]]*URIs:[[:space:]]+https?://' "$f"; then
      return 0
    fi
  done
  return 1
}

# 无有效源时写入清华镜像（Debian 13 优先 deb822）
if [ -n "$CODENAME" ] && ! has_valid_source; then
  echo "未检测到有效网络源，正在为 ${CODENAME} 添加清华镜像源..."
  mkdir -p /etc/apt/sources.list.d

  if [ "$CODENAME" = "trixie" ] || [ "${VERSION_ID%%.*}" = "13" ]; then
    cat > /etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian
Suites: ${CODENAME} ${CODENAME}-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/debian-security
Suites: ${CODENAME}-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    # 清空可能为空/仅有 cdrom 的旧 sources.list，避免干扰
    if [ -f /etc/apt/sources.list ]; then
      cp /etc/apt/sources.list "/etc/apt/sources.list.bak_$(date +%F_%T)"
      : > /etc/apt/sources.list
    fi
    echo "已写入 deb822 源：/etc/apt/sources.list.d/debian.sources"
  else
    cat > /etc/apt/sources.list <<EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME} main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${CODENAME}-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${CODENAME}-security main contrib non-free non-free-firmware
EOF
    echo "已写入传统源：/etc/apt/sources.list"
  fi
fi

echo "正在更新软件包索引..."
apt-get update

apt-get install -y vim curl wget net-tools iputils-ping passwd sudo

echo "基础软件安装完成！（检测到系统：${PRETTY_NAME:-${ID:-unknown}} / ${CODENAME:-n/a}）"
