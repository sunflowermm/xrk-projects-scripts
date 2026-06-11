#!/bin/bash
# Copyright (c) 2026 Xrkseek
# Licensed under MIT License
# 安装脚本公共模块：统一远程/本地执行、模块加载
# 供 NapCat.sh、chromium 等独立安装脚本复用

# 检测是否远程执行（curl | bash / process substitution）
_是否远程执行() {
    if [ "$0" = "-" ] || [ "$0" = "bash" ] || [[ "$0" == /dev/fd/* ]]; then
        return 0
    fi
    [ ! -f "$0" ] && return 0
    [ "${BASH_SOURCE[0]:-$0}" != "$0" ] && [[ "${BASH_SOURCE[0]:-$0}" == /dev/fd/* ]] && return 0
    return 1
}
_is_remote_exec() { _是否远程执行 "$@"; }

# 脚本仓库根（本地执行时）
_脚本仓库根() {
    if _是否远程执行; then
        echo ""
        return 0
    fi
    local script_path="${BASH_SOURCE[0]:-$0}" dir
    if [ -f "$script_path" ]; then
        dir="$(cd "$(dirname "$script_path")" && pwd)"
        echo "${dir}/.."
    fi
}
_get_script_base() { _脚本仓库根 "$@"; }

# 统一加载模块：委托 bootstrap.load_module，否则本地/远程兜底
load_install_module() {
    local path="$1" root="${XRK_ROOT:-/xrk}" base base_url

    if ! type load_module &>/dev/null; then
        if [ -f "$root/shell_modules/bootstrap.sh" ]; then
            # shellcheck source=/dev/null
            source "$root/shell_modules/bootstrap.sh"
        else
            base_url="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
            # shellcheck source=/dev/null
            source <(curl -sL --connect-timeout 5 --max-time 30 "${base_url}/shell_modules/bootstrap.sh" 2>/dev/null) || true
        fi
    fi
    if type load_module &>/dev/null; then
        load_module "$path" && return 0
    fi
    if type safe_source &>/dev/null; then
        safe_source "$path" && return 0
    fi
    [ -f "$root/$path" ] && { source "$root/$path"; return 0; }
    base="$(_脚本仓库根)"
    [ -n "$base" ] && [ -f "${base}/$path" ] && { source "${base}/$path"; return 0; }
    base_url="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    # shellcheck source=/dev/null
    source <(curl -sL --connect-timeout 5 --max-time 30 "${base_url}/$path" 2>/dev/null) && return 0
    return 1
}

# 初始化安装脚本环境
init_install_env() {
    local source_arg="${1:-${XRK_SOURCE:-3}}" force=0
    [ -n "${1:-}" ] && force=1

    load_install_module "shell_modules/bootstrap.sh" 2>/dev/null || true
    if type xrk_bootstrap &>/dev/null; then
        xrk_bootstrap "$source_arg" "$force"
    else
        type init_repo_source &>/dev/null && init_repo_source "$source_arg" "$force"
        SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
        export SCRIPT_RAW_BASE
    fi

    load_install_module "shell_modules/common.sh" 2>/dev/null || true
    type xrk_init_software &>/dev/null && xrk_init_software \
        || load_install_module "shell_modules/github.sh" 2>/dev/null || true
}

# 统一执行安装脚本（委托 xrk_run_script）
run_install_script() {
    type xrk_run_script &>/dev/null || load_install_module "shell_modules/common.sh" 2>/dev/null || true
    xrk_run_script "$@"
}

初始化安装环境() { init_install_env "$@"; }
执行安装脚本() { run_install_script "$@"; }
