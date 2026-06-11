#!/bin/bash
# 引导：源推导、init_repo_source、load_module、load_distro_deps、log_*

[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
_XRK_DEFAULT_BASE="${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"

# 检测是否在国内：唯一依据 countryCode == CN（中国大陆）
# 支持覆盖：XRK_REGION=cn|overseas（用于测试/特殊网络）
detect_region() {
    local json country

    case "${XRK_REGION:-}" in
        cn|overseas) echo "$XRK_REGION"; return 0 ;;
    esac

    # 唯一依据：countryCode == CN
    json=$(curl -s --connect-timeout 3 --max-time 5 "http://ip-api.com/json" 2>/dev/null || true)
    country=$(printf '%s' "$json" | grep -oE '"countryCode":"[^"]*"' | cut -d'"' -f4)
    [ "$country" = "CN" ] && { echo "cn"; return 0; }
    echo "overseas"
}

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
        *) echo "https://gitee.com/xrkseek/xrk-projects-scripts.git" ;;
    esac
}

init_repo_source() {
    local arg="$1" force="${2:-0}" root="${XRK_ROOT:-/xrk}"

    if [ "$force" = "1" ]; then
        unset SCRIPT_RAW_BASE SCRIPT_CLONE_URL
    else
        [ -f "$root/.repo_source" ] && source "$root/.repo_source"
        [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    fi
    # 未指定源时：统一优先 Gitee（3）
    [ -z "$arg" ] && arg="3"
    [ -z "$SCRIPT_RAW_BASE" ] && SCRIPT_RAW_BASE="$(get_base_from_arg "$arg")"
    [[ "$SCRIPT_RAW_BASE" != https://* ]] && SCRIPT_RAW_BASE="$(get_base_from_arg 3)"
    [ -z "$SCRIPT_CLONE_URL" ] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    [[ "$SCRIPT_CLONE_URL" != https://* ]] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
}

# 统一加载模块：优先本地，否则远程
load_module() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    if [ -f "$root/$path" ]; then
        # shellcheck source=/dev/null
        source "$root/$path"
        return 0
    fi
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    # shellcheck source=/dev/null
    source <(curl -sL --connect-timeout 10 --max-time 30 "${SCRIPT_RAW_BASE}/$path" 2>/dev/null) || return 1
}

# 统一 source 模块：优先本地，否则远程（静默失败）
safe_source() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    [ -f "$root/$path" ] && source "$root/$path" && return 0
    local base="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    source <(curl -sL "$base/$path" 2>/dev/null) 2>/dev/null || true
}

load_distro_deps() {
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg 3)}"
    safe_source "shell_modules/color.sh"
    safe_source "shell_modules/Yunzai_pieces.sh"
    safe_source "shell_modules/install.sh"
}

_log_color() {
    local name="$1" fallback="$2"
    local v="${!name:-}"
    [ -n "$v" ] && echo "$v" || echo "$fallback"
}

log_info()    { echo -e "$(_log_color color_light_blue '\033[1;36m')[信息] $1$(_log_color reset_color '\033[0m')"; }
log_success() { echo -e "$(_log_color color_light_green '\033[1;92m')[成功] $1$(_log_color reset_color '\033[0m')"; }
log_error()   { echo -e "$(_log_color color_red '\033[31m')[错误] $1$(_log_color reset_color '\033[0m')"; }

# 统一首跳引导：加载 bootstrap 并初始化脚本源（替代各入口重复的 case/source 块）
# 用法：xrk_bootstrap [源: 1=GitCode 2=GitHub 3=Gitee] [force: 0|1]
# 显式传入源时默认 force=1，避免 ~/.xrk_repo 覆盖用户选择的镜像
xrk_bootstrap() {
    local source_arg="${1:-${XRK_SOURCE:-3}}"
    local force="${2:-}"
    local root="${XRK_ROOT:-/xrk}"

    if ! type get_base_from_arg &>/dev/null; then
        if [ -f "$root/shell_modules/bootstrap.sh" ]; then
            # shellcheck source=/dev/null
            source "$root/shell_modules/bootstrap.sh"
        else
            local boot_base
            case "${source_arg#-}" in
                1) boot_base="https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/main" ;;
                2) boot_base="https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/main" ;;
                3|*) boot_base="${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}" ;;
            esac
            source <(curl -sL "${boot_base}/shell_modules/bootstrap.sh")
        fi
    fi

    [ -z "$force" ] && { [ -n "${1:-}" ] && force=1 || force=0; }
    XRK_SOURCE="$source_arg"
    init_repo_source "$source_arg" "$force"
    export SCRIPT_RAW_BASE SCRIPT_CLONE_URL XRK_SOURCE
}
