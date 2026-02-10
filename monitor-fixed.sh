#!/bin/bash

# --- 配置参数 ---
CPU_THRESHOLD=80
LOG_FILE="$HOME/logs/sys_monitor.log"
CHECK_INTERVAL=30

# 白名单：不可杀死的进程关键词
WHITELIST=(
    "systemd"
    "avahi-daemon"
    "dbus"
    "sshd"
    "Xvnc"
    "bash"
    "monitor"
    "init"
)

# 检查进程是否在白名单
is_whitelisted() {
    local cmd="$1"
    for keyword in "${WHITELIST[@]}"; do
        if echo "$cmd" | grep -qi "$keyword"; then
            return 0
        fi
    done
    return 1
}

echo "=== 监控脚本启动: $(date) ===" >> "$LOG_FILE"

while true; do
    # 正确获取 CPU 占用超过阈值的进程
    ps -eo pid,ppid,cmd,%cpu --sort=-%cpu | awk -v threshold="$CPU_THRESHOLD" '
        NR > 1 && $NF > threshold {
            # 提取 PID 和 CPU，命令部分可能包含空格
            pid = $1
            cpu = $NF
            cmd = ""
            for (i=3; i<NF; i++) cmd = cmd $i " "
            print pid "|" cpu "|" cmd
        }
    ' | while IFS='|' read -r pid cpu_usage cmd; do
        
        # 跳过空行
        [ -z "$pid" ] && continue
        
        # 检查白名单
        if is_whitelisted "$cmd"; then
            echo "$(date): [跳过] 白名单进程 PID=$pid CPU=${cpu_usage}%: $cmd" >> "$LOG_FILE"
            continue
        fi
        
        # 检查是否是 code-server
        if echo "$cmd" | grep -q "code-server"; then
            echo "$(date): [警告] code-server 进程 PID=$pid CPU=${cpu_usage}% 超过阈值，正在重启..." >> "$LOG_FILE"
            kill -15 "$pid" 2>/dev/null  # 优雅终止
            sleep 2
            sudo systemctl restart code-server@w3c_offical 2>/dev/null || \
                echo "$(date): [错误] 无法重启 code-server" >> "$LOG_FILE"
        else
            echo "$(date): [终止] 进程 PID=$pid CPU=${cpu_usage}% 超过阈值: $cmd" >> "$LOG_FILE"
            kill -15 "$pid" 2>/dev/null  # 优雅终止，不用 -9
        fi
    done
    
    sleep "$CHECK_INTERVAL"
done
