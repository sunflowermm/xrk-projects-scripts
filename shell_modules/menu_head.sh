#!/bin/bash
# 菜单脚本标准头部
# 用法：source "$root/shell_modules/menu_head.sh" <need_common:0|1> <need_check:0|1> [附加模块...]
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh"
xrk_load_menu_head "$@"
