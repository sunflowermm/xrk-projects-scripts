#!/bin/bash
# 高级：切换主题、重装脚本
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1
# shellcheck source=/dev/null
[ -f "$root/shell_modules/theme.sh" ] && source "$root/shell_modules/theme.sh"

_advanced_handle() {
    case "$1" in
        1)
            menu_show "切换脚本主题" "${XRK_THEME_NAMES[@]}"
            echo
            local pick
            pick=$(menu_read_choice "选择主题 [1-${#XRK_THEMES[@]}]，q 返回: ") || return 0
            menu_should_exit "$pick" quit && return 0
            clear_menu
            case "$(xrk_theme_menu_apply "$pick"; echo $?)" in
                0) menu_msg_ok "主题已更改，返回主菜单后生效" ;;
                2) menu_msg_err "请先安装 yq（环境与工具 → yq）" ;;
                *) menu_msg_err "无效主题编号" ;;
            esac
            ;;
        2)
            local _yz; _yz="$(xrk_yz_dir)"
            if menu_check_dir "$_yz" "未检测到葵崽路径，请先安装主流程"; then
                bash "$root/body/xrkwrite.sh"
            else
                menu_pause
            fi
            ;;
    esac
}

menu_run_loop "脚本高级菜单" "切换脚本主题" "重装脚本" -- _advanced_handle
