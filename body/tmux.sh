#!/bin/bash
# 向日葵 tmux 桌面：xrk-tmux [--setup|--status|--no-attach|-h]

XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
# shellcheck source=/dev/null
[ -f "$XRK_ROOT/shell_modules/xrk_config.sh" ] && source "$XRK_ROOT/shell_modules/xrk_config.sh"

SESSION_NAME="${XRK_TMUX_SESSION:-新年快乐}"
TMUX_CONF="${HOME}/.tmux.conf"
XRK_MENU="$HOME/.tmux/xrk-menu"
read -ra XRK_TMUX_WINDOWS <<< "${XRK_TMUX_WINDOW_NAMES:-来财 来福 来运}"

_tmux_usage() {
    cat <<EOF
用法: xrk-tmux [选项]
  (无参数)    进入或创建「${SESSION_NAME}」桌面
  --setup     安装 tmux 并写入配置
  --status    检查环境
  --no-attach 只创建/检查，不 attach（菜单 7→2 使用）
  -h, --help  本帮助

快捷键: 前缀 Alt+Space | 分离 d | 重载 r | 帮助 ?
窗口: ${XRK_TMUX_WINDOWS[*]}
EOF
}

_tmux_ensure_utf8() {
    case "${LANG:-}" in
        *UTF-8*|*utf8*) ;;
        *) export LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 ;;
    esac
}

_tmux_apply_window_names() {
    local session="$1" i name
    [ -n "$session" ] || return 0
    tmux has-session -t "$session" 2>/dev/null || return 0
    for i in "${!XRK_TMUX_WINDOWS[@]}"; do
        name="${XRK_TMUX_WINDOWS[$i]}"
        tmux rename-window -t "$session:$i" "$name" 2>/dev/null || true
    done
}

_tmux_conf_ok() {
    [ -f "$TMUX_CONF" ] || return 1
    grep -q "source-file.*body/.tmux.conf" "$TMUX_CONF" 2>/dev/null || return 1
    grep -q "xrk-mouse.conf" "$TMUX_CONF" 2>/dev/null || return 1
    return 0
}

_tmux_repair_config() {
    local mod="$XRK_ROOT/body/modules/tmux.sh"
    [ -f "$mod" ] || return 1
    bash "$mod" --link-only >/dev/null 2>&1 || return 1
    _tmux_conf_ok
}

_tmux_status() {
    echo "tmux: $(command -v tmux >/dev/null && tmux -V || echo 未安装)"
    echo "配置: $TMUX_CONF $(_tmux_conf_ok && echo OK || echo 未链接)"
    [ -x "$XRK_MENU" ] && echo "菜单: $XRK_MENU OK" || echo "菜单: 缺失（xrk-tmux --setup）"
    tmux has-session -t "$SESSION_NAME" 2>/dev/null \
        && echo "会话: $SESSION_NAME 已存在" \
        || echo "会话: $SESSION_NAME 未创建"
}

_tmux_session_usable() {
    local s="$1" n
    tmux has-session -t "$s" 2>/dev/null || return 1
    n=$(tmux list-windows -t "$s" 2>/dev/null | wc -l)
    [ "${n:-0}" -ge 3 ]
}

_tmux_can_attach() {
    [ "${XRK_TMUX_NO_ATTACH:-0}" = "1" ] && return 1
    [ -n "${SSH_CONNECTION:-}" ] || return 1
    [ -t 0 ] && [ -t 1 ] || return 1
    return 0
}

_tmux_print_attach_hint() {
    local target="${1:-$SESSION_NAME}"
    echo "[tmux] 会话: $target（后台运行）"
    echo "[tmux] SSH 进入: tmux attach -t $target"
}

_tmux_connect() {
    local target="$1" cur
    [ -z "$target" ] && return 1
    [ "$target" = "$SESSION_NAME" ] && _tmux_apply_window_names "$target"

    if [ -n "$TMUX" ]; then
        cur=$(tmux display-message -p '#S' 2>/dev/null || true)
        if [ "$cur" = "$target" ]; then
            echo "[tmux] 已在会话: $target"
            return 0
        fi
        tmux switch-client -t "$target"
        return
    fi

    if ! _tmux_can_attach; then
        _tmux_print_attach_hint "$target"
        return 0
    fi
    echo "[tmux] 连接: $target"
    tmux attach-session -t "$target"
}

create_desktop_layout() {
    local s="$SESSION_NAME"
    _tmux_ensure_utf8

    if _tmux_session_usable "$s"; then
        _tmux_apply_window_names "$s"
        echo "[tmux] 桌面已存在: ${XRK_TMUX_WINDOWS[*]}"
        return 0
    fi

    tmux has-session -t "$s" 2>/dev/null && tmux kill-session -t "$s" 2>/dev/null || true

    (
        set -e
        tmux new-session -d -s "$s" -n "${XRK_TMUX_WINDOWS[0]}" "exec bash"
        tmux split-window -v -t "$s:0" "exec bash"
        tmux new-window -t "$s:1" -n "${XRK_TMUX_WINDOWS[1]}" "exec bash"
        tmux split-window -h -t "$s:1" "exec bash"
        tmux new-window -t "$s:2" -n "${XRK_TMUX_WINDOWS[2]}" "exec bash"
        tmux split-window -h -t "$s:2" "exec bash"
        tmux select-window -t "$s:0"
    ) || { echo "[tmux] 创建失败" >&2; return 1; }

    _tmux_apply_window_names "$s"
    echo "[tmux] 桌面已创建: ${XRK_TMUX_WINDOWS[*]}"
}

ensure_tmux_env() {
    command -v tmux &>/dev/null || {
        echo "[tmux] 未安装，请菜单 7→1 或 xrk-tmux --setup" >&2
        return 1
    }
    _tmux_conf_ok || _tmux_repair_config || {
        echo "[tmux] 配置未就绪，请菜单 7→1" >&2
        return 1
    }
    [ -x "$XRK_MENU" ] || _tmux_repair_config || {
        echo "[tmux] 菜单脚本缺失，请菜单 7→1" >&2
        return 1
    }
}

goto_desktop() {
    local target
    _tmux_ensure_utf8
    ensure_tmux_env || exit 1

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        _tmux_connect "$SESSION_NAME"
        return
    fi

    echo "[tmux] 创建向日葵桌面…"
    create_desktop_layout || exit 1
    _tmux_connect "$SESSION_NAME"
}

case "${1:-}" in
    -h|--help)   _tmux_usage; exit 0 ;;
    --status)    _tmux_status; exit 0 ;;
    --no-attach) export XRK_TMUX_NO_ATTACH=1; shift ;;
    --setup)
        bash "$XRK_ROOT/body/modules/tmux.sh"
        exit $?
        ;;
esac

goto_desktop
