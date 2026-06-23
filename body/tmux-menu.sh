#!/bin/bash
# 向日葵 tmux 菜单（唯一菜单定义）
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
MENU="${XRK_MENU_CMD:-bash ${XRK_ROOT}/body/tmux-menu.sh}"

_xrk_sys_items=(
    '  帮助' 'h' 'run-shell "@XRK_MENU@ help || true"'
    '  重载' 'r' 'source-file ~/.tmux.conf \; display "配置已重载"'
    '  分离' 'd' 'detach-client'
)

_xrk_pane_items=(
    '  复制模式' '[' 'copy-mode'
    '  粘贴' 'p' 'paste-buffer'
    '  左右分割' 'v' 'split-window -h -c "#{pane_current_path}"'
    '  上下分割' 's' 'split-window -v -c "#{pane_current_path}"'
    '  最大化/还原' 'z' 'resize-pane -Z'
    '  关闭窗格' 'w' 'kill-pane'
    '  新建窗口' 'c' 'new-window -c "#{pane_current_path}"'
    '  重命名' 'n' 'command-prompt -I "#W" "rename-window -- \"%%\""'
    '  关闭窗口' 'q' 'kill-window'
)

_xrk_session_items=(
    '  重命名' 'R' 'command-prompt -I "#S" "rename-session -- \"%%\""'
    '  新建窗口' 'w' 'new-window -c "#{pane_current_path}"'
    '  新建会话' 's' 'new-session'
)

_xrk_window_items=(
    '  重命名' 'R' 'command-prompt -I "#W" "rename-window -- \"%%\""'
    '  关闭' 'q' 'kill-window'
    '  新建' 'c' 'new-window -c "#{pane_current_path}"'
    '  上一个' 'P' 'previous-window'
    '  下一个' 'N' 'next-window'
)

_xrk_expand_menu() {
    local s="$1"
    s="${s//@XRK_MENU@/$MENU}"
    printf '%s' "$s"
}

_xrk_quote_conf() {
    local s="$1"
    s="${s//\'/\'\\\'\'}"
    printf "'%s'" "$s"
}

_xrk_emit_item() {
    local name="$1" key="$2" cmd="$3" cont="$4"
    cmd="$(_xrk_expand_menu "$cmd")"
    printf '  %s %s %s' "$(_xrk_quote_conf "$name")" "$(_xrk_quote_conf "$key")" "$(_xrk_quote_conf "$cmd")"
    [ "$cont" = "1" ] && printf ' \\'
    printf '\n'
}

_xrk_emit_items() {
    local -a items=("$@")
    local n=${#items[@]} i=0
    while [ "$i" -lt "$n" ]; do
        i=$((i + 3))
        [ "$i" -lt "$n" ] && cont=1 || cont=0
        _xrk_emit_item "${items[$((i - 3))]}" "${items[$((i - 2))]}" "${items[$((i - 1))]}" "$cont"
    done
}

_xrk_emit_mouse_bind() {
    local trigger="$1" title="$2" pos_x="$3" pos_y="$4"
    shift 4
    local -a items=("$@")
    printf 'bind -n %s display-menu -T %s -t = -x %s -y %s \\\n' \
        "$trigger" "$(_xrk_quote_conf "$title")" "$pos_x" "$pos_y"
    _xrk_emit_items "${items[@]}"
}

_xrk_all_pane_menu_items() {
    local -a all=("${_xrk_pane_items[@]}" "${_xrk_sys_items[@]}")
    printf '%s\0' "${all[@]}"
}

_xrk_show_menu() {
    local title="$1" target="$2" pos_x="$3" pos_y="$4"
    shift 4
    local -a items=("$@")
    local -a expanded=()
    local item
    for item in "${items[@]}"; do
        expanded+=("$(_xrk_expand_menu "$item")")
    done
    tmux display-menu -T "$title" -t "$target" -x "$pos_x" -y "$pos_y" \
        "${expanded[@]}" || true
}

case "${1:-}" in
    --emit-mouse-binds)
        _xrk_emit_mouse_bind MouseDown3Pane '#[align=centre]向日葵 · 窗格' M M \
            "${_xrk_pane_items[@]}" "${_xrk_sys_items[@]}"
        _xrk_emit_mouse_bind MouseDown3StatusLeft '#[align=centre]向日葵 · 会话 · #{session_name}' M W \
            "${_xrk_session_items[@]}" "${_xrk_sys_items[@]}"
        _xrk_emit_mouse_bind MouseDown3Status '#[align=centre]向日葵 · 窗口 · #{window_index}:#{window_name}' M W \
            "${_xrk_window_items[@]}" "${_xrk_sys_items[@]}"
        _xrk_emit_mouse_bind MouseDown3StatusRight '#[align=centre]向日葵 · 系统' M W \
            "${_xrk_sys_items[@]}"
        ;;
    help)
        tmux display-message -d 10000 \
            "向日葵 tmux | 前缀 Alt+Space | F9 或 \\\\ 菜单 | 右键窗格/状态栏
Alt+hjkl 切窗格 | v/s 分割 | [ y 复制 | Alt+0~5 切窗口"
        ;;
    pane)
        _xrk_show_menu '#[align=centre]向日葵 · 窗格' "${2:-=}" "${3:-C}" "${4:-P}" \
            "${_xrk_pane_items[@]}" "${_xrk_sys_items[@]}"
        ;;
    *)
        echo "用法: tmux-menu.sh help|pane|session|window|system|--emit-mouse-binds" >&2
        exit 1
        ;;
esac
