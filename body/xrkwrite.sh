#!/bin/bash

# 切换到用户目录
cd ~ || exit

# 导入函数与变量（已克隆到 /xrk，直接使用本地）
source /xrk/shell_modules/install.sh
source /xrk/shell_modules/Yunzai_pieces.sh
source /xrk/shell_modules/github.sh
source /xrk/shell_modules/init.sh
source /xrk/shell_modules/update.sh


# 安装和配置自定义脚本
function install_and_configure_scripts() {
    安装xrk脚本
    source /xrk/.init
    葵崽升级
}

# 主执行函数（仅核心：安装器、git/jq、脚本仓库、葵崽升级、xrkk；tmux/ffmpeg/profile 为独立模块，从菜单安装）
function main() {
    确定系统安装器魔法
    install_package "git"
    install_package "jq"
    install_and_configure_scripts
    双崽linux脚本升级
    echo "主流程安装完成。tmux/ffmpeg/profile 可从主菜单「环境与模块」或 xm 中单独安装。"
    [ -f "$HOME/.profile" ] && source "$HOME/.profile"
}

main