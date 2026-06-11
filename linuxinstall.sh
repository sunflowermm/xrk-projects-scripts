#!/bin/bash
# Copyright (c) 2026 Xrkseek
# Licensed under MIT License
# 主流程入口：按 detect_os 分发到各发行版安装脚本，支持全 Linux + 多架构

XRK_ROOT="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
if [ -f "$XRK_ROOT/shell_modules/xrk_base.sh" ]; then
    # shellcheck source=/dev/null
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
    xrk_加载底层 common
else
    if [ -f "$XRK_ROOT/shell_modules/common.sh" ]; then
        # shellcheck source=/dev/null
        source "$XRK_ROOT/shell_modules/common.sh"
    else
        # shellcheck source=/dev/null
        source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
    fi
fi
export SCRIPT_RAW_BASE

os=$(detect_os)
case "$os" in
    ubuntu)   xrk_run_script "project-install/Yunzai/ubuntu.sh" ;;
    debian)   xrk_run_script "project-install/Yunzai/debian.sh" ;;
    arch)     xrk_run_script "project-install/Yunzai/arch.sh" ;;
    centos)   xrk_run_script "project-install/Yunzai/centos.sh" ;;
    opensuse) xrk_run_script "project-install/Yunzai/opensuse.sh" ;;
    alpine)   xrk_run_script "project-install/Yunzai/alpine.sh" ;;
    void|gentoo)
        echo "未显式支持的发行版: $os，尝试通用安装流程..."
        xrk_run_script "project-install/Yunzai/generic.sh"
        ;;
    *)
        echo "未显式支持的发行版: $os"
        echo "尝试通用安装流程..."
        xrk_run_script "project-install/Yunzai/generic.sh"
        ;;
esac
