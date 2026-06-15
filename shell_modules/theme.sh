#!/bin/bash
# 主题与菜单色：统一入口，避免 .init / .color / menu_init 各写一套

XRK_THEMES=(".theme" ".theme2" ".theme3" ".theme4" ".theme5" ".theme6" ".theme7" ".theme8" ".theme9" ".theme10" ".theme11" ".theme12" ".theme13")
XRK_THEME_NAMES=("向日葵原版主题" "暗夜锋芒" "甜心微爱" "极光幻境" "霓虹都市" "薄暮流云" "科技未来" "沙漠晨曦" "深海之谜" "森林密语" "莓果甜心" "星空梦境" "金属光泽")

xrk_load_colors() {
    local root="${XRK_ROOT:-/xrk}"
    [ -n "${color_red:-}" ] && return 0
    [ -f "$root/shell_modules/color.sh" ] || return 1
    # shellcheck source=/dev/null
    source "$root/shell_modules/color.sh"
}

xrk_ensure_menu_colors() {
    xrk_load_colors 2>/dev/null || true
    [ -n "${bg:-}" ] || bg="\033[0m"
    [ -n "${caidan1:-}" ] || caidan1="\033[1;32m"
    [ -n "${caidan2:-}" ] || caidan2="\033[1;36m"
    [ -n "${caidan3:-}" ] || caidan3="\033[0;33m"
    MENU_HINT_EXIT="${caidan3}输入 q 或 0 退出${bg}"
}

xrk_sync_menu_aliases() {
    red="${color_red:-\033[31m}"
    green="${bold_green:-\033[1;32m}"
    yellow="${color_yellow:-\033[33m}"
    bg="${bg:-\033[0m}"
    RED="${RED:-$red}"
    GREEN="${GREEN:-$green}"
    YELLOW="${YELLOW:-$yellow}"
    NC="${NC:-$bg}"
}

# force=1 时无视缓存，重新读取 system.yaml 与主题文件
xrk_load_theme() {
    local force="${1:-0}" root="${XRK_ROOT:-/xrk}" theme theme_file
    xrk_load_colors || true
    theme=".theme"
    [ -f "$root/system.yaml" ] && command -v yq &>/dev/null \
        && theme=$(yq -r '.color // ".theme"' "$root/system.yaml" 2>/dev/null)
    theme="${theme:-.theme}"
    export theme
    if [ "$force" = "1" ] || [ "$theme" != "${XRK_THEME_ACTIVE:-}" ]; then
        theme_file="$root/body/theme/${theme}"
        if [ -f "$theme_file" ]; then
            # shellcheck source=/dev/null
            source "$theme_file"
        fi
        export XRK_THEME_ACTIVE="$theme"
    fi
    xrk_ensure_menu_colors
    xrk_sync_menu_aliases
}

xrk_ensure_system_yaml() {
    local root="${XRK_ROOT:-/xrk}"
    [ -f "$root/system.yaml" ] || echo 'color: .theme' > "$root/system.yaml"
}

xrk_set_theme() {
    local name="$1" root="${XRK_ROOT:-/xrk}"
    [ -f "$root/body/theme/${name}" ] || return 1
    command -v yq &>/dev/null || return 2
    xrk_ensure_system_yaml
    yq -i ".color = \"${name}\"" "$root/system.yaml" 2>/dev/null || return 3
    unset XRK_THEME_ACTIVE
    xrk_load_theme 1
}

xrk_theme_menu_apply() {
    local idx="$1" root="${XRK_ROOT:-/xrk}"
    if ! command -v yq &>/dev/null; then
        echo "未安装 yq，请先菜单安装 yq" >&2
        return 2
    fi
    if [[ ! "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt "${#XRK_THEMES[@]}" ]; then
        return 1
    fi
    xrk_set_theme "${XRK_THEMES[$((idx - 1))]}"
}
