#!/bin/bash
# xm 入口标准头部
# 用法：source "$XRK_ROOT/shell_modules/xm_head.sh"

if ! type xrk_load_xm &>/dev/null; then
    root="${XRK_ROOT:-/xrk}"
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    if [ -f "$root/shell_modules/bootstrap.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/bootstrap.sh"
    else
        # shellcheck source=/dev/null
        source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
    fi
fi
xrk_load_xm
