#!/bin/bash
# 葵崽 / 葵子 子菜单
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1
safe_source "shell_modules/kuizi_products.sh"
safe_source "shell_modules/kuizi_repos.sh"

_kuizai_handle() {
    local n="$1"
    case "$n" in
        1) bash "$root/linuxinstall.sh" ;;
        2) kuizi_install_agt ;;
        3) bash "$root/body/menu/plugin.sh" ;;
        4) bash "$root/body/menu/errorbg.sh" ;;
        5) kuizi_manage_menu ;;
    esac
}

menu_run_loop "葵崽 / 葵子" \
    "安/重装葵崽" "安/重装葵子" "插件相关(葵崽)" "报错修复(葵崽)" "路径与状态管理" "返回" \
    -- _kuizai_handle
