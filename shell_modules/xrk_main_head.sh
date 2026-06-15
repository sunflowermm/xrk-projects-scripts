#!/bin/bash
# 主菜单（body/xrk）标准头部
# 用法：source "$XRK_ROOT/shell_modules/xrk_main_head.sh"

XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$XRK_ROOT/shell_modules/xrk_base.sh"
xrk_加载底层 xrk
menu_init 0 1

重新加载主菜单环境() {
    xrk_加载底层 xrk
    unset XRK_THEME_ACTIVE
    menu_init 0 1
}
