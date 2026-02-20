#!/bin/bash
# 高级：切换主题、重装脚本
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 0 1

THEMES=(".theme" ".theme2" ".theme3" ".theme4" ".theme5" ".theme6" ".theme7" ".theme8" ".theme9" ".theme10" ".theme11" ".theme12" ".theme13")
THEME_NAMES=("向日葵原版主题" "暗夜锋芒" "甜心微爱" "极光幻境" "霓虹都市" "薄暮流云" "科技未来" "沙漠晨曦" "深海之谜" "森林密语" "莓果甜心" "星空梦境" "金属光泽")

while true; do
    menu_show "脚本高级菜单" "切换脚本主题" "重装脚本"
    echo
    read -rp "请选择 [1-${MENU_OPT_COUNT}]，q 退出: " raw_patch
    patch=$(echo "$raw_patch" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    clear_menu
    [ "$patch" = "0" ] || [ "$patch" = "q" ] && exit 0
    case "$patch" in
        1)
            menu_show "切换脚本主题" "${THEME_NAMES[@]}"
            echo
            read -rp "选择主题 [1-13]，q 返回: " color
            color=$(echo "$color" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
            [ "$color" = "q" ] && continue
            clear_menu
            if [[ "$color" =~ ^[0-9]+$ ]] && [ "$color" -ge 1 ] && [ "$color" -le 13 ]; then
                yq -i '.color = "'"${THEMES[$((color-1))]}"'"' "$root/system.yaml" 2>/dev/null
                [ -f "$root/.init" ] && . "$root/.init"
                echo -e "${caidan1}更改${bg}${caidan2}完成${bg}"
                exit 0
            fi
            ;;
        2)
            yz="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}"
            if [ -n "$yz" ] && [ -d "$yz" ]; then
                bash "$root/body/xrkwrite.sh"
            else
                echo -e "${red}未检测到葵崽(XRK-Yunzai)路径，请先安装主流程${bg}"
                read -rp "按回车返回..." _
            fi
            ;;
        *)
            echo -e "${red}无效选择${bg}"
            ;;
    esac
done
