#!/bin/bash

# 创建日志目录
mkdir -p ~/logs

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ~/logs/cloudflared-tunnel.log
}

log "开始 cloudflared 隧道脚本..."

# 检查 CF_TUNNEL 环境变量
if [ -z "$CF_TUNNEL" ]; then
    log "错误: CF_TUNNEL 环境变量未设置！"
    echo "请设置：export CF_TUNNEL=你的隧道令牌"
    exit 1
fi
log "CF_TUNNEL 已设置"

# 检查并安装 cloudflared
log "检查 cloudflared..."
if [ ! -e /usr/local/bin/cloudflared ]; then
    log "安装 cloudflared..."
    bash <(curl -fsSL https://raw.githubusercontent.com/cicybot/cloudflare-tunnel-proxy/refs/heads/main/install-cloudflared.sh) >> ~/logs/cloudflared_install.log 2>&1
    if [ $? -eq 0 ]; then
        log "cloudflared 安装完成"
    else
        log "错误: cloudflared 安装失败"
        exit 1
    fi
else
    log "cloudflared 已安装"
fi

# 检查 cloudflared 是否正在运行
if pgrep -f "cloudflared tunnel" > /dev/null; then
    log "cloudflared 隧道已在运行"
    log "当前进程: $(pgrep -f 'cloudflared tunnel')"

    # 自动重启（支持环境变量控制）
    # 设置 CF_TUNNEL_NO_RESTART=1 可跳过重启
    if [ "$CF_TUNNEL_NO_RESTART" = "1" ]; then
        log "保持现有隧道运行（CF_TUNNEL_NO_RESTART=1）"
        exit 0
    else
        log "自动重启 cloudflared 隧道..."
        pkill -f "cloudflared tunnel"
        sleep 2
    fi
fi

# 启动 cloudflared 隧道
log "启动 cloudflared 隧道..."
nohup cloudflared tunnel run --token $CF_TUNNEL >> ~/logs/tunnel.log 2>&1 &
TUNNEL_PID=$!
log "cloudflared 隧道已启动，PID: $TUNNEL_PID"

# 等待几秒并检查进程是否仍在运行
sleep 3
if ps -p $TUNNEL_PID > /dev/null; then
    log "隧道启动成功，正在运行中"
    log "查看日志: tail -f ~/logs/tunnel.log"
else
    log "错误: 隧道启动失败，请检查日志"
    exit 1
fi

log "cloudflared 隧道配置完成！"
