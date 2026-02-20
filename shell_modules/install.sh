#!/bin/bash
# 主流程用：加载 common，对外 install_package → install_pkg
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/common.sh" ] && source "$root/shell_modules/common.sh" || {
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
}

install_package() { install_pkg "$1"; }
