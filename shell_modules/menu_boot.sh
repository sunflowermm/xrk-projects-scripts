#!/bin/bash
# 菜单脚本冷启动
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/bootstrap.sh" ] && source "$root/shell_modules/bootstrap.sh"
xrk_ensure_bootstrap
