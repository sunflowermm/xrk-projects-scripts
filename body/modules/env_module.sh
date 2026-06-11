#!/bin/bash
# 环境与模块子菜单 → env_menu
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
if [ -f "$XRK_ROOT/shell_modules/env_menu.sh" ]; then
    exec bash "$XRK_ROOT/shell_modules/env_menu.sh"
fi
# shellcheck source=/dev/null
[ -f "$XRK_ROOT/shell_modules/menu_boot.sh" ] && source "$XRK_ROOT/shell_modules/menu_boot.sh" \
    || source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
xrk_exec_script "shell_modules/env_menu.sh"
