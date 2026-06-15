#!/bin/bash
# tmux 窗格脚本标准头部（轻量：仅颜色 + 默认产品路径，禁止全盘 find）
root="${XRK_ROOT:-/xrk}"

if [ -z "${caidan1:-}" ] && [ -f "$root/.init" ]; then
    # shellcheck source=/dev/null
    source "$root/.init"
elif [ -f "$root/shell_modules/color.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/shell_modules/color.sh"
    [ -f "$root/.color" ] && source "$root/.color" 2>/dev/null || true
fi

# 只认默认目录，避免 7 个窗格并行 search_directories 扫盘
_yz_default="${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
_agt_default="${AGT_DEFAULT_DIR:-$HOME/XRK-AGT}"
[ -d "$_yz_default" ] && export yz="$_yz_default" xyz="$_yz_default"
[ -d "$_agt_default" ] && export agt="$_agt_default"

red="${color_red:-\033[31m}"
green="${bold_green:-\033[1;32m}"
yellow="${color_yellow:-\033[33m}"
bg="${bg:-\033[0m}"
RED="${RED:-$red}"
GREEN="${GREEN:-$green}"
YELLOW="${YELLOW:-$yellow}"
NC="${NC:-$bg}"

xrk_yz_dir() { echo "${yz:-}"; }
xrk_agt_dir() { echo "${agt:-}"; }
