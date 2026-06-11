#!/bin/bash
# xrkk：包管理 + 菜单快捷
XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$XRK_ROOT/shell_modules/xrk_base.sh" || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }
xrk_加载底层 full
menu_init 1 1

SCRIPT_NAME="xrkk"
SCRIPT_VERSION="2.2"

_do_install() { install_pkgs "$@"; }
_do_remove() { remove_pkgs "$@"; }

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
    -h|--help) show_help ;;
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
    list|l) _do_list ;;
    plugin)  bash "$XRK_ROOT/body/menu/plugin.sh" ;;
    other)   bash "$XRK_ROOT/body/menu/advanced.sh" ;;
    js)      bash "$XRK_ROOT/body/menu/js.sh" ;;
    dele)    bash "$XRK_ROOT/body/menu/deletion.sh" ;;
    diadele) bash "$XRK_ROOT/body/menu/deletiondialog.sh" ;;
    up)      check_changes; search_directories ;;
    error)   bash "$XRK_ROOT/body/menu/errorbg.sh" ;;
    nc|ncqq) run_software "project-install/NapCat.sh" ;;
    *)
        echo "未知子命令: $1"
        show_help
        exit 1
        ;;
esac
