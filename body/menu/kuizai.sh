#!/bin/bash
# 葵崽相关子菜单：安/重装葵崽、插件相关、报错修复、一键换签
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 0 0
yz="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}"

while true; do
    menu_show "葵崽相关" "安/重装葵崽" "插件相关" "报错修复" "一键换签" "返回"
    read -rp "请选择 [1-${MENU_OPT_COUNT}]，0 或 q 返回: " raw_choice
    choice=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    [ -z "$choice" ] && continue
    [ "$choice" = "0" ] || [ "$choice" = "q" ] || [ "$choice" = "$MENU_OPT_COUNT" ] && exit 0
    case "$choice" in
        1) bash "$root/linuxinstall.sh" ;;
        2) bash "$root/body/menu/plugin.sh" ;;
        3) bash "$root/body/menu/errorbg.sh" ;;
        4) [ -f "$yz/plugins/XRK/components/xrkksign.js" ] && node "$yz/plugins/XRK/components/xrkksign.js" || echo -e "${red}未找到换签脚本${bg}" ;;
        *) echo -e "${red}无效选择${bg}" ;;
    esac
    echo
done
