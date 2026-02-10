#!/bin/bash

# --- 配置参数 ---
CPU_THRESHOLD=80          # CPU 利用率阈值 (%)
LOG_FILE="$HOME/logs/sys_monitor.log"

echo "--- 监控脚本启动: $(date) ---" >> $LOG_FILE

while true; do
    # 检查 CPU 占用超过 80% 的进程
    ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | awk 'NR>1 && $4>80 {print $0}' | while read pid ppid cmd cpu_usage; do
        # 检查是否是 code-server 相关进程
        if echo "$cmd" | grep -q "code-server"; then
            echo "$(date): [警告] code-server 进程 PID=$pid CPU=${cpu_usage}% 超过阈值，正在重启..." >> $LOG_FILE
            kill -9 $pid
            sleep 2
            sudo systemctl restart code-server@w3c_offical 2>/dev/null || echo "$(date): [错误] 无法重启 code-server" >> $LOG_FILE
        else
            echo "$(date): [警告] 进程 PID=$pid CPU=${cpu_usage}% 超过阈值，已终止: $cmd" >> $LOG_FILE
            kill -9 $pid
        fi
    done

    sleep 30 # 每 30 秒检查一次
done