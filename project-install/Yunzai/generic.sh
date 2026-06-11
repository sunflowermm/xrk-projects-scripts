#!/bin/bash
# 通用主流程：Void/Gentoo 及未显式支持的发行版（逻辑见 shell_modules/yunzai_distro.sh）
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")
yunzai_distro_main generic
