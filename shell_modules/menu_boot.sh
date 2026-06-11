#!/bin/bash
# 菜单脚本冷启动
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/xrk_boot.sh" ] && source "$root/shell_modules/xrk_boot.sh" \
    || source "$(dirname "${BASH_SOURCE[0]}")/xrk_boot.sh" 2>/dev/null \
    || source "${root}/shell_modules/xrk_boot.sh"
xrk_ensure_bootstrap
