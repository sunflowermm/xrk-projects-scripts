#!/bin/bash
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/window_head.sh"
cd /root
echo -e "${caidan1}来福窗口${bg}"
echo -e "${caidan2}主菜单 xrk | 工具 xrkk sync|menu|path${bg}"
echo -e "${caidan3}tmux 帮助: 前缀 Alt+Space ?${bg}"
