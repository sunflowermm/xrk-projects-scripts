#!/bin/bash
# 环境与模块子菜单 → env_menu
root="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
if [ -f "$root/shell_modules/env_menu.sh" ]; then
    exec bash "$root/shell_modules/env_menu.sh"
fi
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" \
    || { tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-boot.XXXXXX"); curl -fsSL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/xrk_boot.sh" -o "$tmp"; source "$tmp"; rm -f "$tmp"; xrk_ensure_bootstrap; }
xrk_exec_script "shell_modules/env_menu.sh"
