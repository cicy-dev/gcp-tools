#!/bin/bash
# Chrome Remote Debugger 启动脚本

# 停止现有 Chrome 进程
pkill -f chrome
sleep 2

# 启动 Chrome Remote Debugger
DISPLAY=:1 /opt/google/chrome/google-chrome   --remote-debugging-port=9222   --user-data-dir=/home/w3c_offical/data/browser/chrome   --no-first-run   --disable-features=DownloadBubble,DownloadBubbleV2   > /tmp/chrome.log 2>&1 &

# 等待启动
sleep 3

# 检查状态
if ss -tlnp 2>/dev/null | grep -q 9222; then
    echo '✅ Chrome Remote Debugger 已启动在端口 9222'
    curl -s http://localhost:9222/json/version | head -3
else
    echo '❌ 启动失败，查看日志: tail /tmp/chrome.log'
    exit 1
fi
