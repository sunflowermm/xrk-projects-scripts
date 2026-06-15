#!/bin/bash
# tmux 中文右键菜单（由 ~/.tmux/xrk-menu 调用）
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
XRK_ROOT="${XRK_ROOT:-/xrk}"
HOME="${HOME:-$(getent passwd "$(id -un 2>/dev/null || echo root)" | cut -d: -f6)}"

_MENU="${HOME}/.tmux/xrk-menu"
_R='source-file ~/.tmux.conf \; display "配置已重载"'
_H="run-shell ${_MENU} help"

_xrk_tmux_help() {
    tmux display-message -d 10000 \
        "向日葵 tmux | 前缀 Alt+Space | 分离 d | 重载 r | 重命名 n
窗格 Alt+hjkl | 分割 v/s | 复制: 前缀 [ 再 y | 窗口 Alt+0~5 | 右键菜单"
}

_xrk_menu_pane() {
    tmux display-menu -T '#[align=centre]向日葵 · 窗格' -t = -x M -y M \
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
        '  重命名窗口' 'n' 'command-prompt -I "#W" "rename-window -- \"%%\""' \
        '  关闭窗口' 'q' 'kill-window' \
        '' '' '' \
        '[系统]' '' '' \
        '  快捷键帮助' '?' "$_H" \
        '  重载配置' 'r' "$_R" \
        '  分离会话' 'd' 'detach-client'
}

_xrk_menu_session() {
    tmux display-menu -T '#[align=centre]向日葵 · 会话 · #{session_name}' -t = -x M -y W \
        '[会话]' '' '' \
        '  重命名会话' 'R' 'command-prompt -I "#S" "rename-session -- \"%%\""' \
        '  新建窗口' 'w' 'new-window -c "#{pane_current_path}"' \
        '  新建会话' 's' 'new-session' \
        '  重排窗口编号' 'N' 'move-window -r' \
        '' '' '' \
        '[切换]' '' '' \
        '  上一个会话' 'p' 'switch-client -p' \
        '  下一个会话' 'n' 'switch-client -n' \
        '' '' '' \
        '[系统]' '' '' \
        '  快捷键帮助' '?' "$_H" \
        '  重载配置' 'r' "$_R" \
        '  分离会话' 'd' 'detach-client'
}

_xrk_menu_window() {
    tmux display-menu -T '#[align=centre]向日葵 · 窗口 · #{window_index}:#{window_name}' -t = -x W -y W \
        '[窗口]' '' '' \
        '  重命名' 'R' 'command-prompt -I "#W" "rename-window -- \"%%\""' \
        '  关闭窗口' 'q' 'kill-window' \
        '  新建窗口' 'c' 'new-window -c "#{pane_current_path}"' \
        '' '' '' \
        '[切换]' '' '' \
        '  上一个窗口' 'p' 'previous-window' \
        '  下一个窗口' 'n' 'next-window' \
        '' '' '' \
        '[系统]' '' '' \
        '  快捷键帮助' '?' "$_H" \
        '  重载配置' 'r' "$_R" \
        '  分离会话' 'd' 'detach-client'
}

_xrk_menu_system() {
    tmux display-menu -T '#[align=centre]向日葵 · 系统' -t = -x W -y W \
        '[系统]' '' '' \
        '  快捷键帮助' '?' "$_H" \
        '  重载配置' 'r' "$_R" \
        '  分离会话' 'd' 'detach-client'
}

case "${1:-}" in
    pane)    _xrk_menu_pane ;;
    session) _xrk_menu_session ;;
    window)  _xrk_menu_window ;;
    system)  _xrk_menu_system ;;
    help)    _xrk_tmux_help ;;
    *)
        echo "用法: tmux-menu.sh pane|session|window|system|help" >&2
        exit 1
        ;;
esac
