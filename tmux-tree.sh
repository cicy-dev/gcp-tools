#!/bin/bash
tmux list-sessions 2>/dev/null | while IFS=: read -r session rest; do
    echo "📦 Session: $session"
    tmux list-windows -t "$session" 2>/dev/null | while read -r line; do
        win_id=$(echo "$line" | cut -d: -f1)
        win_name=$(echo "$line" | awk -F': ' '{print $2}' | awk '{print $1}')
        pane_count=$(tmux list-panes -t "$session:$win_id" 2>/dev/null | wc -l)
        
        last_win=$(tmux list-windows -t "$session" 2>/dev/null | tail -1 | cut -d: -f1)
        if [ "$win_id" = "$last_win" ]; then
            echo "└── Window $win_id: $win_name"
            prefix="    "
        else
            echo "├── Window $win_id: $win_name"
            prefix="│   "
        fi
        
        if [ "$pane_count" -eq 1 ]; then
            echo "${prefix}└── Pane 0"
        else
            i=0
            while [ $i -lt $pane_count ]; do
                if [ $i -eq $((pane_count-1)) ]; then
                    echo "${prefix}└── Pane $i"
                else
                    echo "${prefix}├── Pane $i"
                fi
                i=$((i+1))
            done
        fi
    done
    echo
done
