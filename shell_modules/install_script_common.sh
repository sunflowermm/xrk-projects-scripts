#!/bin/bash
# Copyright (c) 2026 Xrkseek
# Licensed under MIT License
# 安装脚本公共模块：统一远程/本地执行支持、模块加载、路径检测
# 供 NapCat.sh、chromium 等独立安装脚本复用

# 检测是否远程执行（通过 $0 和 BASH_SOURCE 判断）
_is_remote_exec() {
    # 检查 $0：远程执行时可能是 "-", "bash", "/dev/fd/N" 或不存在
    if [ "$0" = "-" ] || [ "$0" = "bash" ] || [[ "$0" == /dev/fd/* ]]; then
        return 0
    fi
    # 检查文件是否存在且可读
    [ ! -f "$0" ] && return 0
    # 检查 BASH_SOURCE（更可靠）
    [ "${BASH_SOURCE[0]:-$0}" != "$0" ] && [[ "${BASH_SOURCE[0]:-$0}" == /dev/fd/* ]] && return 0
    return 1
}

# 获取脚本基础路径（支持远程和本地）
_get_script_base() {
    if _is_remote_exec; then
        # 远程执行：返回空（使用远程加载）
        echo ""
    else
        # 本地执行：使用脚本所在目录
        local script_path="${BASH_SOURCE[0]:-$0}"
        if [ -f "$script_path" ]; then
            SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"
            echo "${SCRIPT_DIR}/.."
        else
            echo ""
        fi
    fi
}

# 统一加载模块：优先本地 XRK_ROOT，其次脚本相对路径，最后远程
# 用法：load_install_module "shell_modules/github.sh"
load_install_module() {
    local path="$1" root="${XRK_ROOT:-/xrk}" base
    [ -f "$root/$path" ] && { source "$root/$path"; return 0; }
    base="$(_get_script_base)"
    [ -n "$base" ] && [ -f "${base}/$path" ] && { source "${base}/$path"; return 0; }
    local base_url="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    source <(curl -sL --connect-timeout 5 --max-time 30 "${base_url}/$path" 2>/dev/null) && return 0
    return 1
}

# 初始化安装脚本环境：加载 github.sh、common.sh、设置 SCRIPT_RAW_BASE
# 用法：init_install_env [源参数]（1=GitCode 2=GitHub 3=Gitee）
init_install_env() {
    local source_arg="${1:-}"
    
    _DEFAULT_RAW="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master"
    load_install_module "shell_modules/bootstrap.sh" 2>/dev/null || true
    type init_repo_source &>/dev/null && init_repo_source "$source_arg"
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$_DEFAULT_RAW}"
    export SCRIPT_RAW_BASE
    
    # 加载 github.sh（代理支持）
    load_install_module "shell_modules/github.sh" 2>/dev/null || true
    
    # 加载 common.sh（detect_os、detect_arch、install_pkg）
    load_install_module "shell_modules/common.sh" 2>/dev/null || true
}

# 统一执行安装脚本：优先本地，否则远程
# 用法：run_install_script "project-install/NapCat.sh" [参数...]
run_install_script() {
    local script_path="$1" root="${XRK_ROOT:-/xrk}"
    shift
    local args=("$@")
    [ -f "$root/$script_path" ] && { bash "$root/$script_path" "${args[@]}"; return $?; }
    local base="$(_get_script_base)"
    [ -f "${base}/$script_path" ] && { bash "${base}/$script_path" "${args[@]}"; return $?; }
    local base_url="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    bash <(curl -sL "${base_url}/$script_path") "${args[@]}"
}
