#!/bin/bash
# xrkk v3：向日葵 CLI — 系统包 / 菜单 / 路径 / bin 同步
XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$XRK_ROOT/shell_modules/xrk_base.sh" || { echo "请先 xm→2 安装脚本仓库到 $XRK_ROOT"; exit 1; }
xrk_加载底层 full
menu_init 1 1
safe_source "shell_modules/kuizi_repos.sh"

XRKK_VERSION="3.0"

_xrkk_sync_bin() {
    safe_source "shell_modules/update.sh"
    if xrk_bin同步; then
        echo "[xrkk] 已同步到 $XRK_BIN: xrk xrkk xyz xyzlogin xag xrk-tmux …"
        return 0
    fi
    echo "[xrkk] bin 同步失败" >&2
    return 1
}

_xrkk_path() {
    check_changes
    search_directories
    echo "葵崽: ${yz:-未探测}"
    echo "葵子: ${agt:-未探测}"
    type kuizi_source_label &>/dev/null && echo "默认源: $(kuizi_source_label)"
}

_xrkk_pkg() {
    case "${1:-}" in
        i|install)
            shift
            [ $# -lt 1 ] && { echo "用法: xrkk pkg install <包名>"; exit 1; }
            install_pkgs "$@"
            ;;
        f|remove|rm)
            shift
            [ $# -lt 1 ] && { echo "用法: xrkk pkg remove <包名>"; exit 1; }
            remove_pkgs "$@"
            ;;
        list|l) _xrkk_pkg_list ;;
        mk)
            shift
            [ $# -lt 1 ] && { echo "用法: xrkk pkg mk <目录>"; exit 1; }
            mkdir -p "$@"
            ;;
        *)
            echo "用法: xrkk pkg install|remove|list|mk …"
            exit 1
            ;;
    esac
}

_xrkk_pkg_list() {
    local os cmd ver
    os=$(detect_os 2>/dev/null || echo "unknown")
    echo "系统: $os"
    echo "---"
    for cmd in git node pnpm jq yq ffmpeg tmux; do
        if command -v "$cmd" &>/dev/null; then
            ver=$("$cmd" --version 2>/dev/null | head -1 || true)
            echo "  $cmd: ${ver:-已安装}"
        else
            echo "  $cmd: 未安装"
        fi
    done
}

_xrkk_menu() {
    case "${1:-}" in
        kuizai|k)    bash "$XRK_ROOT/body/menu/kuizai.sh" ;;
        plugin|p)    bash "$XRK_ROOT/body/menu/plugin.sh" ;;
        js|j)        bash "$XRK_ROOT/body/menu/js.sh" ;;
        advanced|a)  bash "$XRK_ROOT/body/menu/advanced.sh" ;;
        env|e)       bash "$XRK_ROOT/body/modules/env_module.sh" ;;
        error)       bash "$XRK_ROOT/body/menu/errorbg.sh" ;;
        nc|napcat)   run_software "project-install/NapCat.sh" ;;
        xrk)         exec bash "$XRK_ROOT/body/xrk" ;;
        *)
            echo "用法: xrkk menu <kuizai|plugin|js|advanced|env|error|nc|xrk>"
            exit 1
            ;;
    esac
}

_xrkk_help() {
    cat <<EOF
xrkk $XRKK_VERSION — 向日葵命令行

  sync              同步 xrk / xrkk / xyz / xag 等到 $XRK_BIN
  pkg install <包>  安装系统包
  pkg remove <包>   卸载系统包
  pkg list          查看常用工具
  pkg mk <目录>     创建目录
  path              刷新并显示葵崽/葵子路径
  menu <子菜单>     kuizai plugin js advanced env error nc xrk

兼容简写:
  i / f / mk / list / l
  plugin js dele diadele up error nc

  -h, --help        本帮助
EOF
    echo "当前系统: $(detect_os 2>/dev/null || echo '未知')"
}

[ $# -lt 1 ] && { _xrkk_help; exit 0; }

case "$1" in
    -h|--help|help) _xrkk_help ;;
    sync|bin)       _xrkk_sync_bin ;;
    pkg)            shift; _xrkk_pkg "$@" ;;
    path|paths|up)  _xrkk_path ;;
    menu|m)         shift; _xrkk_menu "$@" ;;
    # 兼容 v2 简写
    i)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定要安装的包名"; exit 1; }
        install_pkgs "$@"
        ;;
    f)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定要卸载的包名"; exit 1; }
        remove_pkgs "$@"
        ;;
    mk)
        shift
        [ $# -lt 1 ] && { echo "错误: 请指定目录"; exit 1; }
        mkdir -p "$@"
        ;;
    list|l) _xrkk_pkg_list ;;
    plugin)  bash "$XRK_ROOT/body/menu/plugin.sh" ;;
    other)   bash "$XRK_ROOT/body/menu/advanced.sh" ;;
    js)      bash "$XRK_ROOT/body/menu/js.sh" ;;
    dele)    bash "$XRK_ROOT/body/menu/deletion.sh" ;;
    diadele) bash "$XRK_ROOT/body/menu/deletiondialog.sh" ;;
    error)   bash "$XRK_ROOT/body/menu/errorbg.sh" ;;
    nc|ncqq) run_software "project-install/NapCat.sh" ;;
    *)
        echo "未知子命令: $1"
        _xrkk_help
        exit 1
        ;;
esac
