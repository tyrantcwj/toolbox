#!/bin/bash
# main.sh
# 作者：Tyrantcwj
# 版本：v8（更新于2026-09-12）
# 功能：一键运行 Debian 12/13 运维脚本菜单

show_os_info() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "当前系统：${PRETTY_NAME:-$ID}"
  fi
}

while true; do
    echo ""
    show_os_info
    echo "请选择要执行的功能："
    echo "0) 退出"
    echo "1) 安装基础软件（支持 Debian 12/13 / deb822）"
    echo "2) 开启 root 登录（Debian 12/13 + DMIT/cloud-init）"
    echo "3) 安装 Docker"
    echo "4) 一键开启 BBR"
    echo "5) 安装 sing-web"
    echo "6) 启用群晖 root 登录"
    read -r -p "输入选项 [0-6]: " option

    case $option in
        0)
            echo "退出脚本。"
            exit 0
            ;;
        1)
            echo "开始执行 install_base.sh ..."
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/toolbox/main/install_base.sh)
            ;;
        2)
            echo "开始执行 openroot.sh ..."
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/toolbox/main/openroot.sh)
            ;;
        3)
            echo "开始执行 install_docker.sh ..."
            bash <(wget -qO- https://linuxmirrors.cn/docker.sh)
            ;;
        4)
            echo "开始开启 BBR ..."
            if ! grep -q '^net.core.default_qdisc=fq' /etc/sysctl.conf 2>/dev/null; then
                printf '\nnet.core.default_qdisc=fq\n' >> /etc/sysctl.conf
            fi
            if ! grep -q '^net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf 2>/dev/null; then
                printf 'net.ipv4.tcp_congestion_control=bbr\n' >> /etc/sysctl.conf
            fi
            sysctl -p >/dev/null 2>&1 || true

            result=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
            if [ "$result" = "bbr" ]; then
                echo "✔︎ BBR 已成功开启！"
                echo "当前拥塞控制算法：$result"
            else
                echo "✘ BBR 开启失败，请检查内核版本或配置"
                echo "当前拥塞控制算法：${result:-unknown}"
            fi
            ;;
        5)
            echo "开始安装 sing-web ..."
            bash <(wget -qO- https://raw.githubusercontent.com/sing-web/x-ui/main/install_CN.sh)
            ;;
        6)
            echo "开始执行 synologyroot.sh ..."
            bash <(wget -qO- https://raw.githubusercontent.com/tyrantcwj/toolbox/main/synologyroot.sh)
            ;;
        *)
            echo "无效选项，请输入 0-6 之间的数字。"
            ;;
    esac
done
