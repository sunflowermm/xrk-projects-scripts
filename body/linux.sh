#!/bin/bash
# xrkk：包管理(i/f/mk/list) + 菜单快捷(plugin/js/error/nc 等)。依赖：common → install → init → menu_common → update
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$XRK_ROOT/shell_modules/common.sh" ] && source "$XRK_ROOT/shell_modules/common.sh"
[ -f "$XRK_ROOT/shell_modules/install.sh" ] && source "$XRK_ROOT/shell_modules/install.sh"
[ -f "$XRK_ROOT/shell_modules/init.sh" ] && source "$XRK_ROOT/shell_modules/init.sh"
[ -f "$XRK_ROOT/shell_modules/menu_common.sh" ] && source "$XRK_ROOT/shell_modules/menu_common.sh"
[ -f "$XRK_ROOT/shell_modules/update.sh" ] && source "$XRK_ROOT/shell_modules/update.sh"
menu_init 1 1

SCRIPT_NAME="xrkk"
SCRIPT_VERSION="2.2"

# 包安装：优先 install_package，否则按 detect_os 调用系统包管理器
_do_install() {
    if type install_package &>/dev/null; then
        install_package "$@"
        return
    fi
    type detect_os &>/dev/null || { echo "请先安装脚本仓库到 $XRK_ROOT 或手动安装: $*"; return 1; }
    local os; os=$(detect_os)
    case "$os" in
        debian|ubuntu) apt update -qq; apt install -y "$@" ;;
        arch) pacman -Sy --noconfirm "$@" ;;
        centos) command -v dnf &>/dev/null && dnf install -y "$@" || yum install -y "$@" ;;
        *) echo "请手动安装: $*"; return 1 ;;
    esac
}

# 包卸载
_do_remove() {
    type detect_os &>/dev/null || { echo "请先安装脚本仓库到 $XRK_ROOT 或手动卸载: $*"; return 1; }
    local os; os=$(detect_os)
    case "$os" in
        debian|ubuntu) apt remove -y "$@" ;;
        arch) pacman -R --noconfirm "$@" ;;
        centos) command -v dnf &>/dev/null && dnf remove -y "$@" || yum remove -y "$@" ;;
        *) echo "请手动卸载: $*"; return 1 ;;
    esac
}

# 列出底层常用工具状态（是否已安装及版本）
_do_list() {
    local os; os=$(detect_os 2>/dev/null || echo "unknown")
    echo "系统: $os"
    echo "---"
    for cmd in git node pnpm jq yq ffmpeg tmux; do
        if command -v "$cmd" &>/dev/null; then
            local ver; ver=$("$cmd" --version 2>/dev/null | head -1 || true)
            echo "  $cmd: ${ver:-已安装}"
        else
            echo "  $cmd: 未安装"
        fi
    done
}

show_help() {
    echo "$SCRIPT_NAME $SCRIPT_VERSION"
    echo "用法: $SCRIPT_NAME <子命令> [参数...]"
    echo ""
    echo "软件包:"
    echo "  i <包名>      安装系统包"
    echo "  f <包名>      卸载系统包"
    echo "  mk <目录>     创建目录"
    echo "  list | l     查看底层工具状态"
    echo ""
    echo "菜单快捷:"
    echo "  plugin       插件菜单"
    echo "  other        脚本高级菜单"
    echo "  js           JS 插件菜单"
    echo "  dele         文件管理(文字)"
    echo "  diadele      文件管理(触屏)"
    echo "  up           更新葵崽路径"
    echo "  error        报错修复"
    echo "  nc           安装 NapCat"
    echo ""
    echo "  -h | --help  本帮助"
    echo "当前系统: $(detect_os 2>/dev/null || echo '未知')"
}

[ $# -lt 1 ] && { show_help; exit 1; }

case "$1" in
    -h|--help)
        show_help
        ;;
    i)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定要安装的包名"; exit 1; }
        _do_install "$@"
        ;;
    f)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定要卸载的包名"; exit 1; }
        _do_remove "$@"
        ;;
    mk)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定目录"; exit 1; }
        mkdir -p "$@"
        ;;
    list|l)
        _do_list
        ;;
    plugin)
        bash "$XRK_ROOT/body/menu/plugin.sh"
        ;;
    other)
        bash "$XRK_ROOT/body/menu/advanced.sh"
        ;;
    js)
        bash "$XRK_ROOT/body/menu/js.sh"
        ;;
    dele)
        bash "$XRK_ROOT/body/menu/deletion.sh"
        ;;
    diadele)
        bash "$XRK_ROOT/body/menu/deletiondialog.sh"
        ;;
    up)
        check_changes
        search_directories
        ;;
    error)
        bash "$XRK_ROOT/body/menu/errorbg.sh"
        ;;
    nc|ncqq)
        type run_software &>/dev/null && run_software "project-install/NapCat.sh" || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }
        ;;
    *)
        echo "未知子命令: $1"
        show_help
        exit 1
        ;;
esac
