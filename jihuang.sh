#!/bin/bash
# dst-admin-go饥荒面板多功能安装脚本 v1.5 by 伶依nekochan

# 获取真实用户信息
REAL_USER=$(who am i | awk '{print $1}')
HOME_DIR=$(getent passwd $REAL_USER | cut -d: -f6)
DEST_DIR="$HOME_DIR/dst"
MANUAL_DIR="$DEST_DIR/手动上传"
LOG_DIR="$(pwd)/install_logs"
LOG_FILE="$LOG_DIR/dst_install_$(date +%Y%m%d%H%M%S).log"
BENCH_DIR="$HOME_DIR/geekbench"

# 初始化日志系统
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chown $REAL_USER:$REAL_USER "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    echo "=== 安装日志 $(date) ==="
}

# 调试信息
debug_info() {
    echo "====== 系统信息 ====="
    echo "当前用户: $REAL_USER"
    echo "用户目录: $HOME_DIR"
    echo "目标目录: $DEST_DIR"
    echo "日志文件: $LOG_FILE"
    echo "内存信息:"
    free -m
    echo "存储信息:"
    df -h
    echo "====================="
}

run_benchmark() {
    echo "====== 开始服务器性能测试 ======"
    
    # 创建目录
    mkdir -p "$BENCH_DIR" || {
        echo "无法创建测试目录: $BENCH_DIR"
        exit 1
    }

    # 检测是否已存在可执行文件
    if [ -f "$BENCH_DIR/geekbench5" ]; then
        echo "检测到已安装的Geekbench，跳过下载安装..."
    else
        # 系统架构检测
        ARCH=$(uname -m)
        case $ARCH in
            x86_64)
                GB_URL="http://47.108.31.40:5244/d/myfiles/Geekbench-5.4.5-Linux.tar.gz?sign=622NhrH1jYbXdiBN_Uy4qEqlh71Cp63ItXxGByXuPbE=:0"
                ;;
            *)
                echo "不支持的架构: $ARCH"
                exit 1
                ;;
        esac

        # 下载Geekbench
        echo "正在下载Geekbench..."
        if ! wget --limit-rate=1m --progress=bar:force -P "$BENCH_DIR" "$GB_URL"; then
            echo "下载失败！请检查："
            echo "1. 网络连接状态"
            echo "2. 磁盘空间是否充足"
            exit 1
        fi

        # 解压文件
        echo "正在解压安装包..."
        if ! tar -xzf "$BENCH_DIR/$(basename $GB_URL)" -C "$BENCH_DIR" --strip-components=1; then
            echo "解压失败！可能原因："
            echo "1. 下载文件不完整"
            echo "2. 磁盘空间不足"
            rm -f "$BENCH_DIR/$(basename $GB_URL)"
            exit 1
        fi

        # 清理安装包
        rm -f "$BENCH_DIR/$(basename $GB_URL)"
    fi

    # 安装依赖
    echo "检查系统依赖..."
    if ! dpkg -l | grep -q libcurl4; then
        sudo apt-get install -y libcurl4 >/dev/null 2>&1
    fi
    if ! dpkg -l | grep -q libncurses5; then
        sudo apt-get install -y libncurses5 >/dev/null 2>&1
    fi

   # 运行测试
    echo "开始性能测试(大约需要5-10分钟)..."
    RAW_OUTPUT=$("$BENCH_DIR/geekbench5" --upload 2>&1)
    echo "$RAW_OUTPUT" | tee "$BENCH_DIR/benchmark_result.txt"

    # 提取结果URL（宽松匹配）
    echo "正在获取测试结果链接..."
    URL=$(grep -oE 'https?://[a-zA-Z0-9./?=_-]+' <<< "$RAW_OUTPUT" | grep 'browser.geekbench' | head -1)

    if [ -n "$URL" ]; then
        echo "========================================"
        echo "测试完成！请手动访问以下链接查看结果："
        echo "$URL"
        echo ""
        echo "操作指引："
        echo "1. 复制上方链接"
        echo "2. 在浏览器地址栏粘贴打开"
        echo "3. 等待页面加载分数"
        echo " 服务器参考跑分：单核：1100 分左右就可以流畅6个人玩"
        echo " 腾讯云轻量单核参考跑分：800左右分 流畅运行纯净或者小mod快餐档"
        echo " 华为云x参考跑分：1200分 流畅运行长期建家档或者大型mod"
        echo " geekbench5跑分仅供参考 服务器性能以实际使用为准"

        echo "========================================"
    else
        echo "未能获取测试链接，请检查："
        echo "1. 查看原始输出: less $BENCH_DIR/benchmark_result.txt"
        echo "2. 尝试重新运行测试"
        echo "3. 确保服务器能访问geekbench.com"
        echo "最后10行输出："
        tail -n 10 "$BENCH_DIR/benchmark_result.txt"
        exit 1
    fi
}

