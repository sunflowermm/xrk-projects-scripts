#!/bin/bash
# 统一入口：Termux→容器安装 | Linux→xm 安装
# 参数：1=GitCode 2=GitHub 3=Gitee（默认 1）

XRK_SOURCE="${1:-1}"
# 加载 bootstrap 获取 get_base_from_arg（无 /xrk 时用默认 URL）
if [ -f /xrk/shell_modules/bootstrap.sh ]; then
    source /xrk/shell_modules/bootstrap.sh
else
    source <(curl -sL "https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master/shell_modules/bootstrap.sh")
fi
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg "$XRK_SOURCE")}"
SCRIPT_CLONE_URL="${SCRIPT_CLONE_URL:-$(get_clone_from_raw "$SCRIPT_RAW_BASE")}"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL XRK_SOURCE

if [ -n "${TERMUX_VERSION:-}" ]; then
    echo "检测到 Termux，安装 Linux 容器..."
    echo "  1=Ubuntu  2=Debian  3=Alpine  4=Arch  5=Fedora  6=CentOS"
    while true; do
        read -rp "请选择 [1-6]: " choice
        case "$choice" in
            1) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --ubuntu "$XRK_SOURCE" ;;
            2) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --debian "$XRK_SOURCE" ;;
            3) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --alpine "$XRK_SOURCE" ;;
            4) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --arch "$XRK_SOURCE" ;;
            5) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --fedora "$XRK_SOURCE" ;;
            6) exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") --centos "$XRK_SOURCE" ;;
            *) echo "请输入 1-6" ;;
        esac
    done
else
    echo "安装 xm，输入 xm 启动..."
    exec bash <(curl -sL "$SCRIPT_RAW_BASE/install_xm.sh") "$XRK_SOURCE"
fi
