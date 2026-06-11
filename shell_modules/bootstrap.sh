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
        unset SCRIPT_RAW_BASE SCRIPT_CLONE_URL XRK_SOURCE
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
    [ -n "${XRK_ROOT:-}" ] && export XRK_ROOT
}

# 是否为 xrk-projects-scripts 仓库（避免误把旧 /xrk 目录当成本仓库）
xrk_is_script_repo() {
    [ -f "${1:-${XRK_ROOT:-/xrk}}/shell_modules/bootstrap.sh" ]
}

# 校验 curl 下来的内容像 shell 脚本（避免 HTML / markdown 被 source 后报错）
_xrk_script_body_ok() {
    local f="$1"
    [ -f "$f" ] && [ -s "$f" ] || return 1
    head -1 "$f" | grep -qE '^#!.*(bash|sh)' || return 1
    grep -qE '(^function |[a-zA-Z_][a-zA-Z0-9_]*\(\)|^[[:space:]]*#)' "$f" || return 1
    grep -qiE '^<!DOCTYPE|<html' "$f" && return 1
    return 0
}

# 下载远程脚本到临时文件；成功时 echo 路径（调用方 source/bash 后需 rm）
xrk_fetch_script() {
    local url="$1" tmp
    tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-script.XXXXXX") || return 1
    if ! curl -fsSL --connect-timeout 10 --max-time 60 "$url" -o "$tmp" 2>/dev/null; then
        rm -f "$tmp"
        return 1
    fi
    if ! _xrk_script_body_ok "$tmp"; then
        log_error "远程内容不是有效 shell 脚本: $url"
        rm -f "$tmp"
        return 1
    fi
    echo "$tmp"
}

xrk_source_url() {
    local url="$1" tmp ret=1
    tmp=$(xrk_fetch_script "$url") || return 1
    # shellcheck source=/dev/null
    source "$tmp" && ret=0
    rm -f "$tmp"
    return "$ret"
}

# 统一加载模块：本仓库本地优先，否则远程
load_module() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    if xrk_is_script_repo "$root" && [ -f "$root/$path" ]; then
        # shellcheck source=/dev/null
        source "$root/$path"
        return 0
    fi
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    xrk_source_url "${SCRIPT_RAW_BASE}/$path" || return 1
}

# 统一 source 模块：本仓库本地优先，否则远程（静默失败）
safe_source() {
    local path="$1" root="${XRK_ROOT:-/xrk}"
    if xrk_is_script_repo "$root" && [ -f "$root/$path" ]; then
        # shellcheck source=/dev/null
        source "$root/$path"
        return 0
    fi
    local base="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}"
    xrk_source_url "${base}/$path" 2>/dev/null || true
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

# 确保 bootstrap 与 SCRIPT_RAW_BASE 就绪
xrk_ensure_bootstrap() {
    if type load_module &>/dev/null; then
        [ -n "${SCRIPT_RAW_BASE:-}" ] && return 0
        xrk_bootstrap "${XRK_SOURCE:-3}" 0
        return 0
    fi
    local root="${XRK_ROOT:-/xrk}"
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    if [ -f "$root/shell_modules/bootstrap.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/bootstrap.sh"
    else
        local base="${SCRIPT_RAW_BASE:-$_XRK_DEFAULT_BASE}" tmp
        tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-bootstrap.XXXXXX") || return 1
        curl -fsSL --connect-timeout 10 --max-time 30 "${base}/shell_modules/bootstrap.sh" -o "$tmp" || {
            rm -f "$tmp"
            return 1
        }
        # shellcheck source=/dev/null
        source "$tmp"
        rm -f "$tmp"
    fi
    xrk_bootstrap "${XRK_SOURCE:-3}" 0
}

# 执行仓库内 bash 脚本：本地优先，否则 curl
xrk_exec_script() {
    local path="$1" tmp
    shift
    local root="${XRK_ROOT:-/xrk}"
    xrk_ensure_bootstrap
    if xrk_is_script_repo "$root" && [ -f "$root/$path" ]; then
        bash "$root/$path" "$@"
        return $?
    fi
    tmp=$(xrk_fetch_script "${SCRIPT_RAW_BASE}/$path") || return 1
    bash "$tmp" "$@"
    local ret=$?
    rm -f "$tmp"
    return "$ret"
}

# xm 入口底层
xrk_load_xm() {
    xrk_ensure_bootstrap
    local root="${XRK_ROOT:-/xrk}"
    if [ -f "$root/shell_modules/xrk_base.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/xrk_base.sh"
        xrk_加载底层 xm
    elif load_module "shell_modules/xrk_base.sh" 2>/dev/null; then
        xrk_加载底层 xm 2>/dev/null || true
    fi
    if ! type menu_show &>/dev/null; then
        load_module "shell_modules/common.sh" || true
        safe_source "shell_modules/menu_common.sh"
    fi
    command -v git &>/dev/null || ensure_cmd git git 2>/dev/null || true
    type menu_init &>/dev/null && menu_init 0 0
}

# 菜单脚本标准头部（need_common need_check [附加模块...]）
xrk_load_menu_head() {
    local need_common="${1:-0}" need_check="${2:-0}"
    shift 2 2>/dev/null || true
    local root="${XRK_ROOT:-/xrk}" _extra _path
    xrk_ensure_bootstrap
    if [ -f "$root/shell_modules/xrk_base.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/xrk_base.sh"
        xrk_加载底层 menu
        [ "$need_common" = "1" ] && ! type install_pkg &>/dev/null && xrk_加载底层 install
    elif load_module "shell_modules/xrk_base.sh" 2>/dev/null; then
        xrk_加载底层 menu 2>/dev/null || true
        [ "$need_common" = "1" ] && ! type install_pkg &>/dev/null && xrk_加载底层 install 2>/dev/null || true
    fi
    if ! type menu_show &>/dev/null; then
        load_module "shell_modules/common.sh" || true
        load_module "shell_modules/init.sh" || true
        safe_source "shell_modules/menu_common.sh"
        [ "$need_common" = "1" ] && safe_source "shell_modules/install.sh"
    fi
    for _extra in "$@"; do
        case "$_extra" in
            */*) _path="$_extra" ;;
            *)   _path="shell_modules/$_extra" ;;
        esac
        if [ -f "$root/$_path" ]; then
            # shellcheck source=/dev/null
            source "$root/$_path"
        else
            load_module "$_path" 2>/dev/null || safe_source "$_path"
        fi
    done
    menu_init "$need_common" "$need_check"
}

# 本地 menu_head 或远程 xrk_load_menu_head
xrk_source_menu_head() {
    local root="${XRK_ROOT:-/xrk}"
    if [ -f "$root/shell_modules/menu_head.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/menu_head.sh" "$@"
    else
        xrk_load_menu_head "$@"
    fi
}
