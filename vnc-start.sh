#!/bin/bash
# 接收参数: ./vnc-start.sh [Display编号] [noVNC端口]
# 默认值: Display=:1, Port=6080
DISPLAY_NUM="${1:-1}"
VNC_DISPLAY=":$DISPLAY_NUM"
NOVNC_PORT="${2:-6080}"
VNC_PORT=$((5900 + DISPLAY_NUM))

VNC_GEOMETRY="1920x1080"
VNC_DEPTH="24"

echo "Checking services for Display $VNC_DISPLAY on noVNC port $NOVNC_PORT..."

# 1. 启动特定编号的 VNC 实例
if ! pgrep -f "Xtigervnc $VNC_DISPLAY" > /dev/null; then
    echo "Starting VNC server on display $VNC_DISPLAY"
    PASSWD_FILE=~/.vnc/passwd
    [ -f ~/.config/tigervnc/passwd ] && PASSWD_FILE=~/.config/tigervnc/passwd
    
    # 这里的核心是每一个 Display 都可以独立启动
    tigervncserver $VNC_DISPLAY -geometry $VNC_GEOMETRY -depth $VNC_DEPTH \
                   -xstartup ~/.vnc/xstartup -PasswordFile "$PASSWD_FILE" -SecurityTypes VncAuth
fi

# 2. 启动特定端口的 websockify 实例
if ! pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
    echo "Starting noVNC web interface on port $NOVNC_PORT (mapping to $VNC_PORT)"
    websockify --web /usr/share/novnc/ $NOVNC_PORT localhost:$VNC_PORT &
fi

echo "Display $VNC_DISPLAY is ready at http://localhost:$NOVNC_PORT/vnc.html"