#!/bin/bash
# 环境与模块子菜单：tmux / ffmpeg / profile / xrkk 同步 / Python+uv
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -d "$XRK_ROOT" ] || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }
source "$XRK_ROOT/shell_modules/color.sh" 2>/dev/null || true
source "$XRK_ROOT/.init" 2>/dev/null || true
[ -f "$XRK_ROOT/shell_modules/menu_common.sh" ] && source "$XRK_ROOT/shell_modules/menu_common.sh"
[ -f "$XRK_ROOT/shell_modules/update.sh" ] && source "$XRK_ROOT/shell_modules/update.sh"

while true; do
    echo ""
    menu_show "环境与模块" "  " "安装/配置 tmux" "安装 ffmpeg" "配置 .profile" "同步 xrkk 到 bin" "Python + uv" "返回"
    echo ""
    read -rp "请选择 [0-${MENU_OPT_COUNT}]: " c
    c=$(echo "$c" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    [ "$c" = "0" ] || [ "$c" = "q" ] || [ "$c" = "${MENU_OPT_COUNT}" ] && exit 0
    case "$c" in
        1) bash "$XRK_ROOT/body/modules/tmux.sh" ;;
        2) bash "$XRK_ROOT/body/modules/ffmpeg.sh" ;;
        3) bash "$XRK_ROOT/body/modules/profile.sh" ;;
        4) xrkk同步 && echo "xrkk 已更新" ;;
        5) bash "$XRK_ROOT/body/modules/python_uv.sh" ;;
        *) echo "无效选择" ;;
    esac
done
