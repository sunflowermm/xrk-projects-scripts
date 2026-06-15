#!/bin/bash
# 统一环境与工具安装菜单
root="${XRK_ROOT:-/xrk}"
if [ -f "$root/shell_modules/menu_boot.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/shell_modules/menu_boot.sh"
else
    # shellcheck source=/dev/null
    if [ -f "$root/shell_modules/xrk_boot.sh" ]; then
        source "$root/shell_modules/xrk_boot.sh"
    elif [ -f "$root/shell_modules/bootstrap.sh" ]; then
        source "$root/shell_modules/bootstrap.sh"
    else
        tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-bootstrap.XXXXXX") || exit 1
        curl -fsSL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh" \
            -o "$tmp" || exit 1
        source "$tmp"
        rm -f "$tmp"
    fi
    xrk_ensure_bootstrap
fi
xrk_load_menu_head 0 0
safe_source "shell_modules/update.sh"

_env_run_action() {
    case "$1" in
        yq)       run_software "project-install/software/yq" ;;
        chromium) run_software "project-install/software/chromium" ;;
        node)     run_software "project-install/software/node" ;;
        pnpm)     run_software "project-install/software/pnpm" ;;
        ffmpeg)   run_software "project-install/software/ffmpeg" ;;
        python)   run_software "body/modules/python_uv.sh" ;;
        tmux)
            menu_require_repo || return 0
            xrk_exec_script "body/tmux.sh" || { menu_msg_err "tmux 进入失败"; return 0; }
            ;;
        profile)
            menu_require_repo || return 1
            XRK_PROFILE_QUIET=0 xrk_exec_script "body/modules/profile.sh" || return 1
            ;;
        xrkk)
            menu_require_repo || return 1
            xrkk同步 || return 1
            menu_msg_ok "xrkk 已更新"
            ;;
        *) menu_msg_err "未知操作: $1"; return 1 ;;
    esac
}

_env_handle() {
    case "$1" in
        1) _env_run_action yq ;;
        2) _env_run_action chromium ;;
        3) _env_run_action node ;;
        4) _env_run_action pnpm ;;
        5) _env_run_action ffmpeg ;;
        6) _env_run_action python ;;
        7) _env_run_action tmux ;;
        8) _env_run_action profile ;;
        9) _env_run_action xrkk ;;
    esac
}

menu_run_loop "环境与工具安装" \
    "yq" "Chromium" "Node.js" "pnpm" "ffmpeg" "Python + uv" \
    "tmux 安装/进入" "配置 .profile" "同步 xrkk 到 bin" "返回" \
    -- _env_handle
