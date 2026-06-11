#!/bin/bash
# 写入 .profile（xrk 环境与 puppeteer）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/xrk_boot.sh" ] && source "$root/shell_modules/xrk_boot.sh"
xrk_ensure_bootstrap
xrk_prepare_root
xrk_ensure_repo_file "body/modules/tmux_profile.sh" 2>/dev/null || true

profile="$HOME/.profile"
needed=(
    "[[ -f $XRK_ROOT/.init ]] && source $XRK_ROOT/.init"
    "export PUPPETEER_SKIP_DOWNLOAD='true'"
)
tmux_hook_marker="# xrk: tmux attach-or-restore"
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
