#!/bin/bash
# 自动生成 ~/projects/0____/ 目录的符号链接

TARGET_DIR="$HOME/projects/0____"

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 第一步：从 ~/personal/ 创建配置文件软链接到 ~/
echo "📝 Step 1: Creating config file links from ~/personal/"
declare -A HOME_LINKS=(
    [".npmrc"]="$HOME/personal/.npmrc"
    [".pypirc"]="$HOME/personal/.pypirc"
)

for name in "${!HOME_LINKS[@]}"; do
    source="${HOME_LINKS[$name]}"
    target="$HOME/$name"
    
    if [ -e "$source" ]; then
        if [ ! -e "$target" ]; then
            ln -sf "$source" "$target"
            echo "  ✅ Created: ~/$name -> $source"
        else
            echo "  ℹ️  Exists: ~/$name"
        fi
    else
        echo "  ⚠️  Skipped: $source does not exist"
    fi
done

echo ""
echo "📁 Step 2: Creating links in $TARGET_DIR/"

# 第二步：定义需要链接到 0____/ 的目录
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

# 创建符号链接
for name in "${!LINKS[@]}"; do
    source="${LINKS[$name]}"
    target="$TARGET_DIR/$name"
    
    # 如果目标不存在，创建链接
    if [ ! -e "$target" ]; then
        if [ -e "$source" ]; then
            ln -s "$source" "$target"
            echo "  ✅ Created: $name -> $source"
        else
            echo "  ⚠️  Skipped: $source does not exist"
        fi
    else
        echo "  ℹ️  Exists: $name"
    fi
done

echo ""
echo "📁 Links in $TARGET_DIR:"
ls -lah "$TARGET_DIR"
