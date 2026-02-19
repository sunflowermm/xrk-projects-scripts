#!/bin/bash
# 主流程入口：按 detect_os 分发到各发行版安装脚本，支持全 Linux + 多架构

SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
export SCRIPT_RAW_BASE

_run_install() {
    local script="$1"
    if [ -f "/xrk/$script" ]; then
        bash "/xrk/$script"
    else
        bash <(curl -sL "$SCRIPT_RAW_BASE/$script")
    fi
}

# 使用 common 的 detect_os（需先加载）
[ -f /xrk/shell_modules/common.sh ] && source /xrk/shell_modules/common.sh || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")

os=$(detect_os)
case "$os" in
    ubuntu)     _run_install "Yunzai-install/ubuntuinstall.sh" ;;
    debian)     _run_install "Yunzai-install/debianinstall.sh" ;;
    arch)       _run_install "Yunzai-install/archinstall.sh" ;;
    centos)     _run_install "Yunzai-install/centosinstall.sh" ;;
    opensuse)   _run_install "Yunzai-install/opensuseinstall.sh" ;;
    alpine)     _run_install "Yunzai-install/alpineinstall.sh" ;;
    void)       _run_install "Yunzai-install/genericinstall.sh" ;;
    gentoo)     _run_install "Yunzai-install/genericinstall.sh" ;;
    *)
        echo "未显式支持的发行版: $os"
        echo "尝试通用安装流程..."
        _run_install "Yunzai-install/genericinstall.sh"
        ;;
esac
