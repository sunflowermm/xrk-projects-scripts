#!/bin/bash
# 升级与 bin 同步、葵崽/葵子拉取
[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
XRK_ROOT="${XRK_ROOT:-/xrk}"
XRK_BIN="${XRK_BIN:-/usr/local/bin}"

xrk_bin同步() {
    declare -A files=(
        ["$XRK_BIN/xrkk"]="$XRK_ROOT/body/linux.sh"
        ["$XRK_BIN/xrk"]="$XRK_ROOT/body/xrk"
        ["$XRK_BIN/nt"]="$XRK_ROOT/body/writeto/nt"
        ["$XRK_BIN/xyz"]="$XRK_ROOT/body/writeto/xrk/xyz"
        ["$XRK_BIN/xyzlogin"]="$XRK_ROOT/body/writeto/xrk/xyzlogin"
        ["$XRK_BIN/xag"]="$XRK_ROOT/body/writeto/xrk/xag"
        ["$XRK_BIN/xrk-tmux"]="$XRK_ROOT/body/tmux.sh"
        ["$XRK_BIN/xrk-tmux-setup"]="$XRK_ROOT/body/modules/tmux.sh"
    )
    local dest src n=0 missing=()
    mkdir -p "$XRK_BIN" 2>/dev/null || true
    for dest in "${!files[@]}"; do
        src="${files[$dest]}"
        if [ ! -f "$src" ]; then
            missing+=("$(basename "$dest")")
            continue
        fi
        cat "$src" > "$dest" && chmod 755 "$dest" && n=$((n + 1))
    done
    [ ${#missing[@]} -gt 0 ] && echo "[bin] 跳过（源缺失）: ${missing[*]}" >&2
    if [ "$n" -gt 0 ]; then
        echo "[bin] 已同步 $n 个命令 → $XRK_BIN"
        return 0
    fi
    echo "[bin] 同步失败：无可用源文件" >&2
    return 1
}

xrkk同步() { xrk_bin同步; }

葵崽升级() {
    xrk_bin同步
    safe_source "shell_modules/kuizi_repos.sh"
    type kuizi_upgrade_products &>/dev/null && kuizi_upgrade_products
}

_run_module() {
    [ -f "$XRK_ROOT/$1" ] && bash "$XRK_ROOT/$1"
}

ffmpeg配置检查() {
    if ! type xrk_run_script &>/dev/null; then
        type xrk_source_common &>/dev/null && xrk_source_common || {
            # shellcheck source=/dev/null
            [ -f "$XRK_ROOT/shell_modules/common.sh" ] && source "$XRK_ROOT/shell_modules/common.sh"
        }
    fi
    type xrk_run_script &>/dev/null && xrk_run_script "project-install/software/ffmpeg" \
        || _run_module "project-install/software/ffmpeg"
}

profile配置检查() {
    _run_module "body/modules/profile.sh" || echo "未找到 $XRK_ROOT/body/modules/profile.sh"
}
