#!/bin/bash
# 冷启动：确保 bootstrap 已加载（install / menu_boot 共用）
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
type load_module &>/dev/null && return 0 2>/dev/null || true
root="${XRK_ROOT:-/xrk}"
if [ -f "$root/shell_modules/bootstrap.sh" ]; then
    # shellcheck source=/dev/null
    source "$root/shell_modules/bootstrap.sh"
else
    base="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
    tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-bootstrap.XXXXXX") || exit 1
    curl -fsSL --connect-timeout 10 --max-time 30 "${base}/shell_modules/bootstrap.sh" -o "$tmp" || {
        rm -f "$tmp"
        echo "[xrk] 无法加载 bootstrap: ${base}/shell_modules/bootstrap.sh" >&2
        exit 1
    }
    # shellcheck source=/dev/null
    source "$tmp"
    rm -f "$tmp"
fi
