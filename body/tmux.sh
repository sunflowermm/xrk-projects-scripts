#!/bin/bash
# 进入或切换到向日葵 tmux 桌面（菜单 7 / xrk-tmux；内外 tmux 统一入口）

XRK_ROOT="${XRK_ROOT:-/xrk}"
SESSION_NAME="新年快乐"
TMUX_CONF="${HOME}/.tmux.conf"

_tmux_latest_session() {
    tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null \
        | sort -rn | head -1 | cut -d' ' -f2-
}

_tmux_reload_conf() {
    tmux source-file "$TMUX_CONF" 2>/dev/null || true
}

_tmux_resolve_target() {
    tmux has-session -t "$SESSION_NAME" 2>/dev/null && { echo "$SESSION_NAME"; return; }
    _tmux_latest_session
}

_tmux_connect() {
    local target="$1" cur
    [ -z "$target" ] && return 1

    if [ -n "$TMUX" ]; then
        cur=$(tmux display-message -p '#S' 2>/dev/null || true)
        if [ "$cur" = "$target" ]; then
            echo "[tmux] 已在会话: $target（配置已重载）"
            return 0
        fi
        echo "[tmux] 切换到会话: $target"
        tmux switch-client -t "$target"
        return
    fi

    echo "[tmux] 连接到会话: $target"
    if [ ! -t 0 ] && [ -r /dev/tty ]; then
        tmux attach-session -t "$target" </dev/tty
    else
        tmux attach-session -t "$target"
    fi
}

create_desktop_layout() {
    tmux new-session -d -s "$SESSION_NAME" -n "来财" "bash $XRK_ROOT/body/window_a.sh; exec bash"
    tmux split-window -v -t "$SESSION_NAME:来财" "bash $XRK_ROOT/body/window_a1.sh; exec bash"
    tmux new-window -t "$SESSION_NAME" -n "来福" "bash $XRK_ROOT/body/window_b.sh; exec bash"
    tmux split-window -h -t "$SESSION_NAME:来福" "bash $XRK_ROOT/body/window_b.sh; exec bash"
    tmux new-window -t "$SESSION_NAME" -n "来运" "bash $XRK_ROOT/body/window_c.sh; exec bash"
    tmux split-window -h -t "$SESSION_NAME:来运" "bash $XRK_ROOT/body/window_c.sh; exec bash"
    tmux select-pane -t 0
    tmux split-window -v "exec bash"
    tmux select-window -t "$SESSION_NAME:来财"
}

ensure_tmux_env() {
    command -v tmux &>/dev/null \
        && [ -d "$HOME/.tmux/.git" ] \
        && [ -e "$TMUX_CONF" ] && return 0
    echo "[tmux] 环境未就绪，正在安装…"
    bash "$XRK_ROOT/body/modules/tmux.sh" || {
        echo "错误: tmux 环境未就绪（可先 xm→3→7 配置）" >&2
        exit 1
    }
}

goto_desktop() {
    local target

    _tmux_reload_conf
    target=$(_tmux_resolve_target)
    if [ -n "$target" ]; then
        _tmux_connect "$target"
        return
    fi

    echo "[tmux] 创建向日葵桌面布局…"
    create_desktop_layout
    _tmux_reload_conf
    _tmux_connect "$SESSION_NAME"
}

ensure_tmux_env
for _w in window_a window_b window_c; do
    [ -f "$XRK_ROOT/body/${_w}.sh" ] || {
        echo "错误: ${_w}.sh 不存在" >&2
        exit 1
    }
done
goto_desktop