# 增强检测函数
check_panel_exist() {
    local check_targets=(
        "$DEST_DIR/dst-admin-go"
        "$DEST_DIR/version.txt"
        "$DEST_DIR/dist/index.html"
        "$DEST_DIR/static"
    )

    for target in "${check_targets[@]}"; do
        if [ -e "$target" ]; then
            echo "检测到面板文件: $target"
            return 0
        fi
    done
    return 1
}

# 安装依赖
install_dependencies() {
    echo "安装系统依赖..."
    sudo apt-get update && \
    sudo apt-get install -y \
        tar \
        gzip \
        wget \
        curl \
        lsof \
        jq \
        unzip
}

# 版本配置
VERSIONS=("多层版本" "多房间版本")
URLS=(
    "http://47.108.31.40:5244/d/myfiles/dst-admin-go.1.5.0.tar.gz?sign=U3eDZ0KgDLcnpJhYjKA3lsEHnuOhxElO-hMqXq1eJg0=:0"
    "http://47.108.31.40:5244/d/myfiles/dst-admin-go-2.4.0-beta.tar.gz?sign=LYJN0Klv3gZ_vbS-Q0dZ58IUKcoAaWzBrbcSI7ewLgU=:0"
)
SCRIPTS=("install_dst_ubuntu.sh" "install_ubuntu.sh")

