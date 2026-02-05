#!/bin/bash

# tmux-mcp HTTP 服务器 - 跨平台解决方案
# 支持 Linux 和 macOS
# 使用方法: ./tmux-mcp.sh [start|stop|status|test|help]

set -e

# 配置参数
PORT=${TMUX_MCP_PORT:-8201}
HOST=${TMUX_MCP_HOST:-0.0.0.0}
API_TOKEN=${TMUX_MCP_TOKEN:-}
DISPLAY_VAR=${TMUX_MCP_DISPLAY:-${DISPLAY:-:0}}
PID_FILE="$HOME/logs/tmux-mcp.pid"
LOG_FILE="$HOME/logs/tmux-mcp.log"
TOKEN_FILE="$HOME/tmux-mcp-token.txt"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_info "检测到 Linux 环境"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_info "检测到 macOS 环境"
    else
        print_error "不支持的操作系统: $OSTYPE"
        print_error "仅支持 Linux 和 macOS"
        exit 1
    fi
}

# 安装依赖（Linux 专用）
install_dependencies() {
    print_info "检查并安装依赖..."

    # 确保日志目录存在
    mkdir -p "$HOME/logs"

    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        print_info "安装 Node.js..."
        if command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs
        else
            print_error "无法自动安装 Node.js，请手动安装"
            exit 1
        fi
    fi
    
    # 检查 tmux
    if ! command -v tmux &> /dev/null; then
        print_info "安装 tmux..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y tmux
        elif command -v yum &> /dev/null; then
            sudo yum install -y tmux
        fi
    fi
    
    # 安装 mcp-proxy
    if ! command -v mcp-proxy &> /dev/null; then
        print_info "安装 mcp-proxy..."
        sudo npm install -g mcp-proxy
    fi
    
    # 生成或加载 API Token
    if [ -z "$API_TOKEN" ]; then
        # 检查是否存在 token.txt 文件
        if [ -f "$TOKEN_FILE" ]; then
            API_TOKEN=$(cat "$TOKEN_FILE")
            print_success "从 $TOKEN_FILE 加载已存在的 API Token: ${API_TOKEN:0:16}..."
        else
            # 生成新的 token
            if command -v openssl &> /dev/null; then
                API_TOKEN=$(openssl rand -hex 32)
                print_success "已生成新的 API Token: ${API_TOKEN:0:16}..."
            else
                API_TOKEN="tmux-mcp-$(date +%s)-$(whoami)"
                print_warning "openssl 未找到，使用默认 Token"
            fi
            
            # 保存 token 到文件
            echo "$API_TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"  # 设置安全权限
            print_info "API Token 已保存到 $TOKEN_FILE"
        fi
    else
        print_info "使用环境变量中的 API Token: ${API_TOKEN:0:16}..."
        # 如果使用自定义 token，也保存到文件中
        echo "$API_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        print_info "API Token 已保存到 $TOKEN_FILE"
    fi
    
    print_success "依赖检查完成"
}

# 检查端口
check_port() {
    if command -v lsof &> /dev/null; then
        if lsof -i :$PORT &> /dev/null; then
            print_error "端口 $PORT 已被占用"
            lsof -i :$PORT
            return 1
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -tlnp 2>/dev/null | grep ":$PORT " &> /dev/null; then
            print_error "端口 $PORT 已被占用"
            return 1
        fi
    fi
    return 0
}

