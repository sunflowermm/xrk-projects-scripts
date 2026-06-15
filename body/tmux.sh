#!/bin/bash
# 向日葵 tmux 桌面：xrk-tmux [--setup|--status|-h]

XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
# shellcheck source=/dev/null
[ -f "$XRK_ROOT/shell_modules/xrk_config.sh" ] && source "$XRK_ROOT/shell_modules/xrk_config.sh"

SESSION_NAME="${XRK_TMUX_SESSION:-新年快乐}"
TMUX_CONF="${HOME}/.tmux.conf"
TMUX_BOOTSTRAP="${XRK_ROOT}/body/.tmux.bootstrap.conf"
XRK_MENU="$HOME/.tmux/xrk-menu"
read -ra XRK_TMUX_WINDOWS <<< "${XRK_TMUX_WINDOW_NAMES:-来财 来福 来运}"

_tmux_usage() {
    cat <<EOF
用法: xrk-tmux [选项]
  (无参数)    进入或创建「${SESSION_NAME}」桌面
  --setup     仅安装/配置 tmux（tpm、插件、配置链接）
  --status    检查 tmux 环境
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

_tmux_latest_session() {
    tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null \
        | sort -rn | head -1 | cut -d' ' -f2-
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
    [ -f "$XRK_ROOT/body/.tmux.conf" ] || return 1
    bash "$mod" --link-only >/dev/null 2>&1 || return 1
    _tmux_conf_ok
}

_tmux_plugins_ok() {
    local name
    for name in tmux-sensible tmux-resurrect tmux-continuum tmux-yank tmux-open tmux-prefix-highlight; do
        [ -d "$HOME/.tmux/plugins/$name" ] || return 1
    done
    return 0
}

_tmux_status_plugins() {
    local entry name dest
    for entry in \
        "tpm|https://github.com/tmux-plugins/tpm.git" \
        "tmux-sensible|https://github.com/tmux-plugins/tmux-sensible.git" \
        "tmux-resurrect|https://github.com/tmux-plugins/tmux-resurrect.git" \
        "tmux-continuum|https://github.com/tmux-plugins/tmux-continuum.git" \
        "tmux-yank|https://github.com/tmux-plugins/tmux-yank.git" \
        "tmux-open|https://github.com/tmux-plugins/tmux-open.git" \
        "tmux-prefix-highlight|https://github.com/tmux-plugins/tmux-prefix-highlight.git"; do
        name="${entry%%|*}"
        dest="$HOME/.tmux/plugins/$name"
        if [ -d "$dest/.git" ]; then
            echo "  $name: OK"
        else
            echo "  $name: 缺失"
        fi
    done
}

_tmux_status() {
    echo "tmux: $(command -v tmux >/dev/null && tmux -V || echo 未安装)"
    echo "配置: $TMUX_CONF $(_tmux_conf_ok && echo OK || echo 未链接)"
    [ -x "$XRK_MENU" ] && echo "菜单脚本: $XRK_MENU OK" || echo "菜单脚本: 缺失（请 xrk-tmux --setup）"
    [ -f "$HOME/.tmux/xrk-mouse.conf" ] && echo "右键绑定: $HOME/.tmux/xrk-mouse.conf OK" || echo "右键绑定: 缺失（请 xrk-tmux --setup）"
    echo "tpm:  $([ -f "$HOME/.tmux/plugins/tpm/tpm" ] && echo OK || echo 缺失)"
    echo "插件:"
    _tmux_status_plugins
    echo "汇总: $(_tmux_plugins_ok && echo 齐全 || echo 不完整)"
    tmux has-session -t "$SESSION_NAME" 2>/dev/null \
        && echo "会话: $SESSION_NAME 已存在" \
        || echo "会话: $SESSION_NAME 未创建"
}

_tmux_reload_conf() {
    if tmux source-file "$TMUX_CONF" 2>/dev/null; then
        [ -n "$TMUX" ] && tmux display-message "配置已重载" 2>/dev/null || true
        return 0
    fi
    echo "[tmux] 配置重载失败: $TMUX_CONF" >&2
    return 1
}

_tmux_clean_resurrect_if_huge() {
    local dir="$HOME/.tmux/resurrect" sz
    [ -d "$dir" ] || return 0
    sz=$(du -sm "$dir" 2>/dev/null | cut -f1)
    [ "${sz:-0}" -le 20 ] && return 0
    rm -rf "${dir:?}"/*
    echo "[tmux] 已清理过大的 resurrect 缓存 (${sz}MB)，避免恢复时卡死"
}

_tmux_load_full_conf() {
    _tmux_clean_resurrect_if_huge
    tmux source-file "$TMUX_CONF" 2>/dev/null || {
        echo "[tmux] 加载完整配置失败: $TMUX_CONF" >&2
        return 1
    }
}

_tmux_can_attach() {
    [ "${XRK_TMUX_NO_ATTACH:-0}" = "1" ] && return 1
    # Web 面板/非 SSH 常有伪 tty，attach 会卡死且 Ctrl+C 无效
    [ -n "${SSH_CONNECTION:-}" ] || return 1
    [ -t 0 ] && [ -t 1 ] || return 1
    return 0
}

_tmux_print_attach_hint() {
    local target="${1:-$SESSION_NAME}"
    echo "[tmux] 桌面会话: $target（已在后台运行）"
    echo "[tmux] 请新开 SSH 窗口执行: tmux attach -t $target"
    echo "[tmux] 分离会话: 前缀 Alt+Space 然后按 d"
}

_tmux_resolve_target() {
    tmux has-session -t "$SESSION_NAME" 2>/dev/null && { echo "$SESSION_NAME"; return; }
    _tmux_latest_session
}

_tmux_connect() {
    local target="$1" cur
    [ -z "$target" ] && return 1
    [ "$target" = "$SESSION_NAME" ] && _tmux_apply_window_names "$target"

    if [ -n "$TMUX" ]; then
        cur=$(tmux display-message -p '#S' 2>/dev/null || true)
        if [ "$cur" = "$target" ]; then
            echo "[tmux] 已在会话: $target"
            _tmux_reload_conf
            return 0
        fi
        echo "[tmux] 切换到会话: $target"
        tmux switch-client -t "$target"
        return
    fi

    echo "[tmux] 连接到会话: $target"
    if ! _tmux_can_attach; then
        _tmux_print_attach_hint "$target"
        return 0
    fi
    tmux attach-session -t "$target"
}

create_desktop_layout() {
    local s="$SESSION_NAME" boot="${TMUX_BOOTSTRAP}"
    _tmux_ensure_utf8
    [ -f "$boot" ] || { echo "[tmux] 缺少 $boot" >&2; return 1; }

    tmux has-session -t "$s" 2>/dev/null && tmux kill-session -t "$s" 2>/dev/null || true

    (
        set -e
        tmux -f "$boot" new-session -d -s "$s" -n "${XRK_TMUX_WINDOWS[0]}" "exec bash"
        tmux split-window -v -t "$s:0" "exec bash"
        tmux new-window -t "$s:1" -n "${XRK_TMUX_WINDOWS[1]}" "exec bash"
        tmux split-window -h -t "$s:1" "exec bash"
        tmux new-window -t "$s:2" -n "${XRK_TMUX_WINDOWS[2]}" "exec bash"
        tmux split-window -h -t "$s:2" "exec bash"
        tmux select-window -t "$s:0"
    ) || { echo "[tmux] 创建会话失败" >&2; return 1; }

    _tmux_apply_window_names "$s"
    _tmux_load_full_conf || true
    tmux display-message -t "$s" -d 4000 \
        "向日葵 tmux | 前缀 Alt+Space ? | 主菜单 xrk | 葵崽 xyz | 葵子 xag" 2>/dev/null || true
    echo "[tmux] 桌面已创建: ${XRK_TMUX_WINDOWS[*]}"
}

ensure_tmux_env() {
    command -v tmux &>/dev/null || {
        echo "[tmux] 未安装 tmux，请先菜单 7→1 或 xrk-tmux --setup" >&2
        return 1
    }
    if ! _tmux_conf_ok; then
        if _tmux_repair_config; then
            echo "[tmux] 已自动补写配置（重启后无需重装，直接进桌面即可）"
        else
            echo "[tmux] 配置未就绪，请先菜单 7→1 安装一次" >&2
            return 1
        fi
    fi
    if [ ! -x "$XRK_MENU" ]; then
        _tmux_repair_config || {
            echo "[tmux] 菜单脚本缺失，请先菜单 7→1" >&2
            return 1
        }
    fi
    if [ ! -f "$HOME/.tmux/plugins/tpm/tpm" ]; then
        echo "[tmux] 首次使用需安装插件，请菜单 7→1（只需一次）" >&2
        return 1
    fi
    _tmux_plugins_ok || echo "[tmux] 部分插件缺失，可先进入；完整补装: 菜单 7→1" >&2
    return 0
}

goto_desktop() {
    local target

    _tmux_ensure_utf8
    ensure_tmux_env || exit 1
    target=$(_tmux_resolve_target)
    if [ -n "$target" ]; then
        _tmux_connect "$target"
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
