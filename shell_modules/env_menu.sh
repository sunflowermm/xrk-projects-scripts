#!/bin/bash
# 统一环境与工具安装菜单
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/menu_boot.sh" 2>/dev/null || {
    # shellcheck source=/dev/null
    source "$root/shell_modules/xrk_boot.sh"
    xrk_ensure_bootstrap
}
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
            local sub
            sub=$(menu_read_choice "tmux [1]首次安装(插件) [2]进入桌面 [0]返回: ") || return 0
            case "$sub" in
                1)
                    xrk_exec_script "body/modules/tmux.sh" \
                        && menu_msg_ok "tmux 已就绪（含样式/cpu 等；不含 yank 复制插件）"
                    ;;
                2)
                    XRK_TMUX_NO_ATTACH=1 xrk_exec_script "body/tmux.sh" --no-attach \
                        && menu_msg_ok "桌面已在后台创建，请新开 SSH 执行: tmux attach -t 新年快乐" \
                        || menu_msg_err "进入失败：首次请先选 1 安装"
                    ;;
                0) ;;
                *) menu_msg_err "无效选项" ;;
            esac
            ;;
        profile)
            menu_require_repo || return 1
            XRK_PROFILE_QUIET=0 xrk_exec_script "body/modules/profile.sh" || return 1
            ;;
        bin|xrkk)
            menu_require_repo || return 1
            xrk_bin同步 || return 1
            menu_msg_ok "命令已同步到 ${XRK_BIN:-/usr/local/bin}"
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
    "tmux 安装/进入" "配置 .profile" "同步命令到 bin" "返回" \
    -- _env_handle
