#!/bin/bash
# 软件安装脚本标准头部

SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
# shellcheck source=/dev/null
if [ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_base.sh" ]; then
    source "${XRK_ROOT:-/xrk}/shell_modules/xrk_base.sh"
    xrk_加载底层 software
else
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/bootstrap.sh")
    xrk_bootstrap
    load_module "shell_modules/common.sh"
    type xrk_init_software &>/dev/null && xrk_init_software
fi
