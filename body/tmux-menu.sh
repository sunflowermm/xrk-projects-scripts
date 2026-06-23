#!/bin/bash
# 向日葵 tmux 菜单（唯一菜单定义；tmux-menus.conf 仅绑定快捷键）
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
MENU="bash ${XRK_ROOT}/body/tmux-menu.sh"

_xrk_sys_items=(
    '[系统]' '' ''
    '  帮助' 'h' "run-shell '${MENU} help || true'"
    '  重载' 'r' 'source-file ~/.tmux.conf \; display "配置已重载"'
    '  分离' 'd' 'detach-client'
)

_xrk_pane_items=(
    '[编辑]' '' ''
    '  复制模式' '[' 'copy-mode'
    '  粘贴' 'p' 'paste-buffer'
    '' '' ''
    '[窗格]' '' ''
    '  左右分割' 'v' 'split-window -h -c "#{pane_current_path}"'
    '  上下分割' 's' 'split-window -v -c "#{pane_current_path}"'
    '  最大化/还原' 'z' 'resize-pane -Z'
    '  关闭窗格' 'w' 'kill-pane'
    '' '' ''
    '[窗口]' '' ''
    '  新建窗口' 'c' 'new-window -c "#{pane_current_path}"'
    '  重命名' 'n' 'command-prompt -I "#W" "rename-window -- \"%%\""'
    '  关闭窗口' 'q' 'kill-window'
)

case "${1:-}" in
    help)
        tmux display-message -d 10000 \
            "向日葵 tmux | 前缀 Alt+Space | F9 或 \\\\ 菜单 | 右键窗格/状态栏
Alt+hjkl 切窗格 | v/s 分割 | [ y 复制 | Alt+0~5 切窗口"
        ;;
    pane)
        tmux display-menu -T '#[align=centre]向日葵 · 窗格' \
            -t "${2:-=}" -x "${3:-C}" -y "${4:-P}" \
            "${_xrk_pane_items[@]}" \
            '' '' '' \
            "${_xrk_sys_items[@]}" \
            || true
        ;;
    session)
        tmux display-menu -T '#[align=centre]向日葵 · 会话 · #{session_name}' \
            -t = -x "${2:-M}" -y "${3:-W}" \
            '[会话]' '' '' \
            '  重命名' 'R' 'command-prompt -I "#S" "rename-session -- \"%%\""' \
            '  新建窗口' 'w' 'new-window -c "#{pane_current_path}"' \
            '  新建会话' 's' 'new-session' \
            '' '' '' \
            "${_xrk_sys_items[@]}" \
            || true
        ;;
    window)
        tmux display-menu -T '#[align=centre]向日葵 · 窗口 · #{window_index}:#{window_name}' \
            -t = -x "${2:-M}" -y "${3:-W}" \
            '[窗口]' '' '' \
            '  重命名' 'R' 'command-prompt -I "#W" "rename-window -- \"%%\""' \
            '  关闭' 'q' 'kill-window' \
            '  新建' 'c' 'new-window -c "#{pane_current_path}"' \
            '' '' '' \
            '[切换]' '' '' \
            '  上一个' 'P' 'previous-window' \
            '  下一个' 'N' 'next-window' \
            '' '' '' \
            "${_xrk_sys_items[@]}" \
            || true
        ;;
    system)
        tmux display-menu -T '#[align=centre]向日葵 · 系统' \
            -t = -x "${2:-M}" -y "${3:-W}" \
            "${_xrk_sys_items[@]}" \
            || true
        ;;
    *)
        echo "用法: tmux-menu.sh help|pane|session|window|system" >&2
        exit 1
        ;;
esac
