#!/bin/sh
# main.sh
# 作者：Tyrantcwj
# 版本：v3（更新于2025-05-18）
# 功能：一键运行 Debian 脚本，提供菜单选择

while true; do
    printf "\n请选择要执行的功能：\n"
    printf "0) 退出\n"
    printf "1) 运行 software.sh（安装基础软件）\n"
    printf "2) 运行 openroot.sh（设置 root 密码等）\n"
    printf "3) 两个脚本都执行\n"
    printf "输入选项 [0-3]: "
    read -r choice

    case "$choice" in
        0)
            echo "已退出。"
            exit 0
            ;;
        1)
            echo "开始执行 software.sh ..."
            wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/software.sh | sh
            ;;
        2)
            echo "开始执行 openroot.sh ..."
            wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh | sh
            ;;
        3)
            echo "开始依次执行 software.sh 和 openroot.sh ..."
            wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/software.sh | sh
            wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh | sh
            ;;
        *)
            echo "无效的选项，请输入 0 到 3 之间的数字。"
            ;;
    esac
done
