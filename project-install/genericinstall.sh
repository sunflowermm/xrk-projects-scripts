#!/bin/bash
# 通用主流程：Void/Gentoo 及未显式支持的发行版
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_info "通用安装 (OS: $(detect_os))"
[ -f /xrk/project-install/software/yq ] && bash /xrk/project-install/software/yq || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/yq")
for pkg in git wget tar xz jq redis; do install_package "$pkg"; done
安装xrk脚本
检测云崽存在魔法
检测npm-node-pnpm安装
command -v chromium &>/dev/null || install_package chromium 2>/dev/null || log_info "Chromium 请手动安装"
检测redis安装
云崽安装菜单
