#!/bin/bash
# 源配置：SCRIPT_RAW_BASE / SCRIPT_CLONE_URL；参数 1=GitCode 2=GitHub 3=Gitee
_DEFAULT_RAW_BASE="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master"
if [ -f "${XRK_ROOT:-/xrk}/shell_modules/bootstrap.sh" ]; then
    source "${XRK_ROOT:-/xrk}/shell_modules/bootstrap.sh"
else
    case "${1#-}" in
        1) _BOOT_BASE="https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/main" ;;
        2) _BOOT_BASE="https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/main" ;;
        3|*) _BOOT_BASE="$_DEFAULT_RAW_BASE" ;;
    esac
    source <(curl -sL "${_BOOT_BASE}/shell_modules/bootstrap.sh")
fi
init_repo_source "$1"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
