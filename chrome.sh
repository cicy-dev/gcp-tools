#!/bin/bash

# Chrome 管理脚本
USER_DATA_DIR="$HOME/data/browser/chrome"
DEBUG_PORT="${DEBUG_PORT:-9222}"

case "$1" in
    install)
        echo "正在安装 Google Chrome..."

        # 检查是否已安装
        if command -v google-chrome &> /dev/null; then
            echo "Google Chrome 已安装"
            google-chrome --version
        else
            # 安装依赖
            sudo apt update
            sudo apt install -y wget gnupg

            # 添加 Google Chrome 仓库
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-archive-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

            # 安装 Chrome
            sudo apt update
            sudo apt install -y google-chrome-stable

            if [ $? -eq 0 ]; then
                echo "Google Chrome 安装完成"
                google-chrome --version
            else
                echo "错误: Google Chrome 安装失败"
                exit 1
            fi
        fi

        # 创建桌面快捷方式
        mkdir -p ~/Desktop
        cat > ~/Desktop/Chrome-Debug.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome Debug
Comment=启动 Chrome 浏览器（带远程调试）
Exec=$HOME/tools/chrome.sh start
Icon=google-chrome
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
EOF
        chmod +x ~/Desktop/Chrome-Debug.desktop
        echo "桌面快捷方式已创建"
        ;;
    start)
        # 检查是否已运行
        if pgrep -f "chrome.*--remote-debugging-port=$DEBUG_PORT" > /dev/null; then
            echo "Chrome 已在端口 $DEBUG_PORT 上运行"
            echo "远程调试地址: http://localhost:$DEBUG_PORT"
            exit 0
        fi

        echo "启动 Google Chrome..."
        mkdir -p "$USER_DATA_DIR"

        # 检测显示模式
        if [ -z "$DISPLAY" ]; then
            # 如果没有 DISPLAY，检查是否有 VNC 服务运行
            if pgrep -f "Xtigervnc :1" > /dev/null; then
                export DISPLAY=:1
                echo "使用 VNC 显示: $DISPLAY"
            else
                # 使用 headless 模式
                HEADLESS_FLAG="--headless=new"
                echo "使用 headless 模式"
            fi
        else
            echo "使用现有显示: $DISPLAY"
        fi

        # 启动 Chrome
        nohup google-chrome \
            --user-data-dir="$USER_DATA_DIR" \
            --remote-debugging-port=$DEBUG_PORT \
            --no-first-run \
            --no-default-browser-check \
            --no-sandbox \
            --disable-dev-shm-usage \
            --disable-gpu \
            --disable-software-rasterizer \
            $HEADLESS_FLAG \
            > "$USER_DATA_DIR/chrome.log" 2>&1 &

        CHROME_PID=$!

        # 等待 Chrome 启动
        echo "等待 Chrome 启动..."
        sleep 2  # 给 Chrome 一点初始化时间

        for i in {1..15}; do
            if curl -s http://localhost:$DEBUG_PORT/json/version > /dev/null 2>&1; then
                echo "✓ Google Chrome 已成功启动 (PID: $CHROME_PID)"
                echo "✓ 远程调试地址: http://localhost:$DEBUG_PORT"
                echo "✓ 日志文件: $USER_DATA_DIR/chrome.log"
                exit 0
            fi
            sleep 1
        done

        # 最后检查进程是否存在
        if ps -p $CHROME_PID > /dev/null 2>&1; then
            echo "✓ Chrome 进程正在运行 (PID: $CHROME_PID)"
            echo "✓ 远程调试地址: http://localhost:$DEBUG_PORT"
            echo "注意: DevTools API 可能需要更多时间初始化"
        else
            echo "错误: Chrome 启动失败，请检查日志: $USER_DATA_DIR/chrome.log"
            exit 1
        fi
        ;;
    stop)
        echo "停止 Google Chrome..."
        pkill -f "chrome.*--remote-debugging-port=$DEBUG_PORT"
        if [ $? -eq 0 ]; then
            echo "Chrome 已停止"
        else
            echo "未找到运行中的 Chrome 进程"
        fi
        ;;
    status)
        if pgrep -f "chrome.*--remote-debugging-port=$DEBUG_PORT" > /dev/null; then
            echo "Chrome 正在运行"
            pgrep -af "chrome.*--remote-debugging-port=$DEBUG_PORT" | head -1
            echo "远程调试地址: http://localhost:$DEBUG_PORT"
        else
            echo "Chrome 未运行"
        fi
        ;;
    help)
        echo "Chrome 管理脚本使用说明:"
        echo "  ./chrome.sh install  - 安装 Google Chrome"
        echo "  ./chrome.sh start    - 启动 Google Chrome"
        echo "  ./chrome.sh stop     - 停止 Google Chrome"
        echo "  ./chrome.sh status   - 查看 Chrome 状态"
        echo "  ./chrome.sh help     - 显示帮助信息"
        echo ""
        echo "配置:"
        echo "  用户数据目录: $USER_DATA_DIR"
        echo "  远程调试端口: $DEBUG_PORT (可通过 DEBUG_PORT 环境变量修改)"
        ;;
    *)
        echo "用法: $0 {install|start|stop|status|help}"
        exit 1
        ;;
esac
