#!/bin/sh
#
# 作者：Tyrantcwj
# 功能：集成 openroot.sh 和 software.sh 两个脚本功能，自动判断curl或wget下载
#

# 检查是否root权限
if [ "$(id -u)" != "0" ]; then
  echo "请使用root权限运行脚本！"
  exit 1
fi

download_and_run() {
  URL=$1
  TMPFILE=$(mktemp)

  if command -v curl >/dev/null 2>&1; then
    curl -sSL "$URL" -o "$TMPFILE"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$TMPFILE" "$URL"
  else
    echo "系统未安装curl或wget，请先安装其中一个工具。"
    exit 1
  fi

  sh "$TMPFILE"
  rm -f "$TMPFILE"
}

echo "请选择要执行的功能："
echo "1) 运行 openroot.sh（设置root密码等）"
echo "2) 运行 software.sh（安装基础软件）"
echo "3) 两个脚本都执行"
echo "0) 退出"

printf "输入选项 [0-3]: "
read -r choice

case "$choice" in
  1)
    echo "开始执行 openroot.sh ..."
    download_and_run "https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh"
    ;;
  2)
    echo "开始执行 software.sh ..."
    download_and_run "https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/software.sh"
    ;;
  3)
    echo "开始执行 openroot.sh ..."
    download_and_run "https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh"
    echo "开始执行 software.sh ..."
    download_and_run "https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/software.sh"
    ;;
  0)
    echo "退出脚本。"
    exit 0
    ;;
  *)
    echo "无效选项，退出。"
    exit 1
    ;;
esac

echo "操作完成！"
