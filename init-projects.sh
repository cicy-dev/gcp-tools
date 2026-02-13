#!/bin/bash
# 初始化 projects 目录结构和符号链接

set -e

PROJECTS_DIR="$HOME/projects"
QUICK_ACCESS="$PROJECTS_DIR/0____"

# 创建目录结构
mkdir -p "$PROJECTS_DIR"
mkdir -p "$QUICK_ACCESS"

echo "📁 初始化 projects 目录..."

# 创建符号链接
declare -A LINKS=(
    ["data"]="$HOME/data"
    ["logs"]="$HOME/logs"
    ["Desktop"]="$HOME/Desktop"
    ["home"]="$HOME"
    ["personal"]="$HOME/personal"
    ["tmp"]="/tmp"
    ["tools"]="$HOME/tools"
    ["workers"]="$HOME/personal/workers"
    [".pypirc"]="$HOME/.pypirc"
    [".npmrc"]="$HOME/.npmrc"
)

for name in "${!LINKS[@]}"; do
    source="${LINKS[$name]}"
    target="$QUICK_ACCESS/$name"
    
    if [ ! -e "$target" ]; then
        if [ -e "$source" ]; then
            ln -s "$source" "$target"
            echo "✅ $name -> $source"
        else
            echo "⚠️  跳过: $source 不存在"
        fi
    else
        echo "ℹ️  已存在: $name"
    fi
done

# 克隆项目（如果不存在）
declare -A REPOS=(
    ["cicy"]="git@github.com:cicy-dev/cicy.git"
    ["cicy-remote"]="git@github.com:cicy-dev-003/cicy-remote.git"
    ["tmux-mcp"]="git@github.com:cicy-dev/tmux-mcp.git"
    ["tts-bot"]="git@github.com:cicy-dev/tts-bot.git"
)

# 克隆 personal 和 tools（如果不存在）
if [ ! -d "$HOME/personal/.git" ]; then
    echo "⬇️  克隆 personal..."
    git clone git@github.com:cicy-dev/personal.git "$HOME/personal"
fi

if [ ! -d "$HOME/tools/.git" ]; then
    echo "⬇️  克隆 tools..."
    git clone git@github.com:cicy-dev/gcp-tools.git "$HOME/tools"
fi

echo ""
echo "📦 检查项目..."

for project in "${!REPOS[@]}"; do
    project_dir="$PROJECTS_DIR/$project"
    if [ ! -d "$project_dir" ]; then
        echo "⬇️  克隆 $project..."
        git clone "${REPOS[$project]}" "$project_dir"
    else
        echo "ℹ️  已存在: $project"
    fi
done

echo ""
echo "✅ 初始化完成！"
echo "📂 快速访问目录: $QUICK_ACCESS"
