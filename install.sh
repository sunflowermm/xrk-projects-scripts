#!/bin/bash
# 统一入口：Termux→容器安装 | Linux→xm 安装
# 参数：1=GitCode 2=GitHub 3=Gitee（默认 3）

XRK_SOURCE="${1:-3}"
XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
if [ -f "$XRK_ROOT/shell_modules/xrk_boot.sh" ]; then
    source "$XRK_ROOT/shell_modules/xrk_boot.sh"
elif [ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ]; then
    source "$XRK_ROOT/shell_modules/bootstrap.sh"
else
    tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-bootstrap.XXXXXX") || exit 1
    curl -fsSL --connect-timeout 10 --max-time 30 \
        "https://gitee.com/xrkseek/xrk-projects-scripts/raw/master/shell_modules/bootstrap.sh" \
        -o "$tmp" || { rm -f "$tmp"; echo "bootstrap 下载失败"; exit 1; }
    source "$tmp"
    rm -f "$tmp"
fi
xrk_bootstrap "$XRK_SOURCE" 1

if [ -n "${TERMUX_VERSION:-}" ]; then
    _termux_dists=(ubuntu debian alpine arch fedora centos)
    echo "检测到 Termux，安装 Linux 容器..."
    echo "  1=Ubuntu  2=Debian  3=Alpine  4=Arch  5=Fedora  6=CentOS"
    while true; do
        read -rp "请选择 [1-6]: " choice
        if [[ "$choice" =~ ^[1-6]$ ]]; then
            exec bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/xrk.sh") "--${_termux_dists[$((choice-1))]}" "$XRK_SOURCE"
        fi
        echo "请输入 1-6"
    done
else
    echo "安装 xm，输入 xm 启动..."
    exec bash <(curl -sL "$SCRIPT_RAW_BASE/install_xm.sh") "$XRK_SOURCE"
fi
