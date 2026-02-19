#!/bin/bash
# Alpine 主流程安装
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_success "Alpine 主流程"
log_info "正在更新系统..."
apk update && apk upgrade -y || { log_error "更新失败"; exit 1; }
log_success "系统更新完成"

[ -f /xrk/project-install/software/yq ] && bash /xrk/project-install/software/yq || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/yq")
for pkg in git wget tar xz jq redis fontconfig; do install_package "$pkg"; done
安装xrk脚本
检测云崽存在魔法
检测npm-node-pnpm安装
command -v chromium &>/dev/null || install_package chromium
检测redis安装
云崽安装菜单
