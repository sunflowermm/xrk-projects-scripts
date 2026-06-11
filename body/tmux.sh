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

    if ! _has_desktop_layout; then
        _tmux new-session -s "$SESSION_NAME" || handle_error "无法创建 tmux 会话"
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

# 检查依赖
check_dependencies() {
    root="${XRK_ROOT:-/xrk}"
    if ! type xrk_ensure_bootstrap &>/dev/null; then
        # shellcheck source=/dev/null
        [ -f "$root/shell_modules/xrk_boot.sh" ] && source "$root/shell_modules/xrk_boot.sh"
    fi
    type xrk_ensure_bootstrap &>/dev/null && xrk_ensure_bootstrap && xrk_prepare_root

    if ! command -v tmux &>/dev/null; then
        if type xrk_exec_script &>/dev/null; then
            XRK_TMUX_PKG_ONLY=1 xrk_exec_script "body/modules/tmux.sh" || handle_error "未安装 tmux"
        elif [ -f "$XRK_ROOT/body/modules/tmux.sh" ]; then
            XRK_TMUX_PKG_ONLY=1 bash "$XRK_ROOT/body/modules/tmux.sh" || handle_error "未安装 tmux"
        else
            handle_error "未找到 tmux 安装模块"
        fi
    fi
    if [ ! -f "$TMUX_CONF" ]; then
        if type xrk_ensure_repo_file &>/dev/null; then
            xrk_ensure_repo_file "body/.tmux.conf" && ln -sf "$XRK_ROOT/body/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null
        elif [ -f "$XRK_ROOT/body/.tmux.conf" ]; then
            ln -sf "$XRK_ROOT/body/.tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || true
        fi
        TMUX_CONF="${HOME}/.tmux.conf"
    fi
    [ -f "$TMUX_CONF" ] || handle_error "配置文件不存在: $TMUX_CONF（可先 xm→3→7 配置 tmux）"
}

_has_desktop_layout() {
    local w
    for w in window_a.sh window_b.sh window_c.sh; do
        if type xrk_ensure_repo_file &>/dev/null; then
            xrk_ensure_repo_file "body/$w" 2>/dev/null || return 1
        elif [ ! -f "$XRK_ROOT/body/$w" ]; then
            return 1
        fi
    done
    return 0
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