#!/bin/bash
# 脚本仓库源配置：统一 SCRIPT_RAW_BASE 与 SCRIPT_CLONE_URL（依赖 bootstrap 的 init_repo_source）
# 供 xrk、.init、update、菜单脚本 等使用；参数 1=GitCode 2=GitHub 3=Gitee

if [ -f /xrk/shell_modules/bootstrap.sh ]; then
    source /xrk/shell_modules/bootstrap.sh
else
    # 首次引导：按传入参数 1/2/3 选择源，否则默认 3=Gitee
    case "${1#-}" in
        1) _BOOT_BASE="https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/main" ;;
        2) _BOOT_BASE="https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/main" ;;
        3|*) _BOOT_BASE="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master" ;;
    esac
    source <(curl -sL "${_BOOT_BASE}/shell_modules/bootstrap.sh")
fi
init_repo_source "$1"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
