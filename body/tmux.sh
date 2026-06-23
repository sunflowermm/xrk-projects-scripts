#!/bin/bash
# 向日葵 tmux 桌面

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

_tmux_conf_ok() {
    [ -f "$TMUX_CONF" ] && grep -q '向日葵 tmux' "$TMUX_CONF" \
        && [ -f "$HOME/.tmux/xrk-menus.conf" ]
}

_tmux_ensure_env() {
    command -v tmux &>/dev/null || {
        echo "[tmux] 未安装，请先菜单 7→1 或 xrk-tmux --setup" >&2
        return 1
    }
    _tmux_conf_ok && return 0
    bash "$XRK_ROOT/body/modules/tmux.sh" --link-only || {
        echo "[tmux] 配置未就绪，请先 xrk-tmux --setup" >&2
        return 1
    }
}

_tmux_start_server() {
    [ -f "$TMUX_CONF" ] || return 1
    tmux info &>/dev/null || tmux -f "$TMUX_CONF" start-server 2>/dev/null || return 1
    tmux source-file "$TMUX_CONF" 2>/dev/null
}

_tmux_apply_window_names() {
    local session="$1" i
    tmux has-session -t "$session" 2>/dev/null || return 0
    for i in "${!XRK_TMUX_WINDOWS[@]}"; do
        tmux rename-window -t "$session:$i" "${XRK_TMUX_WINDOWS[$i]}" 2>/dev/null || true
    done
}

_tmux_ensure_session() {
    local s="$SESSION_NAME"
    if tmux has-session -t "$s" 2>/dev/null; then
        _tmux_apply_window_names "$s"
        return 0
    fi
    tmux new-session -d -s "$s" -n "${XRK_TMUX_WINDOWS[0]}"
    tmux split-window -v -t "$s:0"
    tmux new-window -t "$s:1" -n "${XRK_TMUX_WINDOWS[1]}"
    tmux split-window -h -t "$s:1"
    tmux new-window -t "$s:2" -n "${XRK_TMUX_WINDOWS[2]}"
    tmux split-window -h -t "$s:2"
    tmux select-window -t "$s:0"
    _tmux_apply_window_names "$s"
}

_tmux_status() {
    echo "tmux: $(command -v tmux >/dev/null && tmux -V || echo 未安装)"
    echo "配置: $TMUX_CONF $(_tmux_conf_ok && echo OK || echo 未就绪)"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "会话: $SESSION_NAME 已存在（$(tmux list-windows -t "$SESSION_NAME" 2>/dev/null | wc -l) 个窗口）"
    else
        echo "会话: 未创建"
    fi
}

_tmux_enter() {
    case "${LANG:-}" in
        *UTF-8*|*utf8*) ;;
        *) export LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 ;;
    esac
    _tmux_ensure_env || exit 1
    _tmux_start_server || true
    _tmux_ensure_session || exit 1

    if [ -n "$TMUX" ]; then
        [ "$(tmux display-message -p '#S' 2>/dev/null)" = "$SESSION_NAME" ] \
            && echo "[tmux] 已在 $SESSION_NAME" \
            || tmux switch-client -t "$SESSION_NAME"
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
