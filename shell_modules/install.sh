#!/bin/bash
# 主流程用：加载公共模块 + 确定系统类型，对外提供 install_package（统一走 common.sh install_pkg）

SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"

# 加载公共模块（本地优先，否则远程）
if [ -f /xrk/shell_modules/common.sh ]; then
    # shellcheck source=/dev/null
    source /xrk/shell_modules/common.sh
else
    # shellcheck source=/dev/null
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
fi

# 确定系统安装器：仅设置 OS_TYPE，实际安装统一用 install_pkg
function 确定系统安装器魔法() {
    export OS_TYPE
    OS_TYPE=$(detect_os)
}

# 对外接口：与原有 install_package 一致，内部走 common 的 install_pkg
function install_package() {
    install_pkg "$1"
}
