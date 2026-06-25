#!/bin/bash
# 写入 .profile（xrk 环境与 puppeteer）
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -d "$XRK_ROOT" ] || { echo "请先 xm→2 安装本仓库到 $XRK_ROOT"; exit 1; }

profile="$HOME/.profile"
needed=(
    "[[ -f $XRK_ROOT/.init ]] && source $XRK_ROOT/.init"
    "export PUPPETEER_SKIP_DOWNLOAD='true'"
)
tmux_hook_marker="# xrk: tmux wrapper"
tmux_hook_line='[ -f "$XRK_ROOT/body/modules/tmux_profile.sh" ] && . "$XRK_ROOT/body/modules/tmux_profile.sh"'
[ -f "$profile" ] || touch "$profile"
for line in "${needed[@]}"; do
    grep -Fxq "$line" "$profile" || echo "$line" >> "$profile"
done
grep -Fq "$tmux_hook_marker" "$profile" || {
    {
        echo ""
        echo "$tmux_hook_marker"
        echo 'XRK_ROOT="${XRK_ROOT:-/xrk}"'
        echo "$tmux_hook_line"
    } >> "$profile"
}
[ "${XRK_PROFILE_QUIET:-0}" != "1" ] && echo "[profile] 已写入 $profile"
