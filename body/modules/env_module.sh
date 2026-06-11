#!/bin/bash
# 环境与模块子菜单 → env_menu
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
if [ -f "$XRK_ROOT/shell_modules/env_menu.sh" ]; then
    exec bash "$XRK_ROOT/shell_modules/env_menu.sh"
fi
if ! type xrk_exec_script &>/dev/null; then
    # shellcheck source=/dev/null
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
fi
xrk_exec_script "shell_modules/env_menu.sh"
