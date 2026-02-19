#!/bin/bash
# 统一引导：源推导、模块加载、日志（get_base_from_arg、get_clone_from_raw、init_repo_source、load_module、load_distro_deps、log_*）
# 供 install.sh、install_xm、xm、Termux xrk.sh、distro_install_head 等复用

# 从参数推导 SCRIPT_RAW_BASE（1=GitCode 2=GitHub 3=Gitee）
get_base_from_arg() {
    local arg="${1:-$XRK_SOURCE}"
    case "${arg#-}" in
        1) echo "https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master" ;;
        2) echo "https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/master" ;;
        3) echo "https://gitee.com/xrkseek/xrk-projects-scripts/raw/master" ;;
        *) echo "https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master" ;;
    esac
}

# 从 RAW 推导 CLONE
get_clone_from_raw() {
    case "$1" in
        *raw.gitcode.com*) echo "https://gitcode.com/Xrkseek/xrk-projects-scripts.git" ;;
        *raw.githubusercontent.com*) echo "https://github.com/sunflowermm/xrk-projects-scripts.git" ;;
        *gitee.com*) echo "https://gitee.com/xrkseek/xrk-projects-scripts.git" ;;
        *) echo "https://gitcode.com/Xrkseek/xrk-projects-scripts.git" ;;
    esac
}

# 初始化仓库源：优先落盘，否则参数
init_repo_source() {
    local arg="$1"
    [ -f /xrk/.repo_source ] && source /xrk/.repo_source
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    [ -z "$SCRIPT_RAW_BASE" ] && SCRIPT_RAW_BASE="$(get_base_from_arg "$arg")"
    [ -z "$SCRIPT_CLONE_URL" ] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    [[ "$SCRIPT_RAW_BASE" != https://* ]] && SCRIPT_RAW_BASE="$(get_base_from_arg 1)"
    [[ "$SCRIPT_CLONE_URL" != https://* ]] && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
    export SCRIPT_RAW_BASE SCRIPT_CLONE_URL
}

# 加载模块：有 /xrk 用本地，否则 curl（需先 init_repo_source 或设 SCRIPT_RAW_BASE）
load_module() {
    local path="$1"
    if [ -f "/xrk/$path" ]; then
        source "/xrk/$path"
    else
        source <(curl -sL "${SCRIPT_RAW_BASE:-$(get_base_from_arg 1)}/$path")
    fi
}

# 加载主流程依赖（color + Yunzai_pieces + install）
load_distro_deps() {
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg 1)}"
    load_module "shell_modules/color.sh"
    load_module "shell_modules/Yunzai_pieces.sh"
    load_module "shell_modules/install.sh"
}

# 统一日志（依赖 color.sh）
log_info()    { echo -e "${color_light_blue}[信息] $1${reset_color}"; }
log_success() { echo -e "${color_light_green}[成功] $1${reset_color}"; }
log_error()   { echo -e "${color_red}[错误] $1${reset_color}"; }
