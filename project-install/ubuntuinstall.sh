#!/bin/bash
# Ubuntu 主流程安装
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_success "Ubuntu 主流程"
# 更新系统
log_info "正在更新系统软件包..."
if apt update && apt upgrade -y; then
    log_success "系统更新完成"
else
    log_error "系统更新失败，请重新运行脚本"
    exit 1
fi

[ -f /xrk/project-install/software/yq ] && bash /xrk/project-install/software/yq || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/yq")
# 安装基本工具
for package in git wget tar dialog xz-utils jq redis sudo tmux fonts-wqy*; do
    install_package "$package"
done

# 安装脚本
安装xrk脚本

# 删除云崽（如果存在）
检测云崽存在魔法

# 下载 Node 和 npm
检测npm-node-pnpm安装

# 检查浏览器
log_info "开始检查 Chromium ..."
[ -f /xrk/project-install/software/chromium ] && bash /xrk/project-install/software/chromium || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/chromium")

# 启动 Redis
检测redis安装

# 提供 menu
云崽安装菜单