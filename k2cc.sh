#!/bin/bash

# 1. 确保权限
chmod +x ~/tools/kiro2cc

# 2. 导出配置（确保目录存在）
~/tools/kiro2cc export > ~/kiro2cc_rc
sed -i 's/8080/8088/g' ~/kiro2cc_rc
source ~/.bashrc
# 3. 彻底杀死旧进程
pkill -9 kiro2cc || true
sleep 1

# 4. 正确的后台启动方式 (nohup)
# 使用 & 符号放入后台，并将标准输出和错误流都指向日志文件
mkdir -p ~/logs
nohup ~/tools/kiro2cc server 8088 > ~/logs/kiro2cc.log 2>&1 &
echo "kiro2cc server started at :8088"

curl -X POST http://localhost:8088/v1/messages   -H "Content-Type: application/json"   -d '{"model": "claude-sonnet-4-20250514", "messages": [{"role": "user", "content": "Hello"}]}'

tail -f  ~/logs/kiro2cc.log