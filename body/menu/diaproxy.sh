#!/bin/bash
# GitHub 代理切换（whiptail 触屏版）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1 github.sh plugin_proxy.sh

RED="${RED:-\033[31m}"
GREEN="${GREEN:-\033[1;32m}"
YELLOW="${YELLOW:-\033[33m}"
BLUE='\033[38;2;30;144;255m'
NC="${NC:-\033[0m}"

export NEWT_COLORS='
root=,black
window=white,black
border=white,black
textbox=white,black
button=black,blue
actbutton=white,red
title=blue,black
'

show_loading() {
    local message=$1 frames=("◐" "◓" "◑" "◒") colors=("$BLUE" "$GREEN" "$YELLOW" "$BLUE") i=0
    ( while true; do
        printf "\r${colors[i]}%s ${frames[i]} ${NC}" "$message"
        i=$(( (i + 1) % 4 )); sleep 0.12
    done ) &
    SPIN_PID=$!
}

stop_loading() {
    kill $SPIN_PID 2>/dev/null
    printf "\r%*s\r" $(($(tput cols))) ""
}

get_proxy() {
    local proxy
    proxy=$(xrk_pick_best_proxy)
    if [ -n "$proxy" ]; then
        echo -e "${GREEN}✨ 已找到最佳代理: ${proxy}${NC}" >&2
        echo "$proxy"
        return 0
    fi
    return 1
}

manage_plugins() {
    local plugins_path="$(xrk_yz_dir)/plugins" filtered_dirs=() menu_items=() selected_plugin selected_dir proxy

    while true; do
        if [ ! -d "$plugins_path" ]; then
            whiptail --title "错误提示" --msgbox "❌ 插件目录不存在，请检查路径" 8 40
            exit 1
        fi

        mapfile -t filtered_dirs < <(xrk_list_plugin_dirs "$plugins_path")
        menu_items=()
        for dir in "${filtered_dirs[@]}"; do
            if [ -d "$dir/.git" ]; then
                menu_items+=("$(basename "$dir")" "📦 Git仓库")
            else
                menu_items+=("$(basename "$dir")" "📁 普通目录")
            fi
        done

        if [ ${#filtered_dirs[@]} -eq 0 ]; then
            whiptail --title "提示信息" --msgbox "📝 未找到可管理的插件" 8 40
            exit 1
        fi

        selected_plugin=$(whiptail --title "插件管理" --menu "请选择要操作的插件:" \
            --ok-button "确定" --cancel-button "返回" 15 60 8 "${menu_items[@]}" 3>&1 1>&2 2>&3)
        [ $? -ne 0 ] && break

        selected_dir=""
        for dir in "${filtered_dirs[@]}"; do
            [ "$(basename "$dir")" = "$selected_plugin" ] && { selected_dir="$dir"; break; }
        done

        if [ ! -d "$selected_dir/.git" ]; then
            whiptail --title "错误提示" --msgbox "❌ ${selected_plugin} 不是Git仓库，无法管理" 8 45
            continue
        fi

        show_loading "🔄 正在扫描可用代理..."
        proxy=$(get_proxy)
        stop_loading

        if [ -n "$proxy" ]; then
            show_loading "⬇️ 正在使用代理 ${proxy} 更新插件..."
            if xrk_apply_github_proxy "$selected_dir" "$proxy"; then
                stop_loading
                whiptail --title "操作成功" --msgbox "✅ 已成功使用代理 ${proxy} 更新插件！" 8 60
            else
                stop_loading
                whiptail --title "错误提示" --msgbox "❌ 使用代理 ${proxy} 更新失败，请重试" 8 60
            fi
        else
            whiptail --title "错误提示" --msgbox "❌ 未能找到可用的代理服务器" 8 40
        fi
    done
}

clear
if whiptail --title "GitHub 代理优化工具" --yes-button "启动" --no-button "关闭" --yesno "
        🚀 GitHub 代理切换工具

✨ 主要功能:
 • 智能检测最快代理
 • 一键切换代理设置
 • 优化访问速度

🔄 开始优化之旅?" 15 48; then
    manage_plugins
fi
clear
