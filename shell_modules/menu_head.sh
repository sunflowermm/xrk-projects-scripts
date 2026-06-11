#!/bin/bash
# 菜单脚本标准头部
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh"
xrk_source_menu_head "$@"
