#!/bin/bash

# Antigravity Script - Python Easter Egg
# Opens the famous xkcd comic about Python

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

install() {
    print_info "检查 Python 安装..."

    if ! command -v python3 &> /dev/null; then
        print_info "安装 Python3..."
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip
        print_success "Python3 安装完成"
    else
        print_success "Python3 已安装: $(python3 --version)"
    fi

    # 检查浏览器
    if ! command -v google-chrome &> /dev/null && ! command -v firefox &> /dev/null; then
        print_info "未检测到浏览器，尝试安装 Firefox..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y firefox-esr
    fi

    print_success "Antigravity 依赖已就绪"
}

start() {
    print_info "启动 Antigravity..."

    # 检查 Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python3 未安装，请先运行: $0 install"
        exit 1
    fi

    # xkcd Antigravity 漫画链接
    XKCD_URL="https://xkcd.com/353/"

    # 优先使用 Chrome（如果在 VNC 中运行）
    if [ -n "$DISPLAY" ] && command -v google-chrome &> /dev/null; then
        print_success "在浏览器中打开 xkcd Antigravity 漫画..."
        google-chrome "$XKCD_URL" &>/dev/null &
    else
        # 使用 Python 的 antigravity 模块
        cat > /tmp/antigravity.py << 'EOF'
import antigravity
EOF
        print_success "使用 Python antigravity 模块打开漫画..."
        python3 /tmp/antigravity.py &>/dev/null &
    fi

    sleep 1
    print_success "Antigravity 已启动！"
    print_info "这是 Python 的经典彩蛋：import antigravity"
    print_info "漫画链接: $XKCD_URL"
}

google() {
    print_info "启动 Google Antigravity..."

    # Google Antigravity Easter Egg
    GOOGLE_URL="https://antigravity.google/download"

    # 检查浏览器
    if [ -n "$DISPLAY" ] && command -v google-chrome &> /dev/null; then
        print_success "在浏览器中打开 Google Antigravity..."
        google-chrome "$GOOGLE_URL" &>/dev/null &
    elif command -v firefox &> /dev/null; then
        print_success "在 Firefox 中打开 Google Antigravity..."
        firefox "$GOOGLE_URL" &>/dev/null &
    else
        print_error "未找到浏览器，请先安装 Chrome 或 Firefox"
        exit 1
    fi

    sleep 1
    print_success "Google Antigravity 已启动！"
    print_info "这是 Google 的反重力彩蛋"
    print_info "链接: $GOOGLE_URL"
}

help() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}  Antigravity 使用说明${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo -e "  $0 ${GREEN}install${NC}  - 安装 Python3 和依赖"
    echo -e "  $0 ${GREEN}start${NC}    - 启动 Antigravity (打开 xkcd 漫画)"
    echo -e "  $0 ${GREEN}google${NC}   - 打开 Google Antigravity 彩蛋"
    echo -e "  $0 ${GREEN}help${NC}     - 显示此帮助信息"
    echo ""
    echo -e "${YELLOW}关于 Antigravity:${NC}"
    echo "  这是 Python 的著名彩蛋之一"
    echo "  在 Python 中输入 'import antigravity' 会打开"
    echo "  xkcd 第 353 号漫画，讲述 Python 的简洁之美"
    echo ""
    echo -e "${YELLOW}Google Antigravity:${NC}"
    echo "  Google 的反重力彩蛋，一个有趣的互动体验"
    echo "  链接: https://antigravity.google/download"
    echo ""
    echo -e "${YELLOW}漫画内容:${NC}"
    echo "  标题: Python"
    echo "  链接: https://xkcd.com/353/"
    echo "  主题: Python 让编程变得如此简单，"
    echo "        就像违反了重力定律一样"
    echo ""
    echo -e "${GREEN}享受 Python 和 Google 的魔力！ 🚀${NC}"
}

# 主逻辑
case "$1" in
    install)
        install
        ;;
    start)
        start
        ;;
    google)
        google
        ;;
    help|--help|-h)
        help
        ;;
    *)
        print_error "未知命令: $1"
        echo ""
        help
        exit 1
        ;;
esac
