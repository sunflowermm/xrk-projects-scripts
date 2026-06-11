#!/bin/bash
# 菜单脚本冷启动（供 body/menu/* 首行 source）
root="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
if ! type xrk_source_menu_head &>/dev/null; then
    if [ -f "$root/shell_modules/bootstrap.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/bootstrap.sh"
    else
        # shellcheck source=/dev/null
        source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
    fi
fi
