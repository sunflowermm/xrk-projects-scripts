#!/bin/bash
# Alpine 主流程：更新、依赖、葵崽主流程安装
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_success "Alpine 主流程"
log_info "正在更新系统..."
apk update && apk upgrade -y || { log_error "更新失败"; exit 1; }

run_yq
for pkg in git wget tar xz jq redis fontconfig; do install_package "$pkg"; done
command -v chromium &>/dev/null || install_package chromium 2>/dev/null || true
葵崽主流程安装
