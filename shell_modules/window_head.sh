#!/bin/bash
# tmux 窗格脚本标准头部
# 用法：source "$root/shell_modules/window_head.sh"

root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/xrk_base.sh"
xrk_加载底层 window
menu_init 0 1
