#!/bin/sh
# main.sh
# 作者：Tyrantcwj
# 版本：v6（更新于2025-06-14）
# 功能：一键运行 Debian 脚本，提供菜单选择，新增群晖 root 登录开启功能

while true; do
    echo ""
    echo "请选择要执行的功能："
    echo "0) 退出"
    echo "1) 安装基础软件"
    echo "2) 开启 root 登录"
    echo "3) 安装 Docker"
    echo "4) 一键开启 BBR"       # ✅ [2025-05-18] 添加 BBR 加速功能
    echo "5) 安装 sing-web"     # ✅ [2025-05-27] 添加 sing-web 安装功能
    echo "6) 启用群晖 root 登录" # ✅ [2025-06-14] 本次添加，引用 synologyroot.sh
    read -p "输入选项 [0-6]: " option

    case $option in
        0)
            echo "退出脚本。"
            exit 0
            ;;
        1)
            echo "开始执行 install_base.sh ..."
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/install_base.sh)
            ;;
        2)
            echo "开始执行 openroot.sh ..."
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/openroot.sh)
            ;;
        3)
            echo "开始执行 install_docker.sh ..."
            bash <(wget -qO- https://linuxmirrors.cn/docker.sh)
            ;;
        4)
            echo "开始开启 BBR ..."
            echo -e "\nnet.core.default_qdisc=fq\nnet.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            sysctl -p > /dev/null

            result=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
            if [ "$result" = "bbr" ]; then
                echo "✔︎ BBR 已成功开启！"
                echo "当前拥塞控制算法：$result"
            else
                echo "✘ BBR 开启失败，请检查内核版本或配置"
                echo "当前拥塞控制算法：$result"
            fi
            ;;
        5)
            echo "开始安装 sing-web ..." 
            bash <(wget -qO- https://raw.githubusercontent.com/sing-web/x-ui/main/install_CN.sh)
            ;;
        6)
            echo "开始执行 synologyroot.sh ..." # ✅ [2025-06-14] 本次添加
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/Debian12-Tools/main/synologyroot.sh)
            ;;
        *)
            echo "无效选项，请输入 0-6 之间的数字。"
            ;;
    esac
done