# 打开 tmux 窗口显示
open_tmux_window() {
    local SHOW_WINDOW=${1:-false}
    
    if [ "$SHOW_WINDOW" = "false" ]; then
        return 0
    fi
    
    print_info "打开 tmux 窗口显示..."
    
    # 创建或连接到 tmux 会话
    local SESSION_NAME="tmux-mcp-server"
    
    # 检查会话是否已存在
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        print_info "tmux 会话 '$SESSION_NAME' 已存在"
    else
        # 创建新会话
        tmux new-session -d -s "$SESSION_NAME" -c "$(pwd)"
        print_success "创建 tmux 会话: $SESSION_NAME"
    fi
    
    # 根据操作系统打开终端窗口
    if [[ "$OS" == "macos" ]]; then
        # macOS: 使用 osascript 打开新的 Terminal 窗口并连接到 tmux 会话
        osascript <<EOF
tell application "Terminal"
    activate
    do script "tmux attach-session -t $SESSION_NAME"
end tell
EOF
        print_success "已在 macOS Terminal 中打开 tmux 会话"
        
    elif [[ "$OS" == "linux" ]]; then
        # Linux: 检查 DISPLAY 环境变量并尝试多种终端模拟器
        local CURRENT_DISPLAY="$DISPLAY_VAR"
        
        # 如果没有设置 DISPLAY，尝试常见的显示器
        if [ -z "$CURRENT_DISPLAY" ] || [ "$CURRENT_DISPLAY" = ":0" ]; then
            if [ -S "/tmp/.X11-unix/X1" ]; then
                CURRENT_DISPLAY=":1.0"
            elif [ -S "/tmp/.X11-unix/X0" ]; then
                CURRENT_DISPLAY=":0"
            else
                print_warning "未检测到 X11 显示器，尝试使用 :0"
                CURRENT_DISPLAY=":0"
            fi
        fi
        
        print_info "使用显示器: $CURRENT_DISPLAY"
        
        # 优先使用 xterm（按照用户建议的格式）
        if command -v xterm &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY xterm -title \"tmux-mcp-server\" -geometry 120x40 -bg black -fg green -e \"tmux attach-session -t $SESSION_NAME\""
        elif command -v gnome-terminal &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY gnome-terminal --title=\"tmux-mcp-server\" -- tmux attach-session -t $SESSION_NAME"
        elif command -v konsole &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY konsole --title \"tmux-mcp-server\" -e tmux attach-session -t $SESSION_NAME"
        elif command -v terminator &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY terminator --title=\"tmux-mcp-server\" -e 'tmux attach-session -t $SESSION_NAME'"
        elif command -v alacritty &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY alacritty --title \"tmux-mcp-server\" -e tmux attach-session -t $SESSION_NAME"
        elif command -v kitty &> /dev/null; then
            TERMINAL_CMD="DISPLAY=$CURRENT_DISPLAY kitty --title=\"tmux-mcp-server\" tmux attach-session -t $SESSION_NAME"
        else
            print_warning "未找到支持的终端模拟器"
            print_info "请手动运行: DISPLAY=$CURRENT_DISPLAY tmux attach-session -t $SESSION_NAME"
            return 1
        fi
        
        # 在后台启动终端
        if [ -n "$TERMINAL_CMD" ]; then
            print_info "执行命令: $TERMINAL_CMD"
            eval "$TERMINAL_CMD" &
            print_success "已在 Linux 终端中打开 tmux 会话 (DISPLAY=$CURRENT_DISPLAY)"
        fi
    fi
    
    # 在 tmux 会话中显示服务器信息
    tmux send-keys -t "$SESSION_NAME" "clear" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '=== tmux-mcp 服务器监控 ==='" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '服务器地址: http://$HOST:$PORT/mcp'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '日志文件: $LOG_FILE'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '使用以下命令管理服务器:'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '  ./tmux-mcp.sh status   - 检查状态'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '  ./tmux-mcp.sh stop     - 停止服务器'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '  ./tmux-mcp.sh logs     - 查看日志'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '  ./tmux-mcp.sh test     - 测试连接'" C-m
    tmux send-keys -t "$SESSION_NAME" "echo ''" C-m
    tmux send-keys -t "$SESSION_NAME" "echo '按 Ctrl+C 退出此窗口（不会停止服务器）'" C-m
    
    return 0
}

