#!/bin/bash

# 创建日志目录
mkdir -p ~/logs

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ~/logs/boot.log
}

log "开始启动脚本..."

# 检查并添加 env 到 .bashrc
log "配置环境文件..."
grep -qxF "source ~/env" ~/.bashrc || echo "source ~/env" >> ~/.bashrc
touch ~/env
chmod +x ~/Desktop/tools/*.sh
source ~/.bashrc
log "环境文件配置完成"


# 运行 cloudflared 隧道脚本
log "配置 cloudflared 隧道..."
if [ -f ~/Desktop/tools/cloudflared-tunnel.sh ]; then
    export CF_TUNNEL_NO_RESTART=1
    ~/Desktop/tools/cloudflared-tunnel.sh
    if [ $? -eq 0 ]; then
        log "cloudflared 隧道配置完成"
    else
        log "警告: cloudflared 隧道配置失败"
    fi
else
    log "错误: ~/Desktop/tools/cloudflared-tunnel.sh 文件不存在"
fi

# 检查并安装 Node.js 和 npm (最新版本)
log "检查 Node.js..."
if ! command -v node >/dev/null 2>&1; then
    log "安装 Node.js 最新版本..."
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - >> ~/logs/node_install.log 2>&1
    sudo apt-get install -y nodejs >> ~/logs/node_install.log 2>&1
    log "Node.js 安装完成，版本: $(node --version)"
else
    log "Node.js 已安装，版本: $(node --version)"
fi

if ! command -v npm >/dev/null 2>&1; then
    log "npm 未找到，重新安装 Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - >> ~/logs/node_install.log 2>&1
    sudo apt-get install -y nodejs >> ~/logs/node_install.log 2>&1
else
    log "npm 已安装"
fi

log "npm 版本: $(npm --version)"

# 检查并安装 AI CLI 工具
log "检查 AI CLI 工具..."

# # 使用 command -v 检查命令是否存在，比 npm list 更快更可靠
if ! command -v gemini >/dev/null 2>&1; then
    log "未检测到 gemini，准备安装 @google/gemini-cli..."
    
    # 尝试安装，并捕获可能的错误
    if sudo npm install -g @google/gemini-cli >> ~/logs/npm_install.log 2>&1; then
        log "@google/gemini-cli 安装成功"
    else
        log "错误: @google/gemini-cli 安装失败！请检查 ~/logs/npm_install.log"
        # 根据需求决定是否退出脚本
        # exit 1 
    fi
else
    log "@google/gemini-cli 已存在，跳过安装"
fi

# 统一显示版本号，确保环境可用
CURRENT_VERSION=$(gemini --version 2>/dev/null || npx @google/gemini --version 2>/dev/null)
log "@google/gemini-cli 当前版本: ${CURRENT_VERSION:-未知}"

# if ! npm list -g @openai/codex >/dev/null 2>&1; then
#     log "安装 @openai/codex@latest..."
#     npm install -g @openai/codex@latest >> ~/logs/npm_install.log 2>&1
#     log "@openai/codex@latest 安装完成"
#     log "@openai/codex 版本: $(npx @openai/codex --version 2>/dev/null)"
# else
#     log "@openai/codex 已安装"
# fi

if ! npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
    log "安装 @anthropic-ai/claude-code..."
    sudo npm install -g @anthropic-ai/claude-code >> ~/logs/npm_install.log 2>&1
    log "@anthropic-ai/claude-code 安装完成"
    log "@anthropic-ai/claude-code 版本: $(npx @anthropic-ai/claude-code --version 2>/dev/null)"
    log "claude 版本: $(npx @anthropic-ai/claude-code claude --version 2>/dev/null)"
    # 创建 claude 命令别名    echo "#!/bin/bash" > ~/.local/bin/claude && echo "npx @anthropic-ai/claude-code claude "$@"" >> ~/.local/bin/claude && chmod +x ~/.local/bin/claude
else
    log "@anthropic-ai/claude-code 已安装"
fi

# # 配置 Claude Code 设置
# if [ ! -e ~/.claude/settings.json ]; then
#     log "创建 Claude Code 配置文件..."
#     mkdir -p ~/.claude
#     cat > ~/.claude/settings.json << EOF
# {
#   "env": {
#     "ANTHROPIC_AUTH_TOKEN": "$ANTHROPIC_AUTH_TOKEN",
#     "ANTHROPIC_BASE_URL": "https://jp.duckcoding.com"
#   }
# }
# EOF
#     log "Claude Code 配置文件已创建"
# else
#     log "Claude Code 配置文件已存在"
# fi

# 检查并安装 pip
log "检查 pip..."
if ! command -v pip >/dev/null 2>&1; then
    log "安装 pip..."
    sudo apt update >> ~/logs/apt.log 2>&1
    sudo apt install -y python3-pip python3-dev >> ~/logs/apt.log 2>&1
    log "pip 安装完成"
else
    log "pip 已安装"
fi

# cd ~/

# ~/Desktop/tools/jupyter.sh

# 检查并安装 VNC
log "检查 VNC..."
if ! command -v tigervncserver >/dev/null 2>&1; then
    log "安装 VNC..."
    ~/Desktop/tools/vnc-install.sh >> ~/logs/vnc_install.log 2>&1
    log "VNC 安装完成"
else
    log "VNC 已安装"
fi

# 检查并安装 Firefox
#log "检查 Firefox..."
#if ! command -v firefox-esr >/dev/null 2>&1; then
#    log "安装 Firefox..."
#    ~/Desktop/tools/firefox.sh install >> ~/logs/firefox_install.log 2>&1
#    log "Firefox 安装完成"
#else
#    log "Firefox 已安装"
#fi

# 检查并安装 Chrome
log "检查 Chrome..."
if ! command -v google-chrome >/dev/null 2>&1; then
    log "安装 Chrome..."
    ~/Desktop/tools/chrome.sh install >> ~/logs/chrome_install.log 2>&1
    log "Chrome 安装完成"
else
    log "Chrome 已安装"
fi


# 检查并安装 kiro-cli
log "检查 kiro-cli..."
if ! command -v kiro-cli >/dev/null 2>&1; then
    log "安装 kiro-cli..."
    curl -fsSL https://cli.kiro.dev/install | bash >> ~/logs/kiro_install.log 2>&1
    log "kiro-cli 安装完成"
    log "kiro-cli 版本: $(~/.local/bin/kiro-cli --version 2>/dev/null)"
else
    log "kiro-cli 已安装"
fi

# 安装 opencode
log "检查 opencode..."
if [ ! -e ~/.opencode/bin/opencode ]; then
    log "安装 opencode..."
    curl -fsSL https://opencode.ai/install | bash 
    log "opencode 安装完成"
else
    log "opencode 已安装"
fi

cd ~/
# 检查并安装 code-server
log "检查 code-server..."
if ! command -v code-server >/dev/null 2>&1; then
    log "安装 code-server..."
    curl -fsSL https://code-server.dev/install.sh | sh >> ~/logs/code_server_install.log 2>&1
fi

echo "⚙️ 正在启动服务..."
sudo systemctl enable --now code-server@$USER

echo "------------------------------------------------"
echo "✅ 安装成功！"
echo "配置文件路径: ~/.config/code-server/config.yaml"
echo "请查看该文件以获取访问密码。"
echo "------------------------------------------------"

log "环境配置完成！"
log "日志文件位置："
log "  - 主日志: ~/logs/boot.log"
log "  - 隧道日志: ~/logs/tunnel.log"
log "  - JupyterLab 日志: ~/logs/jupyter_lab.log"
log "  - Node.js 安装日志: ~/logs/node_install.log"
log "  - npm 包安装日志: ~/logs/npm_install.log"
