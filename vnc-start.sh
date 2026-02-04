#!/bin/bash
VNC_DISPLAY=":1"
VNC_GEOMETRY="1920x1080"
VNC_DEPTH="24"
NOVNC_PORT="6080"

echo "Starting VNC and noVNC services..."

if ! pgrep -f "Xtigervnc $VNC_DISPLAY" > /dev/null; then
    echo "Starting VNC server on display $VNC_DISPLAY"
    # Use -PasswordFile to avoid interactive password prompts
    # Check both possible password file locations
    if [ -f ~/.config/tigervnc/passwd ]; then
        PASSWD_FILE=~/.config/tigervnc/passwd
    else
        PASSWD_FILE=~/.vnc/passwd
    fi
    tigervncserver $VNC_DISPLAY -geometry $VNC_GEOMETRY -depth $VNC_DEPTH -xstartup ~/.vnc/xstartup -PasswordFile "$PASSWD_FILE" -SecurityTypes VncAuth
fi

if ! pgrep -f "websockify.*$NOVNC_PORT" > /dev/null; then
    echo "Starting noVNC web interface on port $NOVNC_PORT"
    websockify --web /usr/share/novnc/ $NOVNC_PORT localhost:5901 &
fi

echo "Services started!"
echo "Web interface: http://localhost:$NOVNC_PORT/vnc.html"
echo "Password: [hidden]"
