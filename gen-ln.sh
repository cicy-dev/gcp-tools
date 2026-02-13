#!/bin/bash
# 自动生成 ~/projects/0____/ 目录的符号链接

TARGET_DIR="$HOME/projects/0____"

# 创建目标目录
mkdir -p "$TARGET_DIR"

# 定义需要链接的目录
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
            echo "✅ Created: $name -> $source"
        else
            echo "⚠️  Skipped: $source does not exist"
        fi
    else
        echo "ℹ️  Exists: $name"
    fi
done

echo ""
echo "📁 Links in $TARGET_DIR:"
ls -lah "$TARGET_DIR"
