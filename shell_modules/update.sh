#!/bin/bash
# 升级与配置检查：bin 同步、xrkk、tmux/ffmpeg/profile 模块
[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
XRK_ROOT="${XRK_ROOT:-/xrk}"
XRK_BIN="${XRK_BIN:-/usr/local/bin}"

葵崽升级() {
    declare -A files=(
        ["$XRK_BIN/nt"]="$XRK_ROOT/body/writeto/nt"
        ["$XRK_BIN/xyz"]="$XRK_ROOT/body/writeto/xrk/xyz"
        ["$XRK_BIN/xyzlogin"]="$XRK_ROOT/body/writeto/xrk/xyzlogin"
        ["$XRK_BIN/xrk"]="$XRK_ROOT/body/xrk"
        ["$XRK_BIN/xrk-tmux"]="$XRK_ROOT/body/modules/tmux.sh"
    )
    for dest in "${!files[@]}"; do
        [ -f "${files[$dest]}" ] && cat "${files[$dest]}" > "$dest" && chmod 755 "$dest"
    done
    [ -n "${xyz:-}" ] && [ -d "$xyz" ] && (cd "$xyz" && git pull)
}

xrkk同步() {
    [ -f "$XRK_ROOT/body/linux.sh" ] && cat "$XRK_ROOT/body/linux.sh" > "$XRK_BIN/xrkk" && chmod 755 "$XRK_BIN/xrkk"
}

_run_module() {
    [ -f "$XRK_ROOT/$1" ] && bash "$XRK_ROOT/$1"
}

tmux配置检查() {
    _run_module "body/modules/tmux.sh" || echo "未找到 $XRK_ROOT/body/modules/tmux.sh"
}

ffmpeg配置检查() {
    type run_software &>/dev/null && { run_software "body/modules/ffmpeg.sh" || run_software "project-install/software/ffmpeg"; return; }
    _run_module "body/modules/ffmpeg.sh" || _run_module "project-install/software/ffmpeg"
}

profile配置检查() {
    _run_module "body/modules/profile.sh" || echo "未找到 $XRK_ROOT/body/modules/profile.sh"
}