#!/bin/bash
# 安装脚本公共模块：统一远程/本地执行支持、模块加载、路径检测
# 供 NapCat.sh、Lagrange.sh、chromium 等独立安装脚本复用

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

# 统一加载模块：优先本地 /xrk，其次脚本相对路径，最后远程
# 用法：load_install_module "shell_modules/github.sh"
load_install_module() {
    local path="$1"
    local base
    
    # 优先 /xrk（已安装环境）
    [ -f "/xrk/$path" ] && { source "/xrk/$path"; return 0; }
    
    # 其次脚本相对路径（本地仓库执行）
    base="$(_get_script_base)"
    [ -n "$base" ] && [ -f "${base}/$path" ] && { source "${base}/$path"; return 0; }
    
    # 最后远程加载（需要 SCRIPT_RAW_BASE）
    local base_url="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
    if source <(curl -sL --connect-timeout 5 --max-time 30 "${base_url}/$path" 2>/dev/null); then
        return 0
    fi
    
    return 1
}

# 初始化安装脚本环境：加载 github.sh、common.sh、设置 SCRIPT_RAW_BASE
# 用法：init_install_env [源参数]（1=GitCode 2=GitHub 3=Gitee）
init_install_env() {
    local source_arg="${1:-}"
    
    # 加载 bootstrap.sh（提供 get_base_from_arg、init_repo_source）
    load_install_module "shell_modules/bootstrap.sh" 2>/dev/null || {
        # 如果加载失败，直接设置默认值
        SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
    }
    
    # 初始化仓库源（如果 bootstrap 加载成功）
    if type init_repo_source &>/dev/null; then
        init_repo_source "$source_arg"
    elif [ -z "$SCRIPT_RAW_BASE" ]; then
        if type get_base_from_arg &>/dev/null; then
            SCRIPT_RAW_BASE="$(get_base_from_arg "$source_arg")"
        else
            SCRIPT_RAW_BASE="https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master"
        fi
    fi
    export SCRIPT_RAW_BASE
    
    # 加载 github.sh（代理支持）
    load_install_module "shell_modules/github.sh" 2>/dev/null || true
    
    # 加载 common.sh（detect_os、detect_arch、install_pkg）
    load_install_module "shell_modules/common.sh" 2>/dev/null || true
}

# 统一执行安装脚本：优先本地，否则远程
# 用法：run_install_script "Yunzai-install/NapCat.sh" [参数...]
run_install_script() {
    local script_path="$1"
    shift
    local args=("$@")
    
    # 优先本地 /xrk
    if [ -f "/xrk/$script_path" ]; then
        bash "/xrk/$script_path" "${args[@]}"
        return $?
    fi
    
    # 其次脚本相对路径
    local base="$(_get_script_base)"
    if [ -f "${base}/$script_path" ]; then
        bash "${base}/$script_path" "${args[@]}"
        return $?
    fi
    
    # 最后远程执行
    local base_url="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
    bash <(curl -sL "${base_url}/$script_path") "${args[@]}"
}