# 启动服务器
start_server() {
    local DAEMON_MODE=${1:-false}
    local SHOW_WINDOW=${2:-false}
    
    if [ "$DAEMON_MODE" = "true" ]; then
        print_info "启动 tmux-mcp HTTP 服务器 (后台模式)..."
    else
        print_info "启动 tmux-mcp HTTP 服务器..."
    fi
    
    # 检查是否已运行
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            print_warning "服务器已在运行 (PID: $PID)"
            return 1
        else
            print_info "清理过期的 PID 文件"
            rm -f "$PID_FILE"
        fi
    fi
    
    detect_os
    install_dependencies
    
    if ! check_port; then
        print_error "端口检查失败"
        return 1
    fi
    
    # 启动服务器
    print_info "在端口 $PORT 启动服务器..."
    
    if [ "$DAEMON_MODE" = "true" ]; then
        # 后台模式：完全分离进程
        nohup mcp-proxy --port "$PORT" --host "$HOST" --token "$API_TOKEN" --shell "npx -y tmux-mcp" > "$LOG_FILE" 2>&1 < /dev/null &
        SERVER_PID=$!
        disown
        echo $SERVER_PID > "$PID_FILE"
        
        # 等待启动
        sleep 3
        
        if kill -0 "$SERVER_PID" 2>/dev/null; then
            print_success "服务器已在后台启动"
            print_info "服务器地址: http://$HOST:$PORT/mcp"
            print_info "Token 文件: $TOKEN_FILE"
            print_info "日志文件: $LOG_FILE"
            print_info "使用 './tmux-mcp.sh status' 检查状态"
            print_info "使用 './tmux-mcp.sh token' 查看 API Token"
            print_info "使用 './tmux-mcp.sh logs' 查看日志"
            
            # 如果需要显示窗口，则打开 tmux 窗口
            if [ "$SHOW_WINDOW" = "true" ]; then
                open_tmux_window true
            fi
            
            return 0
        else
            print_error "服务器启动失败"
            return 1
        fi
    else
        # 前台模式
        nohup mcp-proxy --port "$PORT" --host "$HOST" --token "$API_TOKEN" --shell "npx -y tmux-mcp" > "$LOG_FILE" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$PID_FILE"
        
        # 等待启动
        sleep 3
        
        if kill -0 "$SERVER_PID" 2>/dev/null; then
            print_success "服务器已启动"
            print_info "服务器地址: http://$HOST:$PORT/mcp"
            print_info "Token 文件: $TOKEN_FILE"
            print_info "日志文件: $LOG_FILE"
            print_info "使用 './tmux-mcp.sh token' 查看 API Token"
            
            # 如果需要显示窗口，则打开 tmux 窗口
            if [ "$SHOW_WINDOW" = "true" ]; then
                open_tmux_window true
            fi
            
            return 0
        else
            print_error "服务器启动失败"
            return 1
        fi
    fi
}

# 停止服务器
stop_server() {
    print_info "停止 tmux-mcp 服务器..."
    
    if [ ! -f "$PID_FILE" ]; then
        print_warning "服务器未运行"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        
        # 等待进程结束
        for i in {1..5}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done
        
        # 强制终止
        if kill -0 "$PID" 2>/dev/null; then
            kill -9 "$PID"
        fi
        
        print_success "服务器已停止"
    else
        print_warning "进程不存在"
    fi
    
    rm -f "$PID_FILE"
}



# 显示 token
show_token() {
    print_info "显示 API Token..."
    
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(cat "$TOKEN_FILE")
        print_success "当前 API Token: $TOKEN"
        print_info "Token 文件: $TOKEN_FILE"
        
        # 显示文件权限
        ls -la "$TOKEN_FILE"
        
        return 0
    else
        print_error "Token 文件不存在: $TOKEN_FILE"
        print_info "请先启动服务器生成 Token"
        return 1
    fi
}

# 重新生成 token
regenerate_token() {
    print_info "重新生成 API Token..."
    
    # 检查服务器是否在运行
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            print_error "服务器正在运行，请先停止服务器"
            print_info "运行: ./tmux-mcp.sh stop"
            return 1
        fi
    fi
    
    # 备份旧 token
    if [ -f "$TOKEN_FILE" ]; then
        cp "$TOKEN_FILE" "${TOKEN_FILE}.backup"
        print_info "旧 Token 已备份到 ${TOKEN_FILE}.backup"
    fi
    
    # 生成新 token
    if command -v openssl &> /dev/null; then
        NEW_TOKEN=$(openssl rand -hex 32)
    else
        NEW_TOKEN="tmux-mcp-$(date +%s)-$(whoami)"
    fi
    
    # 保存新 token
    echo "$NEW_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    
    print_success "新 API Token 已生成: ${NEW_TOKEN:0:16}..."
    print_info "Token 已保存到 $TOKEN_FILE"
    print_warning "请更新客户端配置中的 Token"
}
check_status() {
    print_info "检查服务器状态..."
    
    if [ ! -f "$PID_FILE" ]; then
        print_warning "服务器未运行"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    
    if kill -0 "$PID" 2>/dev/null; then
        print_success "服务器运行中"
        print_info "服务器地址: http://$HOST:$PORT/mcp"
        
        # 显示端口信息
        if command -v lsof &> /dev/null; then
            print_info "端口信息:"
            lsof -i :$PORT 2>/dev/null || echo "  无法获取端口信息"
        fi
        
        return 0
    else
        print_warning "进程不存在，清理 PID 文件"
        rm -f "$PID_FILE"
        return 1
    fi
}

