#!/bin/bash
# xm 入口标准头部（/xrk 已安装时使用）
# 用法：source "$XRK_ROOT/shell_modules/xm_head.sh"

XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

# shellcheck source=/dev/null
if [ -f "$XRK_ROOT/shell_modules/xrk_base.sh" ]; then
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
else
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/bootstrap.sh")
fi
xrk_bootstrap "${XRK_SOURCE:-3}" 0

if [ -f "$XRK_ROOT/shell_modules/xrk_base.sh" ]; then
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
    xrk_加载底层 xm
else
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/xrk_base.sh") \
        && xrk_加载底层 xm 2>/dev/null \
        || { load_module "shell_modules/common.sh"; safe_source "shell_modules/menu_common.sh"; }
fi
command -v git &>/dev/null || ensure_cmd git git 2>/dev/null || true
type menu_init &>/dev/null && menu_init 0 0
