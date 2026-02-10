#!/bin/bash

# Firefox 管理脚本
USER_DATA_DIR="$HOME/data/browser/firefox"

case "$1" in
    install)
        echo "正在安装 Firefox..."
        sudo apt update
        sudo apt install -y firefox-esr
        echo "Firefox 安装完成"
        
        # 创建桌面快捷方式
        mkdir -p ~/Desktop
        cat > ~/Desktop/Firefox.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
Comment=启动 Firefox 浏览器
Exec=$HOME/tools/firefox.sh start
Icon=firefox-esr
Terminal=false
StartupNotify=true
Categories=Network;WebBrowser;
EOF
        chmod +x ~/Desktop/Firefox.desktop
        echo "桌面快捷方式已创建"
        ;;
    start)
        echo "启动 Firefox..."
        mkdir -p "$USER_DATA_DIR"
        firefox-esr --profile "$USER_DATA_DIR" &
        echo "Firefox 已启动"
        ;;
    help)
        echo "Firefox 管理脚本使用说明:"
        echo "  ./firefox.sh install  - 安装 Firefox"
        echo "  ./firefox.sh start    - 启动 Firefox"
        echo "  ./firefox.sh help     - 显示帮助信息"
        echo "  用户数据目录: $USER_DATA_DIR"
        ;;
    *)
        echo "用法: $0 {install|start|help}"
        exit 1
        ;;
esac
