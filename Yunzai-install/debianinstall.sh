#!/bin/bash
# Debian 主流程安装
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
[ -f /xrk/shell_modules/distro_install_head.sh ] && source /xrk/shell_modules/distro_install_head.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/distro_install_head.sh")

log_success "Debian/Ubuntu 主流程"

# 更新系统
log_info "正在更新系统软件包..."
if apt-get update && apt-get upgrade -y; then
    log_success "系统更新完成"
else
    log_error "系统更新失败，请重新运行脚本"
    exit 1
fi

[ -f /xrk/Yunzai-install/software/yq ] && bash /xrk/Yunzai-install/software/yq || bash <(curl -sL "$SCRIPT_RAW_BASE/Yunzai-install/software/yq")
for package in git wget dialog tar xz-utils jq redis tmux fontconfig fonts-wqy-zenhei; do
    install_package "$package"
done

# 安装脚本
安装xrk脚本

# 删除云崽（如果存在）
检测云崽存在魔法

# 下载 Node 和 npm
检测npm-node-pnpm安装

# 检查和安装 Chromium
if ! command -v chromium &>/dev/null; then
    log_info "开始安装 Chromium，请耐心等待..."
    if install_package chromium; then
        log_success "Chromium 安装成功"
    else
        log_error "Chromium 安装失败"
        exit 1
    fi
else
    log_success "检测到 Chromium 已安装，跳过安装"
fi

# 启动 Redis
检测redis安装

# 提供安装选项
云崽安装菜单