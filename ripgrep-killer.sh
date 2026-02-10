#!/bin/bash
# ripgrep CPU 监控和自动终止脚本

LOG_FILE="$HOME/logs/ripgrep_killer.log"
CPU_THRESHOLD=50  # ripgrep CPU超过50%就杀

while true; do
    # 查找 ripgrep 进程的 CPU 使用率
    RG_CPU=$(ps aux | grep -E '[r]ipgrep|[/]rg' | awk '{sum+=$3} END {print int(sum)}')
    
    if [ ! -z "$RG_CPU" ] && [ "$RG_CPU" -gt "$CPU_THRESHOLD" ]; then
        echo "$(date): ripgrep CPU=${RG_CPU}%, 超过阈值 ${CPU_THRESHOLD}%, 正在终止..." >> $LOG_FILE
        pkill -9 -f ripgrep 2>/dev/null
        pkill -9 rg 2>/dev/null
        # 如果普通权限失败，尝试sudo
        if pgrep -f ripgrep > /dev/null; then
            sudo pkill -9 -f ripgrep 2>/dev/null
            sudo pkill -9 rg 2>/dev/null
        fi
        echo "$(date): ripgrep 已终止" >> $LOG_FILE
    fi
    
    sleep 5  # 每5秒检查一次
done