# 测试服务器
test_server() {
    print_info "测试服务器连接..."
    
    if ! check_status > /dev/null; then
        print_error "服务器未运行"
        return 1
    fi
    
    print_info "发送初始化请求..."
    
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' \
        "http://$HOST:$PORT/mcp" 2>/dev/null)
    
    if echo "$RESPONSE" | grep -q "tmux-mcp"; then
        print_success "服务器响应正常"
        print_info "响应: $(echo "$RESPONSE" | head -c 100)..."
        return 0
    else
        print_error "服务器无响应或响应异常"
        print_info "响应: $RESPONSE"
        return 1
    fi
}

# API 测试
api_test() {
    print_info "执行完整 API 测试..."
    
    if ! check_status > /dev/null; then
        print_error "服务器未运行"
        return 1
    fi
    
    print_info "测试 1: 初始化连接"
    INIT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json, text/event-stream" \
        -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"roots":{"listChanged":true},"sampling":{}},"clientInfo":{"name":"api-test","version":"1.0.0"}}}' \
        "http://$HOST:$PORT/mcp" 2>/dev/null)
    
    if echo "$INIT_RESPONSE" | grep -q "tmux-mcp"; then
        print_success "✓ 初始化测试通过"
        
        print_info "测试 2: 获取工具列表"
        TOOLS_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json, text/event-stream" \
            -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
            "http://$HOST:$PORT/mcp" 2>/dev/null)
        
        if echo "$TOOLS_RESPONSE" | grep -q "tools\|result"; then
            print_success "✓ 工具列表测试通过"
        else
            print_warning "⚠ 工具列表测试失败（可能需要会话管理）"
        fi
        
        print_info "测试 3: 获取资源列表"
        RESOURCES_RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json, text/event-stream" \
            -d '{"jsonrpc":"2.0","id":3,"method":"resources/list","params":{}}' \
            "http://$HOST:$PORT/mcp" 2>/dev/null)
        
        if echo "$RESOURCES_RESPONSE" | grep -q "resources\|result"; then
            print_success "✓ 资源列表测试通过"
        else
            print_warning "⚠ 资源列表测试失败（可能需要会话管理）"
        fi
        
        print_success "API 测试完成"
        return 0
    else
        print_error "初始化测试失败"
        print_info "响应: $INIT_RESPONSE"
        return 1
    fi
}

