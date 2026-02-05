#!/bin/bash

# GoTTY 管理脚本
# 用法: bash gotty.sh [install|start|stop|status|help]

GOTTY_PORT=8081
GOTTY_PID_FILE="/tmp/gotty.pid"

install() {
    echo "安装 GoTTY..."
    cd /tmp
    wget -q https://github.com/yudai/gotty/releases/download/v2.0.0-alpha.3/gotty_2.0.0-alpha.3_linux_amd64.tar.gz
    tar -xzf gotty_2.0.0-alpha.3_linux_amd64.tar.gz
    sudo mv gotty /usr/local/bin/
    sudo chmod +x /usr/local/bin/gotty
    rm -f gotty_2.0.0-alpha.3_linux_amd64.tar.gz
    echo "GoTTY 安装完成"
    gotty --version
}

start() {
    if [ -f "$GOTTY_PID_FILE" ] && kill -0 $(cat "$GOTTY_PID_FILE") 2>/dev/null; then
        echo "GoTTY 已在运行 (PID: $(cat $GOTTY_PID_FILE))"
        return
    fi
    
    echo "启动 GoTTY 在端口 $GOTTY_PORT..."
    nohup gotty -w -p $GOTTY_PORT tmux > /dev/null 2>&1 &
    echo $! > "$GOTTY_PID_FILE"
    sleep 2
    echo "GoTTY 已启动: http://localhost:$GOTTY_PORT"
}

stop() {
    if [ -f "$GOTTY_PID_FILE" ]; then
        PID=$(cat "$GOTTY_PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            rm -f "$GOTTY_PID_FILE"
            echo "GoTTY 已停止"
        else
            echo "GoTTY 进程不存在"
            rm -f "$GOTTY_PID_FILE"
        fi
    else
        echo "GoTTY 未运行"
    fi
}

status() {
    if [ -f "$GOTTY_PID_FILE" ] && kill -0 $(cat "$GOTTY_PID_FILE") 2>/dev/null; then
        echo "✅ GoTTY 运行中 (PID: $(cat $GOTTY_PID_FILE))"
        echo "   访问地址: http://localhost:$GOTTY_PORT"
    else
        echo "❌ GoTTY 未运行"
    fi
}

help() {
    echo "GoTTY 管理脚本"
    echo ""
    echo "用法: bash gotty.sh [命令]"
    echo ""
    echo "命令:"
    echo "  install  - 安装 GoTTY"
    echo "  start    - 启动 GoTTY 服务"
    echo "  stop     - 停止 GoTTY 服务"
    echo "  status   - 检查 GoTTY 状态"
    echo "  help     - 显示帮助信息"
    echo ""
    echo "GoTTY 基本用法:"
    echo "  # 在浏览器中共享终端"
    echo "  gotty bash"
    echo ""
    echo "  # 指定端口"
    echo "  gotty -p 8080 bash"
    echo ""
    echo "  # 允许写入权限（危险，仅在安全环境使用）"
    echo "  gotty -w bash"
    echo ""
    echo "  # 设置认证"
    echo "  gotty --credential user:password bash"
    echo ""
    echo "常用选项:"
    echo "  -p, --port          指定端口（默认 8080）"
    echo "  -w, --permit-write  允许客户端写入"
    echo "  --credential        设置用户名:密码认证"
    echo "  --random-url        使用随机 URL 路径"
    echo "  --once              只允许一个客户端连接"
    echo ""
    echo "默认端口: $GOTTY_PORT"
}

case "$1" in
    install)
        install
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    help|"")
        help
        ;;
    *)
        echo "未知命令: $1"
        help
        exit 1
        ;;
esac
