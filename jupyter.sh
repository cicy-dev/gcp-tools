#!/bin/bash

# 设置默认端口
PORT=${1:-8889}

# 创建日志目录
mkdir -p ~/logs

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ~/logs/boot.log
}


# 检查环境变量
log "检查环境变量..."
if [ -z "$CF_TUNNEL" ]; then
    log "错误: CF_TUNNEL 环境变量未设置！"
    echo "请设置：export CF_TUNNEL=你的隧道名"
    exit 1
fi
log "CF_TUNNEL 已设置"

if [ -z "$JUPYTER_TOKEN" ]; then
    log "错误: JUPYTER_TOKEN 环境变量未设置！"
    echo "请设置：export JUPYTER_TOKEN=你的令牌"
    exit 1
fi
log "JUPYTER_TOKEN 已设置"

# 检查并安装 jupyterlab
log "检查 JupyterLab..."
if ! pip show jupyterlab >/dev/null 2>&1; then
    log "安装 JupyterLab..."
    pip install --user jupyterlab >> ~/logs/jupyter_install.log 2>&1 || pip install --break-system-packages jupyterlab >> ~/logs/jupyter_install.log 2>&1
    log "JupyterLab 安装完成"
else
    log "JupyterLab 已安装"
fi

# 启动 JupyterLab
log "启动 JupyterLab..."
sudo fuser -k $PORT/tcp 2>/dev/null || true
sleep 2


nohup jupyter-lab \
  --no-browser \
  --ServerApp.token=$JUPYTER_TOKEN \
  --ip=127.0.0.1 \
  --port=$PORT \
  --ServerApp.allow_remote_access=True \
  --ServerApp.trust_xheaders=True \
  > ~/logs/jupyter_lab.log 2>&1 &

JUPYTER_PID=$!
log "JupyterLab 已启动，PID: $JUPYTER_PID"

# 等待启动并检查状态
sleep 3
if ps -p $JUPYTER_PID > /dev/null; then
    log "JupyterLab 启动成功，监听端口 $PORT"
    echo "访问地址: http://localhost:$PORT/?token=***"
else
    log "错误: JupyterLab 启动失败"
    echo "查看日志: tail -f ~/logs/jupyter_lab.log"
    exit 1
fi