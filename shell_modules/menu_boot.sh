#!/bin/bash
# 菜单脚本冷启动
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
if [ -f "$root/shell_modules/xrk_boot.sh" ]; then
    source "$root/shell_modules/xrk_boot.sh"
elif [ -f "$root/shell_modules/bootstrap.sh" ]; then
    source "$root/shell_modules/bootstrap.sh"
fi
xrk_ensure_bootstrap
