#!/bin/bash

XRK_ROOT="${XRK_ROOT:-/xrk}"
SESSION_NAME="新年快乐"
TMUX_CONF="${HOME}/.tmux.conf"
[ -f "$TMUX_CONF" ] || TMUX_CONF="$XRK_ROOT/body/.tmux.conf"

_tmux() {
    if [ -f "$HOME/.tmux.conf" ]; then
        tmux "$@"
    else
        tmux -f "$TMUX_CONF" "$@"
    fi
}

# 取最近活动的会话名（有多个存活会话时用于恢复上次使用的）
_tmux_latest_session() {
    _tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null \
        | sort -rn \
        | head -1 \
        | cut -d' ' -f2-
}

create_desktop_layout() {
    _tmux new-session -d -s "$SESSION_NAME" -n "来财" "bash $XRK_ROOT/body/window_a.sh; exec bash"
    _tmux split-window -v -t "$SESSION_NAME:来财" "bash $XRK_ROOT/body/window_a1.sh; exec bash"
    _tmux new-window -t "$SESSION_NAME" -n "来福" "bash $XRK_ROOT/body/window_b.sh; exec bash"
    _tmux split-window -h -t "$SESSION_NAME:来福" "bash $XRK_ROOT/body/window_b.sh; exec bash"
    _tmux new-window -t "$SESSION_NAME" -n "来运" "bash $XRK_ROOT/body/window_c.sh; exec bash"
    _tmux split-window -h -t "$SESSION_NAME:来运" "bash $XRK_ROOT/body/window_c.sh; exec bash"
    _tmux select-pane -t 0
    _tmux split-window -v "exec bash"
    _tmux select-window -t "$SESSION_NAME:来财"
}

attach_existing_session() {
    local target="$1"
    [ -z "$target" ] && return 1
    _tmux attach-session -t "$target"
}

# 优先恢复已有会话：最近活动会话 → 默认桌面名 → 新建布局
attach_or_create() {
    local latest

    latest=$(_tmux_latest_session)
    if [ -n "$latest" ]; then
        attach_existing_session "$latest"
        return
    fi

    if _tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        attach_existing_session "$SESSION_NAME"
        return
    fi

    create_desktop_layout
    _tmux source-file "$TMUX_CONF" 2>/dev/null || true
    attach_existing_session "$SESSION_NAME"
}

# 错误处理函数
handle_error() {
    echo "错误: $1" >&2
    exit 1
}

# 检查依赖（委托 body/modules/tmux.sh 仅安装包）
check_dependencies() {
    if ! command -v tmux &>/dev/null; then
        [ -f "$XRK_ROOT/body/modules/tmux.sh" ] || handle_error "未找到 tmux 安装模块"
        XRK_TMUX_PKG_ONLY=1 bash "$XRK_ROOT/body/modules/tmux.sh" || handle_error "未安装 tmux"
    fi
    [ -f "$TMUX_CONF" ] || {
        if [ -f "$XRK_ROOT/body/.tmux.conf" ]; then
            ln -sf "$XRK_ROOT/body/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || true
            TMUX_CONF="$HOME/.tmux.conf"
        fi
    }
    [ -f "$TMUX_CONF" ] || handle_error "配置文件不存在: $TMUX_CONF（可先运行 xrk-tmux-setup）"
    [ -f "$XRK_ROOT/body/window_a.sh" ] || handle_error "window_a.sh 不存在"
    [ -f "$XRK_ROOT/body/window_b.sh" ] || handle_error "window_b.sh 不存在"
    [ -f "$XRK_ROOT/body/window_c.sh" ] || handle_error "window_c.sh 不存在"
}

# 主函数
main() {
    check_dependencies
    if [ -n "$TMUX" ]; then
        _tmux source-file "$TMUX_CONF"
        return
    fi
    attach_or_create
}

main