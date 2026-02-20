#!/bin/bash
# 通用主流程：Void/Gentoo 及未显式支持的发行版
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_info "通用安装 (OS: $(detect_os))"
run_yq
for pkg in git wget tar xz jq redis; do install_package "$pkg"; done
command -v chromium &>/dev/null || install_package chromium 2>/dev/null || true
葵崽主流程安装
