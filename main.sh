#!/bin/sh
#
# 作者：Tyrantcwj
# 功能：集成 openroot.sh 和 software.sh 两个脚本功能
#      支持选择运行其中一个或同时运行两个
#

# 检查是否root权限
if [ "$(id -u)" != "0" ]; then
  echo "请使用root权限运行脚本！"
  exit 1
fi

echo "请选择要执行的功能："
echo "1) 运行 openroot.sh（设置root密码等）"
echo "2) 运行 software.sh（安装基础软件）"
echo "3) 两个脚本都执行"
echo "0) 退出"

printf "输入选项 [0-3]: "
read choice

run_openroot() {
  echo "开始执行 openroot.sh ..."
  sh -c "$(curl -sSL https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh)"
}

run_software() {
  echo "开始执行 software.sh ..."
  sh -c "$(curl -sSL https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/software.sh)"
}

case "$choice" in
  1)
    run_openroot
    ;;
  2)
    run_software
    ;;
  3)
    run_openroot
    run_software
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
