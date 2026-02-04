#!/bin/bash

# 创建日志目录
mkdir -p ~/logs

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a ~/logs/boot.log
}

log "开始启动脚本..."

# 检查并添加 env.sh 到 .bashrc
log "配置环境文件..."
grep -qxF "source ~/env.sh" ~/.bashrc || echo "source ~/env.sh" >> ~/.bashrc
touch ~/env.sh
chmod +x ~/tools/*.sh
chmod +x ~/env.sh
source ~/.bashrc
log "环境文件配置完成"

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

# 运行 cloudflared 隧道脚本
log "配置 cloudflared 隧道..."
if [ -f ~/tools/cloudflared-tunnel.sh ]; then
    ~/tools/cloudflared-tunnel.sh
    if [ $? -eq 0 ]; then
        log "cloudflared 隧道配置完成"
    else
        log "警告: cloudflared 隧道配置失败"
    fi
else
    log "错误: ~/tools/cloudflared-tunnel.sh 文件不存在"
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
    log "npm 安装完成，版本: $(npm --version)"
else
    log "npm 已安装，版本: $(npm --version)"
fi

# 检查并安装 AI CLI 工具
log "检查 AI CLI 工具..."

# 检查并安装 AI CLI 工具
log "检查 AI CLI 工具..."

# 使用 command -v 检查命令是否存在，比 npm list 更快更可靠
if ! command -v gemini >/dev/null 2>&1; then
    log "未检测到 gemini，准备安装 @google/gemini-cli..."
    
    # 尝试安装，并捕获可能的错误
    if npm install -g @google/gemini-cli >> ~/logs/npm_install.log 2>&1; then
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

if ! npm list -g @openai/codex >/dev/null 2>&1; then
    log "安装 @openai/codex@latest..."
    npm install -g @openai/codex@latest >> ~/logs/npm_install.log 2>&1
    log "@openai/codex@latest 安装完成"
    log "@openai/codex 版本: $(npx @openai/codex --version 2>/dev/null)"
else
    log "@openai/codex 已安装"
fi

if ! npm list -g @anthropic-ai/claude-code >/dev/null 2>&1; then
    log "安装 @anthropic-ai/claude-code..."
    npm install -g @anthropic-ai/claude-code >> ~/logs/npm_install.log 2>&1
    log "@anthropic-ai/claude-code 安装完成"
    log "@anthropic-ai/claude-code 版本: $(npx @anthropic-ai/claude-code --version 2>/dev/null)"
    log "claude 版本: $(npx @anthropic-ai/claude-code claude --version 2>/dev/null)"
    # 创建 claude 命令别名    echo "#!/bin/bash" > ~/.local/bin/claude && echo "npx @anthropic-ai/claude-code claude "$@"" >> ~/.local/bin/claude && chmod +x ~/.local/bin/claude
else
    log "@anthropic-ai/claude-code 已安装"
fi

# 配置 Claude Code 设置
if [ ! -e ~/.claude/settings.json ]; then
    log "创建 Claude Code 配置文件..."
    mkdir -p ~/.claude
    cat > ~/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$ANTHROPIC_AUTH_TOKEN",
    "ANTHROPIC_BASE_URL": "https://jp.duckcoding.com"
  }
}
EOF
    log "Claude Code 配置文件已创建"
else
    log "Claude Code 配置文件已存在"
fi

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
sudo fuser -k 8889/tcp || true
sleep 1
cd ~/
nohup ~/.local/bin/jupyter-lab \
  --no-browser \
  --IdentityProvider.token=$JUPYTER_TOKEN \
  --ip=127.0.0.1 \
  --port=8889 \
  --ServerApp.allow_remote_access=True \
  --ServerApp.trust_xheaders=True \
  > ~/logs/jupyter_lab.log 2>&1 &
log "JupyterLab 已启动，PID: $!"

# 检查并安装 VNC
log "检查 VNC..."
if ! command -v tigervncserver >/dev/null 2>&1; then
    log "安装 VNC..."
    ~/vnc-install.sh >> ~/logs/vnc_install.log 2>&1
    log "VNC 安装完成"
else
    log "VNC 已安装"
fi

# 检查并安装 Firefox
#log "检查 Firefox..."
#if ! command -v firefox-esr >/dev/null 2>&1; then
#    log "安装 Firefox..."
#    ~/tools/firefox.sh install >> ~/logs/firefox_install.log 2>&1
#    log "Firefox 安装完成"
#else
#    log "Firefox 已安装"
#fi

# 检查并安装 Chrome
log "检查 Chrome..."
if ! command -v google-chrome >/dev/null 2>&1; then
    log "安装 Chrome..."
    ~/tools/chrome.sh install >> ~/logs/chrome_install.log 2>&1
    log "Chrome 安装完成"
else
    log "Chrome 已安装"
fi

# 安装 opencode
log "检查 opencode..."
if [ ! -e ~/.opencode/bin/opencode ]; then
    log "安装 opencode..."
    curl -fsSL https://opencode.ai/install | bash >> ~/logs/opencode_install.log 2>&1
    log "opencode 安装完成"
else
    log "opencode 已安装"
fi

log "环境配置完成！"
log "日志文件位置："
log "  - 主日志: ~/logs/boot.log"
log "  - 隧道日志: ~/logs/tunnel.log"
log "  - JupyterLab 日志: ~/logs/jupyter_lab.log"
log "  - Node.js 安装日志: ~/logs/node_install.log"
log "  - npm 包安装日志: ~/logs/npm_install.log"

# 检查并安装 kiro-cli
log "检查 kiro-cli..."
if ! command -v kiro-cli >/dev/null 2>&1; then
    log "安装 kiro-cli..."
    curl -fsSL https://cli.kiro.dev/install | bash >> ~/logs/kiro_install.log 2>&1
    log "kiro-cli 安装完成"
    log "kiro-cli 版本: $(~/.local/bin/kiro-cli --version 2>/dev/null)"
    # 添加 kiro-cli 到 PATH    grep -qxF "export PATH="/Users/ton/.local/bin:/Users/ton/.opencode/bin:/Users/ton/.antigravity/antigravity/bin:/usr/local/opt/openjdk@17/bin:/Users/ton/.nvm/versions/node/v20.19.0/bin:/Users/ton/Desktop/Android/sdk/emulator:/Users/ton/Desktop/Android/sdk/tools:/Users/ton/Desktop/Android/sdk/tools/bin:/Users/ton/Desktop/Android/sdk/platform-tools:/Applications/Docker.app/Contents/Resources/bin:/usr/local/go/bin:/usr/local/bin:/Users/ton/bin:/Users/ton/.local/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Applications/VMware Fusion.app/Contents/Public:/usr/local/go/bin:/Users/ton/.cargo/bin:/Users/ton/.local/bin:/Users/ton/Desktop/projects/web3-explorer/apps/desktop/out/Web3ExplorerBeta-darwin-x64"" ~/.bashrc || echo "export PATH="/Users/ton/.local/bin:/Users/ton/.opencode/bin:/Users/ton/.antigravity/antigravity/bin:/usr/local/opt/openjdk@17/bin:/Users/ton/.nvm/versions/node/v20.19.0/bin:/Users/ton/Desktop/Android/sdk/emulator:/Users/ton/Desktop/Android/sdk/tools:/Users/ton/Desktop/Android/sdk/tools/bin:/Users/ton/Desktop/Android/sdk/platform-tools:/Applications/Docker.app/Contents/Resources/bin:/usr/local/go/bin:/usr/local/bin:/Users/ton/bin:/Users/ton/.local/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/Library/Apple/usr/bin:/Applications/VMware Fusion.app/Contents/Public:/usr/local/go/bin:/Users/ton/.cargo/bin:/Users/ton/.local/bin:/Users/ton/Desktop/projects/web3-explorer/apps/desktop/out/Web3ExplorerBeta-darwin-x64"" >> ~/.bashrc
else
    log "kiro-cli 已安装"
fi
