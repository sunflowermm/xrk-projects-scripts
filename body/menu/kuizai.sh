#!/bin/bash
# 葵崽相关子菜单
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/menu_head.sh" 0 1

_kuizai_handle() {
    local n="$1"
    case "$n" in
        1) bash "$root/linuxinstall.sh" ;;
        2) bash "$root/body/menu/plugin.sh" ;;
        3) bash "$root/body/menu/errorbg.sh" ;;
        4)
            local _yz
            _yz="$(xrk_yz_dir)"
            if [ -f "$_yz/plugins/XRK/components/xrkksign.js" ]; then
                node "$_yz/plugins/XRK/components/xrkksign.js"
            else
                menu_msg_err "未找到换签脚本"
            fi
            ;;
    esac
}

menu_run_loop "葵崽相关" "安/重装葵崽" "插件相关" "报错修复" "一键换签" "返回" -- _kuizai_handle
