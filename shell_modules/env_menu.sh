#!/bin/bash
# 统一环境与工具安装菜单（合并 xm env_install_menu 与 body/modules/env_module.sh）

root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/menu_head.sh" 0 0
# shellcheck source=/dev/null
[ -f "$root/shell_modules/update.sh" ] && source "$root/shell_modules/update.sh"

_env_run_action() {
    case "$1" in
        yq)       run_software "project-install/software/yq" ;;
        chromium) run_software "project-install/software/chromium" ;;
        node)     run_software "project-install/software/node" ;;
        pnpm)     run_software "project-install/software/pnpm" ;;
        ffmpeg)   run_software "project-install/software/ffmpeg" ;;
        python)   run_software "body/modules/python_uv.sh" ;;
        tmux)
            menu_check_dir "$XRK_ROOT" "请先安装脚本仓库到 $XRK_ROOT" || return 1
            if [ ! -d "$HOME/.tmux/plugins/tpm" ] || { [ ! -f "$HOME/.tmux.conf" ] && [ ! -L "$HOME/.tmux.conf" ]; }; then
                bash "$XRK_ROOT/body/modules/tmux.sh"
            fi
            bash "$XRK_ROOT/body/tmux.sh"
            ;;
        profile)  menu_check_dir "$XRK_ROOT" "请先安装脚本仓库" && XRK_PROFILE_QUIET=0 bash "$XRK_ROOT/body/modules/profile.sh" ;;
        xrkk)     menu_check_dir "$XRK_ROOT" "请先安装脚本仓库" && xrkk同步 && menu_msg_ok "xrkk 已更新" ;;
        *)        menu_msg_err "未知操作: $1"; return 1 ;;
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