# 显示帮助
show_help() {
    echo "========================================"
    echo "  tmux-mcp HTTP 服务器管理脚本"
    echo "========================================"
    echo ""
    echo "描述:"
    echo "  跨平台 tmux-mcp HTTP 服务器管理工具"
    echo "  支持 Linux 和 macOS 系统"
    echo "  提供 MCP (Model Context Protocol) 服务"
    echo ""
    echo "用法:"
    echo "  $0 [命令] [选项]"
    echo ""
    echo "基本命令:"
    echo "  start       - 前台启动服务器"
    echo "  start-gui   - 前台启动服务器并显示 tmux 监控窗口"
    echo "  daemon      - 后台启动服务器（推荐）"
    echo "  daemon-gui  - 后台启动服务器并显示 tmux 监控窗口"
    echo "  stop        - 停止服务器"
    echo "  restart     - 重启服务器"
    echo "  restart-gui - 重启服务器并显示 tmux 监控窗口"
    echo ""
    echo "状态和测试:"
    echo "  status      - 检查服务器运行状态"
    echo "  test        - 测试服务器连接"
    echo "  api_test    - 执行完整的 API 功能测试"
    echo ""
    echo "Token 管理:"
    echo "  token       - 显示当前 API Token"
    echo "  regen_token - 重新生成 API Token（需要先停止服务器）"
    echo ""
    echo "日志和监控:"
    echo "  logs        - 实时查看服务器日志"
    echo "  show-tmux   - 显示 tmux 监控窗口"
    echo ""
    echo "帮助:"
    echo "  help        - 显示此帮助信息"
    echo "  --help, -h  - 显示此帮助信息"
    echo ""
    echo "环境变量配置:"
    echo "  TMUX_MCP_PORT    - 服务器端口 (默认: 8201)"
    echo "  TMUX_MCP_HOST    - 服务器绑定地址 (默认: 0.0.0.0，监听所有接口)"
    echo "  TMUX_MCP_TOKEN   - API 认证令牌 (默认: 自动生成 64 位随机字符串)"
    echo "  TMUX_MCP_DISPLAY - Linux X11 显示器 (默认: \$DISPLAY 或 :0)"
    echo ""
    echo "文件位置:"
    echo "  PID 文件: /tmp/tmux-mcp.pid"
    echo "  日志文件: /tmp/tmux-mcp.log"
    echo "  Token 文件: /tmp/token.txt"
    echo ""
    echo "使用示例:"
    echo "  # 基本使用"
    echo "  $0 daemon                             # 后台启动服务器"
    echo "  $0 daemon-gui                         # 后台启动并显示监控窗口"
    echo "  $0 status                             # 检查状态"
    echo "  $0 test                               # 测试连接"
    echo "  $0 stop                               # 停止服务器"
    echo ""
    echo "  # 自定义配置"
    echo "  TMUX_MCP_PORT=8202 $0 daemon-gui     # 使用自定义端口"
    echo "  TMUX_MCP_HOST=127.0.0.1 $0 daemon    # 仅监听本地接口"
    echo "  TMUX_MCP_TOKEN=my-token $0 daemon     # 使用自定义 Token"
    echo ""
    echo "  # Linux 特定"
    echo "  TMUX_MCP_DISPLAY=:1.0 $0 start-gui   # 指定 X11 显示器"
    echo ""
    echo "  # 日志和调试"
    echo "  $0 logs                               # 查看实时日志"
    echo "  $0 api_test                           # 完整 API 测试"
    echo "  $0 token                              # 查看当前 Token"
    echo ""
    echo "连接信息:"
    echo "  服务器默认运行在: http://0.0.0.0:8201/mcp"
    echo "  需要使用 Bearer Token 进行认证"
    echo "  Token 会自动生成并保存到 /tmp/token.txt"
    echo ""
    echo "注意事项:"
    echo "  1. 首次运行会自动安装依赖 (Node.js, tmux, mcp-proxy)"
    echo "  2. Token 文件权限设置为 600 (仅所有者可读写)"
    echo "  3. 服务器进程在后台运行，重启系统后需要重新启动"
    echo "  4. 使用 daemon 模式可以让服务器在后台持续运行"
    echo "  5. 日志文件位于 /tmp 目录，系统重启后会被清理"
    echo ""
    echo "故障排除:"
    echo "  - 端口被占用: 使用 TMUX_MCP_PORT 环境变量指定其他端口"
    echo "  - 权限问题: 确保有执行脚本和安装软件包的权限"
    echo "  - 连接失败: 检查防火墙设置和网络配置"
    echo "  - Token 问题: 使用 regen_token 命令重新生成"
    echo ""
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_server false false
            ;;
        start-gui)
            start_server false true
            ;;
        daemon)
            start_server true false
            ;;
        daemon-gui)
            start_server true true
            ;;
        stop)
            stop_server
            ;;
        status)
            check_status
            ;;
        test)
            test_server
            ;;
        api_test)
            api_test
            ;;
        token)
            show_token
            ;;
        regen_token)
            regenerate_token
            ;;
        restart)
            stop_server
            sleep 2
            start_server false false
            ;;
        restart-gui)
            stop_server
            sleep 2
            start_server false true
            ;;
        show-tmux)
            detect_os
            open_tmux_window true
            ;;
        logs)
            if [ -f "$LOG_FILE" ]; then
                tail -f "$LOG_FILE"
            else
                print_error "日志文件不存在"
            fi
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"