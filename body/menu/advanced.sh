#!/bin/bash
# 高级：切换主题、重装脚本
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1

THEMES=(".theme" ".theme2" ".theme3" ".theme4" ".theme5" ".theme6" ".theme7" ".theme8" ".theme9" ".theme10" ".theme11" ".theme12" ".theme13")
THEME_NAMES=("向日葵原版主题" "暗夜锋芒" "甜心微爱" "极光幻境" "霓虹都市" "薄暮流云" "科技未来" "沙漠晨曦" "深海之谜" "森林密语" "莓果甜心" "星空梦境" "金属光泽")

_advanced_handle() {
    case "$1" in
        1)
            menu_show "切换脚本主题" "${THEME_NAMES[@]}"
            echo
            color=$(menu_read_choice "选择主题 [1-13]，q 返回: ") || return 0
            menu_should_exit "$color" quit && return 0
            clear_menu
            if [[ "$color" =~ ^[0-9]+$ ]] && [ "$color" -ge 1 ] && [ "$color" -le 13 ]; then
                yq -i '.color = "'"${THEMES[$((color-1))]}"'"' "$root/system.yaml" 2>/dev/null
                [ -f "$root/.init" ] && . "$root/.init"
                menu_msg_ok "主题已更改"
                exit 0
            fi
            menu_msg_err "无效主题编号"
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
