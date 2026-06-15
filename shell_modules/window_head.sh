#!/bin/bash
# tmux 窗格：仅颜色，绝不 source .init（.init 含 search_directories 扫盘）
root="${XRK_ROOT:-/xrk}"

if [ -f "$root/shell_modules/color.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/shell_modules/color.sh"
    [ -f "$root/.color" ] && source "$root/.color" 2>/dev/null || true
fi

_yz_default="${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
_agt_default="${AGT_DEFAULT_DIR:-$HOME/XRK-AGT}"
[ -d "$_yz_default" ] && export yz="$_yz_default" xyz="$_yz_default"
[ -d "$_agt_default" ] && export agt="$_agt_default"

red="${color_red:-\033[31m}"
green="${bold_green:-\033[1;32m}"
yellow="${color_yellow:-\033[33m}"
bg="${bg:-\033[0m}"

xrk_yz_dir() { echo "${yz:-}"; }
xrk_agt_dir() { echo "${agt:-}"; }
