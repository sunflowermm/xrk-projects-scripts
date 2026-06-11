#!/bin/bash
# 源配置：SCRIPT_RAW_BASE / SCRIPT_CLONE_URL；参数 1=GitCode 2=GitHub 3=Gitee
XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
if [ -f "$XRK_ROOT/shell_modules/xrk_base.sh" ]; then
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
    _xrk_ensure_bootstrap
else
    source <(curl -sL "https://gitee.com/xrkseek/xrk-projects-scripts/raw/master/shell_modules/bootstrap.sh")
fi
xrk_bootstrap "${1:-}" 0
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
