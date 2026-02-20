#!/bin/bash
# 引导：源推导、init_repo_source、load_module、load_distro_deps、log_*

[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
_XRK_DEFAULT_BASE="${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"

get_base_from_arg() {
    local arg="${1:-$XRK_SOURCE}"
    case "${arg#-}" in
        1) echo "https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/main" ;;
        2) echo "https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/main" ;;
        3|*) echo "${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}" ;;
    esac
}

get_clone_from_raw() {
    case "$1" in
        *raw.gitcode.com*) echo "https://gitcode.com/Xrkseek/xrk-projects-scripts.git" ;;
        *raw.githubusercontent.com*) echo "https://github.com/sunflowermm/xrk-projects-scripts.git" ;;
        *gitee.com*) echo "https://gitee.com/xrkseek/xrk-projects-scripts.git" ;;
        *) echo "https://gitcode.com/Xrkseek/xrk-projects-scripts.git" ;;
    esac
}

init_repo_source() {
    local arg="$1" root="${XRK_ROOT:-/xrk}"
    [ -f "$root/.repo_source" ] && source "$root/.repo_source"
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    [ -z "$SCRIPT_RAW_BASE" ] && SCRIPT_RAW_BASE="$(get_base_from_arg "$arg")"
    [[ "$SCRIPT_RAW_BASE" != https://* ]] && SCRIPT_RAW_BASE="$(get_base_from_arg 1)"
    [ -z "$SCRIPT_CLONE_URL" ] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    [[ "$SCRIPT_CLONE_URL" != https://* ]] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
}

# 统一加载模块：优先本地，否则远程
load_module() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    [ -f "$root/$path" ] && { source "$root/$path"; return 0; }
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    source <(curl -sL "${SCRIPT_RAW_BASE}/$path" 2>/dev/null) || return 1
}

# 统一 source 模块：优先本地，否则远程（静默失败）
safe_source() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    [ -f "$root/$path" ] && source "$root/$path" && return 0
    local base="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    source <(curl -sL "$base/$path" 2>/dev/null) 2>/dev/null || true
}

load_distro_deps() {
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg 1)}"
    safe_source "shell_modules/color.sh"
    safe_source "shell_modules/Yunzai_pieces.sh"
    safe_source "shell_modules/install.sh"
}

log_info()    { echo -e "${color_light_blue}[信息] $1${reset_color}"; }
log_success() { echo -e "${color_light_green}[成功] $1${reset_color}"; }
log_error()   { echo -e "${color_red}[错误] $1${reset_color}"; }