# 主安装流程
main_installation() {
    # 创建目录
    mkdir -p "$MANUAL_DIR" || {
        echo "目录创建失败: $MANUAL_DIR"
        exit 1
    }

    # 版本选择
    echo "请选择安装版本："
    PS3="输入数字选择："
    select num in "${VERSIONS[@]}" "取消"; do
        case $REPLY in
            1|2)
                selected=$((REPLY-1))
                break
                ;;
            3)
                echo "安装已取消"
                exit 0
                ;;
            *)
                echo "无效选择！"
                ;;
        esac
    done

    # 下载处理
    filename=$(basename "${URLS[$selected]%%\?*}")
    if [ ! -f "$MANUAL_DIR/$filename" ]; then
        echo "正在下载 ${VERSIONS[$selected]}..."
        wget --progress=bar:force --limit-rate=2M -O "$MANUAL_DIR/$filename" \
            "${URLS[$selected]}" || {
            echo "下载失败！错误代码：$?"
            exit 1
        }
    fi

    # 解压安装
    TEMP_DIR=$(mktemp -d)
    echo "解压到临时目录: $TEMP_DIR"
    tar -xzvf "$MANUAL_DIR/$filename" -C "$TEMP_DIR" || {
        echo "解压失败！错误代码：$?"
        rm -rf "$TEMP_DIR"
        exit 1
    }

    SRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "dst-admin-go*" | head -1)
    [ -z "$SRC_DIR" ] && {
        echo "无效的安装包结构！目录内容："
        ls -l "$TEMP_DIR"
        exit 1
    }

    echo "安装文件到 $DEST_DIR..."
    mkdir -p "$DEST_DIR"
    cp -vr "$SRC_DIR"/* "$DEST_DIR/"

    # 增强权限设置
    echo "设置文件权限..."
    sudo chown -R $REAL_USER:$REAL_USER "$DEST_DIR"
    
    # 设置目录权限
    sudo find "$DEST_DIR" -type d -exec chmod 775 {} \;
    
    # 设置文件权限（保留可执行权限）
    sudo find "$DEST_DIR" -type f -exec chmod 664 {} \;
    
    # 特别设置可执行文件权限
    for exec_file in "$DEST_DIR"/dst-admin-go "$DEST_DIR"/*.sh; do
        if [ -f "$exec_file" ]; then
            sudo chmod +x "$exec_file"
            echo "设置可执行权限: $exec_file"
        fi
    done

    # 验证安装脚本权限
    if [ ! -x "$DEST_DIR/${SCRIPTS[$selected]}" ]; then
        echo "错误：安装脚本没有执行权限！"
        ls -l "$DEST_DIR/${SCRIPTS[$selected]}"
        exit 1
    fi

    # 执行安装脚本
    echo "运行安装脚本 ${SCRIPTS[$selected]}..."
    cd "$DEST_DIR" && ./${SCRIPTS[$selected]} || {
        echo "安装脚本执行失败！错误代码：$?"
        echo "可能的原因："
        echo "1. 脚本缺少依赖项"
        echo "2. 磁盘空间不足"
        echo "3. 网络连接问题"
        exit 1
    }

    # 服务配置增强版
    configure_service() {
        SERVICE_FILE="/etc/systemd/system/dst-admin-go.service"
        
        echo "生成服务配置文件..."
        sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=DST Admin Go Service
After=network.target

[Service]
Type=simple
User=$REAL_USER
WorkingDirectory=$DEST_DIR
ExecStart=$DEST_DIR/dst-admin-go
Restart=always
RestartSec=30
Environment="PATH=$PATH:/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

        # 验证服务文件
        if ! sudo test -f "$SERVICE_FILE"; then
            echo "服务文件创建失败！"
            return 1
        fi

        # 权限设置
        sudo chmod 644 "$SERVICE_FILE"
        
        # 重载配置
        for i in {1..3}; do
            sudo systemctl daemon-reload && break
            sleep $i
        done

        # 启用服务
        sudo systemctl enable dst-admin-go.service
        
        # 启动服务
        sudo systemctl restart dst-admin-go.service
        sleep 5
        
        # 验证服务状态
        if ! systemctl is-active dst-admin-go.service >/dev/null; then
            echo "服务启动失败！错误日志："
            journalctl -u dst-admin-go.service -n 20 --no-pager
            return 1
        fi
    }

    # 执行服务配置
    if ! configure_service; then
        echo "服务配置失败！请手动检查："
        echo "1. 检查服务文件: $SERVICE_FILE"
        echo "2. 手动重载配置: sudo systemctl daemon-reload"
        echo "3. 查看服务状态: systemctl status dst-admin-go.service"
        exit 1
    fi

    echo "面板安装完成！"
    echo "访问地址：http://$(curl -s ifconfig.me):8082"
    echo "如果使用nat服请修改8082对应的端口号 游戏端口号记得打开哦"
    echo "饥荒开荒和开服交流群737331541"
    echo "面板作者项目地址https://github.com/carrot-hu23/dst-admin-go"
    echo "面板作者反馈群863437190"
}

# 更新面板功能（修复死循环核心部分）
update_panel() {
    echo "=== 面板更新 ==="
    
    # 更安全的服务停止
    if ! sudo systemctl stop dst-admin-go.service; then
        echo "警告：停止服务失败（可能服务未运行），继续更新..."
    fi

    # 目录处理
    pushd "$MANUAL_DIR" >/dev/null
    files=($(ls -t *.tar.gz *.tgz 2>/dev/null))
    [ ${#files[@]} -eq 0 ] && {
        echo "未找到更新文件！请将更新包放入 $MANUAL_DIR"
        popd >/dev/null
        return 1
    }

    # 文件选择（修复死循环的关键部分）
    local retry=0
    while true; do
        echo "可用的更新包："
        PS3="请输入数字选择更新包（最多错误3次）: "
        select file in "${files[@]}" "取消"; do
            case $REPLY in
                [1-9]*)
                    if (( REPLY > ${#files[@]} + 1 )); then
                        ((retry++))
                        echo "无效选择，剩余重试次数：$((3-retry))"
                        if (( retry >= 3 )); then
                            echo "错误次数过多，返回主菜单。"
                            popd >/dev/null
                            return 1
                        fi
                        continue
                    fi
                    if [[ "$file" == "取消" ]]; then
                        echo "操作已取消。"
                        popd >/dev/null
                        return 1
                    fi
                    break 2
                    ;;
                *)
                    ((retry++))
                    echo "无效输入，剩余重试次数：$((3-retry))"
                    if (( retry >= 3 )); then
                        echo "错误次数过多，返回主菜单。"
                        popd >/dev/null
                        return 1
                    fi
                    ;;
            esac
        done
    done
    popd >/dev/null

    # 增强解压验证
    TEMP_DIR=$(mktemp -d)
    echo "正在验证更新包..."
    if ! tar -tzf "$MANUAL_DIR/$file" >/dev/null; then
        echo "更新包损坏！"
        rm -rf "$TEMP_DIR"
        return 1
    fi
    tar -xzvf "$MANUAL_DIR/$file" -C "$TEMP_DIR" || {
        echo "解压失败！错误码：$?"
        rm -rf "$TEMP_DIR"
        return 1
    }

    SRC_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "dst-admin-go*" | head -1)
    [ -z "$SRC_DIR" ] && {
        echo "无效的更新包结构！目录内容："
        tree -L 2 "$TEMP_DIR"
        rm -rf "$TEMP_DIR"
        return 1
    }

    # 用户确认
    read -p "确认更新？将替换程序文件但保留配置 [y/N]: " confirm
    [[ $confirm =~ ^[Yy] ]] || { 
        rm -rf "$TEMP_DIR"
        return 0
    }

    # 精确文件替换
    echo "开始安全更新..."
    required_files=(
        "dst-admin-go" 
        "start.sh" 
        "更新内容.txt" 
        "dist" 
        "static" 
        "version.txt"
    )
    exclude_files=("config" "worlds")

    for item in "${required_files[@]}"; do
        if [[ " ${exclude_files[@]} " =~ " ${item} " ]]; then
            echo "跳过保留项: $item"
            continue
        fi
        
        if [ -e "$DEST_DIR/$item" ]; then
            echo "移除旧文件: $DEST_DIR/$item"
            rm -rf "$DEST_DIR/$item"
        fi
        
        if [ -e "$SRC_DIR/$item" ]; then
            echo "安装新文件: $item"
            cp -vr "$SRC_DIR/$item" "$DEST_DIR/"
        fi
    done

    # 权限修复
    sudo chown -R $REAL_USER:$REAL_USER "$DEST_DIR"
    sudo find "$DEST_DIR" -type d -exec chmod 775 {} \;
    sudo find "$DEST_DIR" -type f -exec chmod 664 {} \;
    sudo chmod +x "$DEST_DIR/dst-admin-go" "$DEST_DIR/start.sh"

    # 服务重启
    sudo systemctl daemon-reload
    sudo systemctl start dst-admin-go.service
    sleep 5
    
    # 启动状态检查
    if ! systemctl is-active dst-admin-go.service >/dev/null; then
        echo "紧急错误：服务无法启动！"
        echo "可能原因："
        echo "1. 文件权限问题 → 检查 chmod +x 设置"
        echo "2. 版本不兼容 → 查看更新内容.txt"
        echo "3. 查看详细日志：journalctl -u dst-admin-go.service -n 50"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # 清理临时文件
    rm -rf "$TEMP_DIR"
    
    echo "更新成功完成！请强制刷新浏览器缓存（Ctrl+F5）"
    echo "访问地址：http://$(curl -s ifconfig.me):8082"
    echo "如果使用nat服请修改8082对应的端口号 游戏端口号记得打开哦"
    echo "饥荒开荒和开服交流群737331541"
    echo "面板作者项目地址https://github.com/carrot-hu23/dst-admin-go"
    echo "面板作者反馈群863437190"
}

# 主流程（修复主菜单循环）
init_logging
debug_info

if check_panel_exist; then
    echo "=== 检测到已安装面板 ==="
    while true; do
        PS3="请输入数字选择操作："
        select action in \
            "更新游戏服务器" \
            "更新管理面板" \
            "下载或者更新测试服" \
            "服务器性能测试" \
            "退出脚本"; do
            case $REPLY in
                1)
                    echo "=== 更新游戏服务器 ==="
                    steamcmd_path="$HOME_DIR/steamcmd/steamcmd.sh"
                    if [ ! -f "$steamcmd_path" ]; then
                        echo "未找到steamcmd，请先通过安装面板安装！"
                        read -p "按回车返回主菜单..."
                        break
                    fi
                    
                    echo "正在更新饥荒正式服..."
                    cd "$HOME_DIR/steamcmd" && \
                    ./steamcmd.sh +login anonymous \
                    +force_install_dir "$HOME_DIR/dst-dedicated-server" \
                    +app_update 343050 validate +quit
                    
                    echo "更新完成！安装目录：$HOME_DIR/dst-dedicated-server"
                    read -p "按回车返回主菜单..."
                    break
                    ;;
                2)
                    echo "##########################################################"
                    echo "# 重要提示！更新面板需要先上传压缩包到dst/手动上传文件夹！"
                    echo "# 不是稳定版可能会有未知bug 可能无法正常使用！"
                    echo "# 请前往交流群或项目地址获取最新版本或者稳定版！"
                    echo "##########################################################"
                    read -p "按回车键继续更新（若确定要继续）或 Ctrl+C 取消..."
                    update_panel
                    read -p "按回车返回主菜单或输入q退出..." -t 60 input
                    [[ "$input" =~ [qQ] ]] && exit 0
                    break
                    ;;
                3)
                    echo "##########################################################"
                    echo "# 重要提示！测试服功能需要面板1.5版本以上支持！"
                    echo "# 如果当前版本低于1.5，测试服可能无法正常使用！"
                    echo "# 请前往交流群或项目地址获取最新版本！"
                    echo "##########################################################"
                    read -p "按回车键继续下载（若确定要继续）或 Ctrl+C 取消..."

                    steamcmd_path="$HOME_DIR/steamcmd/steamcmd.sh"
                    if [ ! -f "$steamcmd_path" ]; then
                        echo "未找到steamcmd，请先通过更新游戏服务器安装！"
                        read -p "按回车返回主菜单..."
                        break
                    fi
                    
                    echo "正在下载饥荒测试服..."
                    cd "$HOME_DIR/steamcmd" && \
                    ./steamcmd.sh +login anonymous \
                    +force_install_dir "$HOME_DIR/dst-dedicated-server-beta" \
                    +app_update 343050 -beta updatebeta validate +quit
                    
                    echo "测试服下载完成！安装目录：$HOME_DIR/dst-dedicated-server-beta"
                    read -p "按回车返回主菜单..."
                    break
                    ;;
                4)
                    run_benchmark
                    read -p "按回车返回主菜单..."
                    break
                    ;;
                5)
                    echo "正在退出脚本..."
                    exit 0
                    ;;
                *)
                    if (( REPLY > 5 )); then
                        echo "输入错误次数过多，自动退出。"
                        exit 1
                    fi
                    echo "无效的选项，请重新输入数字！"
                    ;;
            esac
        done
    done
else
    echo "=== 开始全新安装 ==="
    install_dependencies
    main_installation
fi

echo "安装日志已保存至：$LOG_FILE"
