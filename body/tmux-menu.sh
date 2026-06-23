#!/bin/bash
# 窗格菜单（F9 / \ / 右键）+ 帮助（?）
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
MENU="bash ${XRK_ROOT}/body/tmux-menu.sh"

case "${1:-}" in
    help)
        tmux display-message -d 10000 \
            "向日葵 tmux | 前缀 Alt+Space | F9 或 \\\\ 菜单 | 右键窗格/状态栏
Alt+hjkl 切窗格 | v/s 分割 | [ y 复制 | Alt+0~5 切窗口"
        ;;
    pane)
        tmux display-menu -T '#[align=centre]向日葵 · 窗格' -t = -x C -y P \
            '[编辑]' '' '' \
            '  复制模式' '[' 'copy-mode' \
            '  粘贴' 'p' 'paste-buffer' \
            '' '' '' \
            '[窗格]' '' '' \
            '  左右分割' 'v' 'split-window -h -c "#{pane_current_path}"' \
            '  上下分割' 's' 'split-window -v -c "#{pane_current_path}"' \
            '  最大化/还原' 'z' 'resize-pane -Z' \
            '  关闭窗格' 'w' 'kill-pane' \
            '' '' '' \
            '[窗口]' '' '' \
            '  新建窗口' 'c' 'new-window -c "#{pane_current_path}"' \
            '  重命名' 'n' 'command-prompt -I "#W" "rename-window -- \"%%\""' \
            '  关闭窗口' 'q' 'kill-window' \
            '' '' '' \
            '[系统]' '' '' \
            '  帮助' 'h' "run-shell '${MENU} help || true'" \
            '  重载' 'r' 'source-file ~/.tmux.conf \; display "配置已重载"' \
            '  分离' 'd' 'detach-client' \
            || true
        ;;
    *)
        echo "用法: tmux-menu.sh help|pane" >&2
        exit 1
        ;;
esac
