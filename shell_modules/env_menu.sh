#!/bin/bash
# 统一环境与工具安装菜单

_xrk_resolve_root() {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    if [ -f "${XRK_ROOT:-/xrk}/shell_modules/bootstrap.sh" ]; then
        export XRK_ROOT="${XRK_ROOT:-/xrk}"
        return 0
    fi
    local d
    for d in "$HOME/.xrk" "$HOME/xrk" "/xrk"; do
        if [ -f "$d/shell_modules/bootstrap.sh" ]; then
            XRK_ROOT="$d"
            export XRK_ROOT
            return 0
        fi
    done
    export XRK_ROOT="${XRK_ROOT:-/xrk}"
}
_xrk_resolve_root

root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
if type xrk_source_menu_head &>/dev/null; then
    xrk_source_menu_head 0 0
else
    xrk_bootstrap "${XRK_SOURCE:-3}" 0
    load_module "shell_modules/common.sh"
    load_module "shell_modules/init.sh"
    safe_source "shell_modules/menu_common.sh"
    menu_init 0 0
fi
safe_source "shell_modules/update.sh"

_xrk_bash_script() {
    local p="$1"
    shift
    if type xrk_exec_script &>/dev/null; then
        xrk_exec_script "$p" "$@"
    elif type xrk_run_script &>/dev/null; then
        xrk_run_script "$p" "$@"
    else
        bash <(curl -sL "${SCRIPT_RAW_BASE}/$p") "$@"
    fi
}

_env_run_action() {
    case "$1" in
        yq)       run_software "project-install/software/yq" ;;
        chromium) run_software "project-install/software/chromium" ;;
        node)     run_software "project-install/software/node" ;;
        pnpm)     run_software "project-install/software/pnpm" ;;
        ffmpeg)   run_software "project-install/software/ffmpeg" ;;
        python)   run_software "body/modules/python_uv.sh" ;;
        tmux)
            menu_check_xrk_repo "$XRK_ROOT" || return 1
            if [ ! -d "$HOME/.tmux/plugins/tpm" ] || { [ ! -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; }; then
                _xrk_bash_script "body/modules/tmux.sh" || return 1
            fi
            _xrk_bash_script "body/tmux.sh" || return 1
            ;;
        profile)
            menu_check_xrk_repo "$XRK_ROOT" || return 1
            XRK_PROFILE_QUIET=0 _xrk_bash_script "body/modules/profile.sh" || return 1
            ;;
        xrkk)
            menu_check_xrk_repo "$XRK_ROOT" || return 1
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

menu_run_loop "环境与工具安装" "  " \
    "yq" "Chromium" "Node.js" "pnpm" "ffmpeg" "Python + uv" \
    "tmux 安装/进入" "配置 .profile" "同步 xrkk 到 bin" "返回" \
    -- _env_handle
