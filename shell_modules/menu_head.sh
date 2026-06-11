#!/bin/bash
# 菜单脚本标准头部：xrk_base + 可选附加模块 + menu_init
# 用法：source "$root/shell_modules/menu_head.sh" <need_common:0|1> <need_check:0|1> [附加模块...]

root="${XRK_ROOT:-/xrk}"
_xrk_menu_need_common="${1:-0}"
_xrk_menu_need_check="${2:-0}"
shift 2 2>/dev/null || true

if [ -f "$root/shell_modules/xrk_base.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/shell_modules/xrk_base.sh"
    xrk_加载底层 menu
    [ "$_xrk_menu_need_common" = "1" ] && ! type install_pkg &>/dev/null && xrk_加载底层 install
else
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
    # shellcheck source=/dev/null
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/bootstrap.sh")
    xrk_bootstrap
    load_module "shell_modules/common.sh"
    load_module "shell_modules/init.sh"
    safe_source "shell_modules/menu_common.sh"
    [ "$_xrk_menu_need_common" = "1" ] && safe_source "shell_modules/install.sh"
fi

for _xrk_menu_extra in "$@"; do
    case "$_xrk_menu_extra" in
        */*) _xrk_menu_path="$_xrk_menu_extra" ;;
        *)   _xrk_menu_path="shell_modules/$_xrk_menu_extra" ;;
    esac
    if [ -f "$root/$_xrk_menu_path" ]; then
        # shellcheck source=/dev/null
        source "$root/$_xrk_menu_path"
    elif type safe_source &>/dev/null; then
        safe_source "$_xrk_menu_path"
    fi
done
unset _xrk_menu_extra _xrk_menu_path

menu_init "$_xrk_menu_need_common" "$_xrk_menu_need_check"
unset _xrk_menu_need_common _xrk_menu_need_check
