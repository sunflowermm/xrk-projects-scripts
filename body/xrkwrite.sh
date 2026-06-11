#!/bin/bash

cd ~ || exit

XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$XRK_ROOT/shell_modules/xrk_base.sh"
xrk_加载底层 deploy

install_and_configure_scripts() {
    安装xrk脚本
    [ -f "$XRK_ROOT/.init" ] && source "$XRK_ROOT/.init"
    葵崽升级
}

main() {
    安装系统包 git
    安装系统包 jq
    install_and_configure_scripts
    type xrkk同步 &>/dev/null && xrkk同步
    echo "[主流程] 脚本与命令已就绪。"
    [ -f "$HOME/.profile" ] && source "$HOME/.profile"
}

main
