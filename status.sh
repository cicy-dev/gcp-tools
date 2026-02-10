#!/bin/bash

# 系统和服务状态检查脚本
# 用于检查所有服务端口和软件状态

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 符号定义
CHECK_MARK="✓"
CROSS_MARK="✗"
WARNING_MARK="⚠"

# 统计变量
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# 打印标题
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 打印成功信息
print_success() {
    echo -e "${GREEN}${CHECK_MARK}${NC} $1"
    ((PASSED_CHECKS++))
    ((TOTAL_CHECKS++))
}

# 打印失败信息
print_error() {
    echo -e "${RED}${CROSS_MARK}${NC} $1"
    ((FAILED_CHECKS++))
    ((TOTAL_CHECKS++))
}

# 打印警告信息
print_warning() {
    echo -e "${YELLOW}${WARNING_MARK}${NC} $1"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
}

# 检查命令是否存在
check_command() {
    local cmd=$1
    local name=${2:-$cmd}
    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        print_success "$name 已安装: $version"
        return 0
    else
        print_error "$name 未安装"
        return 1
    fi
}

# 检查端口是否监听
check_port() {
    local port=$1
    local service=$2
    if ss -tuln | grep -q ":$port "; then
        print_success "$service (端口 $port) 正在监听"
        return 0
    else
        print_error "$service (端口 $port) 未监听"
        return 1
    fi
}

# 检查进程是否运行
check_process() {
    local pattern=$1
    local name=$2
    if pgrep -f "$pattern" > /dev/null; then
        local pid=$(pgrep -f "$pattern" | head -1)
        local count=$(pgrep -f "$pattern" | wc -l)
        print_success "$name 正在运行 (PID: $pid, 进程数: $count)"
        return 0
    else
        print_error "$name 未运行"
        return 1
    fi
}

# 检查 URL 是否可访问
check_url() {
    local url=$1
    local name=$2
    local timeout=${3:-5}
    if curl -s --max-time $timeout "$url" > /dev/null 2>&1; then
        print_success "$name ($url) 可访问"
        return 0
    else
        print_error "$name ($url) 不可访问"
        return 1
    fi
}

# 检查文件是否存在
check_file() {
    local file=$1
    local name=$2
    if [ -f "$file" ]; then
        print_success "$name 存在: $file"
        return 0
    else
        print_warning "$name 不存在: $file"
        return 1
    fi
}

# 检查目录是否存在
check_directory() {
    local dir=$1
    local name=$2
    if [ -d "$dir" ]; then
        print_success "$name 存在: $dir"
        return 0
    else
        print_warning "$name 不存在: $dir"
        return 1
    fi
}

# ============================================
# 开始检查
# ============================================

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      系统和服务状态检查工具 v1.0            ║${NC}"
echo -e "${BLUE}║      检查时间: $(date '+%Y-%m-%d %H:%M:%S')      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"

# ============================================
# 1. 系统信息
# ============================================
print_header "系统信息"

