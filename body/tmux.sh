#!/bin/bash
# 向日葵 tmux 桌面（对齐 sunflower：直接 attach，无后台模式）

XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
# shellcheck source=/dev/null
[ -f "$XRK_ROOT/shell_modules/xrk_config.sh" ] && source "$XRK_ROOT/shell_modules/xrk_config.sh"

SESSION_NAME="${XRK_TMUX_SESSION:-新年快乐}"
TMUX_CONF="${HOME}/.tmux.conf"
read -ra XRK_TMUX_WINDOWS <<< "${XRK_TMUX_WINDOW_NAMES:-来财 来福 来运}"

_tmux_usage() {
    cat <<EOF
用法: xrk-tmux [选项]
  (无参数)  进入或创建「${SESSION_NAME}」
  --setup   安装 tmux 并写入配置
  --status  检查环境
  -h        本帮助
EOF
}

_tmux_ensure_utf8() {
    case "${LANG:-}" in
        *UTF-8*|*utf8*) ;;
        *) export LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 ;;
    esac
}

_tmux_conf_ok() {
    [ -f "$TMUX_CONF" ] && grep -q '向日葵 tmux' "$TMUX_CONF" \
        && [ -f "$HOME/.tmux/xrk-menus.conf" ]
}

_tmux_reload_config() {
    [ -f "$TMUX_CONF" ] || return 1
    tmux info &>/dev/null || tmux -f "$TMUX_CONF" start-server 2>/dev/null || return 1
    tmux source-file "$TMUX_CONF" 2>/dev/null || return 1
}

_tmux_repair_config() {
    [ -f "$XRK_ROOT/body/modules/tmux.sh" ] && bash "$XRK_ROOT/body/modules/tmux.sh" --link-only
}

_tmux_apply_window_names() {
    local session="$1" i
    tmux has-session -t "$session" 2>/dev/null || return 0
    for i in "${!XRK_TMUX_WINDOWS[@]}"; do
        tmux rename-window -t "$session:$i" "${XRK_TMUX_WINDOWS[$i]}" 2>/dev/null || true
    done
}

_tmux_session_window_count() {
    local s="$1"
    tmux has-session -t "$s" 2>/dev/null || return 0
    tmux list-windows -t "$s" 2>/dev/null | wc -l
}

_tmux_status() {
    echo "tmux: $(command -v tmux >/dev/null && tmux -V || echo 未安装)"
    echo "配置: $TMUX_CONF $(_tmux_conf_ok && echo OK || echo 未就绪)"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "会话: $SESSION_NAME 已存在（$(_tmux_session_window_count "$SESSION_NAME") 个窗口）"
    else
        echo "会话: 未创建"
    fi
}

_tmux_ensure_env() {
    command -v tmux &>/dev/null || {
        echo "[tmux] 未安装，请先菜单 7→1 或 xrk-tmux --setup" >&2
        return 1
    }
    _tmux_conf_ok || _tmux_repair_config || {
        echo "[tmux] 配置未就绪，请先 xrk-tmux --setup" >&2
        return 1
    }
}

_tmux_create_layout() {
    local s="$SESSION_NAME"
    if tmux has-session -t "$s" 2>/dev/null; then
        _tmux_apply_window_names "$s"
        return 0
    fi
    tmux new-session -d -s "$s" -n "${XRK_TMUX_WINDOWS[0]}" "exec bash"
    tmux split-window -v -t "$s:0" "exec bash"
    tmux new-window -t "$s:1" -n "${XRK_TMUX_WINDOWS[1]}" "exec bash"
    tmux split-window -h -t "$s:1" "exec bash"
    tmux new-window -t "$s:2" -n "${XRK_TMUX_WINDOWS[2]}" "exec bash"
    tmux split-window -h -t "$s:2" "exec bash"
    tmux select-window -t "$s:0"
    _tmux_apply_window_names "$s"
}

_tmux_enter() {
    local cur
    _tmux_ensure_utf8
    _tmux_ensure_env || exit 1
    _tmux_reload_config || true
    _tmux_create_layout || exit 1
    _tmux_reload_config || true

    if [ -n "$TMUX" ]; then
        cur=$(tmux display-message -p '#S' 2>/dev/null || true)
        _tmux_apply_window_names "$SESSION_NAME"
        tmux display-message "配置已刷新" 2>/dev/null || true
        [ "$cur" = "$SESSION_NAME" ] && {
            echo "[tmux] 已在 $SESSION_NAME，配置已刷新"
            return 0
        }
        tmux switch-client -t "$SESSION_NAME"
        return 0
    fi

    echo "[tmux] 进入 $SESSION_NAME …"
    exec tmux attach-session -t "$SESSION_NAME"
}

case "${1:-}" in
    -h|--help)  _tmux_usage; exit 0 ;;
    --status)   _tmux_status; exit 0 ;;
    --setup)    bash "$XRK_ROOT/body/modules/tmux.sh"; exit $? ;;
esac

_tmux_enter
