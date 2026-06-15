#!/bin/bash
# tmux 中文菜单：help + 键盘/触屏备用（F9）；鼠标右键见 body/tmux-menus.conf 内联 display-menu
XRK_ROOT="${XRK_ROOT:-/xrk}"
HOME="${HOME:-$(getent passwd "$(id -un 2>/dev/null || echo root)" | cut -d: -f6)}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

_xrk_tmux_help() {
    tmux display-message -d 10000 \
        "向日葵 tmux | 前缀 Alt+Space | 菜单 \\\\ 或 F9 | 右键状态栏/窗格
窗格 Alt+hjkl | 分割 v/s | 复制: 前缀 [ 再 y | 窗口 Alt+0~5"
}

# 键盘/触屏备用：run-shell 内不可用 -x M，用居中坐标
_xrk_menu_pane() {
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
        '  重命名窗口' 'n' 'command-prompt -I "#W" "rename-window -- \"%%\""' \
        '  关闭窗口' 'q' 'kill-window' \
        '' '' '' \
        '[系统]' '' '' \
        '  快捷键帮助' 'h' 'run-shell '"$0"' help' \
        '  重载配置' 'r' 'source-file ~/.tmux.conf \; display "配置已重载"' \
        '  分离会话' 'd' 'detach-client' \
        || true
}

case "${1:-}" in
    pane)    _xrk_menu_pane ;;
    help)    _xrk_tmux_help ;;
    *)
        echo "用法: tmux-menu.sh pane|help" >&2
        exit 1
        ;;
esac