echo -e "主机名: $(hostname)"
echo -e "系统: $(uname -s) $(uname -r)"
echo -e "发行版: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo -e "运行时间: $(uptime -p 2>/dev/null || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
echo -e "负载: $(uptime | awk -F'load average:' '{print $2}')"

# CPU 和内存
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
mem_info=$(free -h | awk 'NR==2{printf "使用: %s / %s (%.1f%%)", $3, $2, $3*100/$2}')
echo -e "CPU 使用率: ${cpu_usage}%"
echo -e "内存: $mem_info"

disk_usage=$(df -h / | awk 'NR==2{printf "使用: %s / %s (%s)", $3, $2, $5}')
echo -e "磁盘 (/): $disk_usage"

# ============================================
# 2. 核心软件检查
# ============================================
print_header "核心软件检查"

check_command "google-chrome" "Google Chrome"
check_command "tigervncserver" "TigerVNC Server"
check_command "websockify" "Websockify"
check_command "cloudflared" "Cloudflared"
check_command "python3" "Python 3"
check_command "node" "Node.js"
check_command "npm" "NPM"
check_command "git" "Git"
check_command "curl" "cURL"
check_command "wget" "wget"
check_command "docker" "Docker"
check_command "tmux" "tmux"
check_command "mcp-proxy" "MCP Proxy"

# ============================================
# 3. 浏览器服务检查
# ============================================
print_header "浏览器服务检查"

# Chrome 远程调试
if pgrep -f "chrome --user-data-dir.*--remote-debugging-port" > /dev/null; then
    chrome_pid=$(pgrep -f "chrome --user-data-dir.*--remote-debugging-port" | head -1)
    print_success "Chrome 远程调试 正在运行 (PID: $chrome_pid)"
    check_url "http://localhost:9222/json/version" "Chrome DevTools API"
else
    print_error "Chrome 远程调试 未运行"
fi
# ============================================
# 4. tmux-mcp 服务检查
# ============================================
print_header "tmux-mcp 服务检查"

# tmux-mcp 进程检查
if pgrep -f "mcp-proxy.*8201" > /dev/null; then
    check_process "mcp-proxy.*8201" "tmux-mcp Server"
    check_port 8201 "tmux-mcp HTTP Port"

    # 检查 Token 文件
    check_file "$HOME/tmux-mcp-token.txt" "tmux-mcp API Token"

    # 检查日志文件
    if [ -f "$HOME/logs/tmux-mcp.log" ]; then
        check_file "$HOME/logs/tmux-mcp.log" "tmux-mcp 日志文件"
        last_log=$(tail -1 "$HOME/logs/tmux-mcp.log" 2>/dev/null)
        echo -e "  最新日志: $last_log"
    fi

    # 测试 API 连接
    if curl -s --max-time 3 "http://localhost:8201/mcp" > /dev/null 2>&1; then
        print_success "tmux-mcp API (http://localhost:8201/mcp) 可访问"
    else
        print_warning "tmux-mcp API (http://localhost:8201/mcp) 响应异常"
        ((WARNING_CHECKS++))
        ((TOTAL_CHECKS++))
    fi
else
    print_warning "tmux-mcp Server 未运行 (可选服务)"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
fi

# ============================================
# 5. VNC 服务检查
# ============================================
print_header "VNC 服务检查"

# TigerVNC
if check_process "Xtigervnc :1" "TigerVNC Server (Display :1)"; then
    check_port 5901 "VNC Port"
fi

# noVNC Web 界面
if check_process "websockify.*6080" "noVNC Web Interface"; then
    check_port 6080 "noVNC Web Port"
    check_url "http://localhost:6080/vnc.html" "noVNC Web UI" 3
fi

# VNC 配置文件
check_file "$HOME/.vnc/xstartup" "VNC xstartup"
if [ -f "$HOME/.config/tigervnc/passwd" ]; then
    check_file "$HOME/.config/tigervnc/passwd" "VNC 密码文件"
elif [ -f "$HOME/.vnc/passwd" ]; then
    check_file "$HOME/.vnc/passwd" "VNC 密码文件"
else
    print_warning "VNC 密码文件不存在"
    ((WARNING_CHECKS++))
    ((TOTAL_CHECKS++))
fi

# ============================================
# 6. Cloudflare Tunnel 检查
# ============================================
print_header "Cloudflare Tunnel 检查"

if check_process "cloudflared tunnel" "Cloudflared Tunnel"; then
    check_file "$HOME/logs/tunnel.log" "Cloudflare Tunnel 日志"

    # 检查最近的日志
    if [ -f "$HOME/logs/tunnel.log" ]; then
        last_log=$(tail -1 "$HOME/logs/tunnel.log" 2>/dev/null)
        echo -e "  最新日志: $last_log"
    fi
else
    if [ -z "$CF_TUNNEL" ]; then
        print_warning "Cloudflare Tunnel 未运行 (CF_TUNNEL 环境变量未设置)"
        ((WARNING_CHECKS++))
        ((TOTAL_CHECKS++))
    else
        print_error "Cloudflare Tunnel 未运行 (但 CF_TUNNEL 已设置)"
        ((FAILED_CHECKS++))
        ((TOTAL_CHECKS++))
    fi
fi

# ============================================
# 7. 网络端口检查
# ============================================
print_header "网络端口检查"

check_port 22 "SSH Server"
check_port 53 "DNS Server (systemd-resolved)"

# 检查其他活动端口
echo -e "\n${BLUE}所有监听端口:${NC}"
ss -tuln | grep LISTEN | awk '{print $5}' | sed 's/.*://' | sort -n | uniq | while read port; do
    echo -e "  端口 $port 正在监听"
done

# ============================================
# 8. 数据目录检查
# ============================================
print_header "数据目录检查"

check_directory "$HOME/data/browser/chrome" "Chrome 用户数据目录"
check_directory "$HOME/data/browser/firefox" "Firefox 用户数据目录"
check_directory "$HOME/logs" "日志目录"
check_directory "$HOME/tools" "工具脚本目录"

# ============================================
# 9. 脚本文件检查
# ============================================
print_header "管理脚本检查"

check_file "$HOME/tools/chrome.sh" "Chrome 管理脚本"
check_file "$HOME/tools/firefox.sh" "Firefox 管理脚本"
check_file "$HOME/tools/vnc-start.sh" "VNC 启动脚本"
check_file "$HOME/tools/cloudflared-tunnel.sh" "Cloudflare Tunnel 脚本"
check_file "$HOME/tools/tmux-mcp.sh" "tmux-mcp 管理脚本"
check_file "$HOME/tools/boot.sh" "启动脚本"

# ============================================
# 10. 进程监控
# ============================================
print_header "关键进程监控"

echo -e "\n${BLUE}Chrome 进程:${NC}"
if pgrep -af "google-chrome" > /dev/null; then
    pgrep -af "google-chrome" | grep -E "(google-chrome|--type=)" | head -5
else
    echo -e "  ${RED}无 Chrome 进程${NC}"
fi

echo -e "\n${BLUE}VNC 进程:${NC}"
if pgrep -f "Xtigervnc" > /dev/null || pgrep -f "websockify" > /dev/null; then
    pgrep -af "Xtigervnc" 2>/dev/null
    pgrep -af "websockify" 2>/dev/null
else
    echo -e "  ${YELLOW}无 VNC 进程${NC}"
fi

echo -e "\n${BLUE}Cloudflared 进程:${NC}"
if pgrep -af "cloudflared" > /dev/null; then
    pgrep -af "cloudflared"
else
    echo -e "  ${YELLOW}无 Cloudflared 进程${NC}"
fi

echo -e "\n${BLUE}tmux-mcp 进程:${NC}"
if pgrep -af "mcp-proxy" > /dev/null; then
    pgrep -af "mcp-proxy"
else
    echo -e "  ${YELLOW}无 tmux-mcp 进程${NC}"
fi

# ============================================
# 11. 快速诊断建议
# ============================================
print_header "快速诊断建议"

if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}发现 $FAILED_CHECKS 个错误，建议检查以下内容:${NC}\n"

    # Chrome 未运行
    if ! pgrep -f "chrome --user-data-dir.*--remote-debugging-port" > /dev/null; then
        echo -e "  • Chrome 未运行: ${YELLOW}bash ~/tools/chrome.sh start${NC}"
    fi

    # VNC 未运行
    if ! pgrep -f "Xtigervnc" > /dev/null; then
        echo -e "  • VNC 未运行: ${YELLOW}bash ~/tools/vnc-start.sh${NC}"
    fi

    # Cloudflared 未运行
    if ! pgrep -f "cloudflared tunnel" > /dev/null && [ -n "$CF_TUNNEL" ]; then
        echo -e "  • Cloudflare Tunnel 未运行: ${YELLOW}bash ~/tools/cloudflared-tunnel.sh${NC}"
    fi

    # tmux-mcp 未运行
    if ! pgrep -f "mcp-proxy.*8201" > /dev/null; then
        echo -e "  • tmux-mcp Server 未运行: ${YELLOW}bash ~/tools/tmux-mcp.sh daemon${NC}"
    fi

    # 软件未安装提示
    if ! command -v git &> /dev/null; then
        echo -e "  • Git 未安装: ${YELLOW}sudo apt install -y git${NC}"
    fi

    if ! command -v docker &> /dev/null; then
        echo -e "  • Docker 未安装: ${YELLOW}curl -fsSL https://get.docker.com | sh${NC}"
    fi

    if ! command -v firefox-esr &> /dev/null; then
        echo -e "  • Firefox 未安装 (可选): ${YELLOW}bash ~/tools/firefox.sh install${NC}"
    fi
fi

if [ $WARNING_CHECKS -gt 0 ]; then
    echo -e "${YELLOW}发现 $WARNING_CHECKS 个警告，这些可能不影响核心功能${NC}"
fi

# ============================================
# 总结
# ============================================
print_header "检查总结"

echo -e "总检查项: ${BLUE}$TOTAL_CHECKS${NC}"
echo -e "通过: ${GREEN}$PASSED_CHECKS${NC}"
echo -e "失败: ${RED}$FAILED_CHECKS${NC}"
echo -e "警告: ${YELLOW}$WARNING_CHECKS${NC}"

success_rate=$(awk "BEGIN {printf \"%.1f\", ($PASSED_CHECKS/$TOTAL_CHECKS)*100}")
echo -e "成功率: ${GREEN}${success_rate}%${NC}"

echo ""
if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   所有关键服务运行正常！ ✓            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   发现问题，请检查上述错误信息        ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    exit 1
fi
