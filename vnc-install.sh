#!/bin/bash

# VNC and noVNC One-Click Installer
# Supports Ubuntu/Debian systems (Container-friendly)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VNC_DISPLAY=":1"
VNC_GEOMETRY="${VNC_GEOMETRY:-1920x1080}"
VNC_DEPTH="24"
NOVNC_PORT="${NOVNC_PORT:-6080}"

VNC_PASSWORD="${VNC_PASSWORD:-0}"

# 检查密码是否为默认值
if [ "$VNC_PASSWORD" = "0" ]; then
    echo -e "${RED}错误: VNC 密码未设置！${NC}"
    echo "请设置环境变量，例如：export VNC_PASSWORD=你的密码"
    exit 1
fi

# 如果最终结果仍然为空，则报错并退出
if [ -z "$VNC_PASSWORD" ]; then
    echo -e "${RED}错误: VNC_PASSWORD 和 JUPYTER_TOKEN 均为空！${NC}"
    echo "请先设置环境变量，例如：export JUPYTER_TOKEN=你的密码"
    exit 1
fi


# Functions
print_header() {
    echo -e "${BLUE}"
    echo "==================================="
    echo "  VNC & noVNC Installer"
    echo "==================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

install_packages() {

    print_info "Setting timezone to UTC+8 (container-friendly)..."
    # Use container-friendly timezone setting
    sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime || true
    echo 'Asia/Shanghai' | sudo tee /etc/timezone > /dev/null || true

    # 1. 定义需要安装的组件列表
    DESKTOP_PKGS=(
        "tigervnc-standalone-server"
        "xfce4"
        "xfce4-goodies"
        "xterm"
        "dbus-x11"
        "fonts-noto-cjk"
        "fcitx5"
        "websockify"
        "novnc"
        "fcitx5-chinese-addons"
    )

    # 2. 筛选出尚未安装的软件包
    MISSING_PKGS=()
    for pkg in "${DESKTOP_PKGS[@]}"; do
        if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
            MISSING_PKGS+=("$pkg")
        fi
    done

    # 3. 如果存在缺失包，则执行安装
    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        echo "检测到缺失组件: ${MISSING_PKGS[*]}"
        echo "正在更新系统并安装桌面环境..."
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING_PKGS[@]}"
    else
        echo "✅ 桌面环境组件已完整安装，跳过此步骤。"
    fi
}

setup_vnc_password() {
    print_info "Setting up VNC password..."
    mkdir -p ~/.vnc
    mkdir -p ~/.config/tigervnc

    # Create password file using tigervncpasswd -f (non-interactive)
    echo "$VNC_PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd 2>/dev/null

    # Also copy to config directory for newer TigerVNC versions
    cp ~/.vnc/passwd ~/.config/tigervnc/passwd 2>/dev/null || true

    chmod 600 ~/.vnc/passwd
    chmod 600 ~/.config/tigervnc/passwd 2>/dev/null || true

    print_success "VNC password set"
}

create_startup_scripts() {
    print_info "Creating startup scripts..."

    # VNC startup script
    cat > ~/.vnc/xstartup << 'EOF'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export GTK_IM_MODULE=fcitx5
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx5
fcitx5 -d &

# Start Chrome with remote debugging
if [ -f "$HOME/Desktop/tools/chrome.sh" ]; then
    bash "$HOME/Desktop/tools/chrome.sh" start &
fi

exec startxfce4
EOF

    chmod +x ~/.vnc/xstartup
    print_success "Startup scripts created"
}

start_services() {
    print_info "Starting VNC and noVNC services..."
    ~/Desktop/Desktop/tools/vnc-start.sh
}

show_connection_info() {
    echo ""
    echo -e "${GREEN}=== Installation Complete! ===${NC}"
    echo ""
    echo -e "${BLUE}🌐 Web Access:${NC}"
    echo -e "   URL: ${YELLOW}http://localhost:$NOVNC_PORT/vnc.html${NC}"
    echo -e "   Password: ${YELLOW}[hidden]${NC}"
    echo ""
    echo -e "${GREEN}Enjoy your remote desktop! 🚀${NC}"
}



# Main installation process
main() {
    print_header
    
    print_info "Container-friendly VNC installation"
    VNC_GEOMETRY="1920x1080"

    install_packages
    setup_vnc_password
    create_startup_scripts
    start_services
    show_connection_info
}

main
