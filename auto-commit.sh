#!/bin/bash

DIRS=(
    "$HOME/personal"
    "$HOME/tools"
)

for dir in "${DIRS[@]}"; do
    if [ -d "$dir/.git" ]; then
        cd "$dir"
        if [ -n "$(git status --porcelain)" ]; then
            git add -A
            git commit -m "auto: $(date '+%Y-%m-%d %H:%M:%S')"
            git push
            echo "✅ $(basename $dir): committed and pushed"
        fi
    fi
done
