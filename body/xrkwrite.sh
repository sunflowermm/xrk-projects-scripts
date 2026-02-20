#!/bin/bash

# 切换到用户目录
cd ~ || exit

# 导入函数与变量（已克隆到 XRK_ROOT，直接使用本地）
XRK_ROOT="${XRK_ROOT:-/xrk}"
source "$XRK_ROOT/shell_modules/install.sh"
source "$XRK_ROOT/shell_modules/Yunzai_pieces.sh"
source "$XRK_ROOT/shell_modules/github.sh"
source "$XRK_ROOT/shell_modules/init.sh"
source "$XRK_ROOT/shell_modules/update.sh"


install_and_configure_scripts() {
    安装xrk脚本
    [ -f "$XRK_ROOT/.init" ] && source "$XRK_ROOT/.init"
    葵崽升级
}

main() {
    install_package "git"
    install_package "jq"
    install_and_configure_scripts
    type xrkk同步 &>/dev/null && xrkk同步
    echo "[主流程] 脚本与命令已就绪。"
    [ -f "$HOME/.profile" ] && source "$HOME/.profile"
}

main