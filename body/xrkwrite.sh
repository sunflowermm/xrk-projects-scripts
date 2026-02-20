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

# 主执行：脚本侧（安装器、git/jq、脚本仓库、bin）；环境与云崽由 xm 选项 4 后续调用 linuxinstall 完成
function main() {
    确定系统安装器魔法
    install_package "git"
    install_package "jq"
    install_and_configure_scripts
    双崽linux脚本升级
    echo "[主流程] 脚本与命令已就绪。"
    [ -f "$HOME/.profile" ] && source "$HOME/.profile"
}

main