#!/bin/bash
# Lagrange.Core 安装脚本（支持远程/本地执行，复用底层 github.sh 代理、common.sh 架构/包管理）

# 统一初始化：加载 install_script_common.sh 并初始化环境
# 支持远程执行：bash <(curl -sL https://raw.gitcode.com/.../Lagrange.sh)
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
if [ -f "/xrk/shell_modules/install_script_common.sh" ]; then
    source /xrk/shell_modules/install_script_common.sh
elif [ -f "$(cd "$(dirname "$0")" && pwd)/../shell_modules/install_script_common.sh" ]; then
    source "$(cd "$(dirname "$0")" && pwd)/../shell_modules/install_script_common.sh"
else
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/install_script_common.sh" 2>/dev/null) || {
        # 如果 install_script_common.sh 不存在，使用简化加载逻辑
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null || echo ".")"
        [ -f "/xrk/shell_modules/github.sh" ] && source /xrk/shell_modules/github.sh || [ -f "${SCRIPT_DIR}/../shell_modules/github.sh" ] && source "${SCRIPT_DIR}/../shell_modules/github.sh" 2>/dev/null || true
        [ -f "/xrk/shell_modules/common.sh" ] && source /xrk/shell_modules/common.sh || [ -f "${SCRIPT_DIR}/../shell_modules/common.sh" ] && source "${SCRIPT_DIR}/../shell_modules/common.sh" 2>/dev/null || true
    }
fi

# 初始化安装环境（如果 install_script_common.sh 加载成功）
type init_install_env &>/dev/null && init_install_env "${XRK_SOURCE:-1}" || true

CYAN='\033[0;1;36;96m'
GREEN='\033[0;1;32;92m'
RED='\033[0;1;31;91m'
NC="${NC:-\033[0m}"

REPO="LagrangeDev/Lagrange.Core"
API_URL="https://api.github.com/repos/${REPO}/releases"
INSTALL_DIR="/root/lagelan"
TARGET_EXECUTABLE="Lagrange.OneBot"

function log() {
    local time msg
    time=$(date +"%Y-%m-%d %H:%M:%S")
    msg="[${time}]: $1"
    case "$1" in
        *"失败"*|*"错误"*|*"无法连接"*) echo -e "${RED}${msg}${NC}" ;;
        *"成功"*) echo -e "${GREEN}${msg}${NC}" ;;
        *) echo -e "${CYAN}${msg}${NC}" ;;
    esac
}

# 架构检测：优先用 common.detect_arch
function get_system_info() {
    if type detect_arch &>/dev/null; then
        case "$(detect_arch)" in
            x64)   system_arch="x64" ;;
            arm64) system_arch="arm64" ;;
            armv7l) system_arch="arm" ;;
            *) log "不支持的系统架构"; exit 1 ;;
        esac
    else
        case "$(uname -m)" in
            x86_64|amd64) system_arch="x64" ;;
            aarch64|arm64) system_arch="arm64" ;;
            armv7l|armhf) system_arch="arm" ;;
            *) log "不支持的系统架构: $(uname -m)"; exit 1 ;;
        esac
    fi
    log "检测到系统架构: ${system_arch}"
    if [ "${system_arch}" = "arm" ]; then
        download_filename="Lagrange.OneBot_linux-arm_net9.0_SelfContained.tar.gz"
    else
        download_filename="Lagrange.OneBot_linux-${system_arch}_net9.0_SelfContained.tar.gz"
    fi
}

function install_dependency() {
    log "安装依赖包..."
    if type install_pkg &>/dev/null; then
        for p in curl jq tar file; do install_pkg "$p" 2>/dev/null || true; done
        return 0
    fi
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq curl jq tar file
    elif command -v dnf &>/dev/null; then
        dnf install -y curl jq tar file
    elif command -v yum &>/dev/null; then
        yum install -y curl jq tar file
    else
        log "未找到支持的包管理器"
        exit 1
    fi
    [ $? -ne 0 ] && { log "依赖包安装失败"; exit 1; }
}

function get_download_url() {
    log "获取最新版本..."
    
    # 默认使用 GitHub 原始 API 地址，代理交给 github.sh 统一处理
    api_url="${API_URL}"
    if [ "${proxy_num}" != "0" ] && command -v getgh >/dev/null 2>&1; then
        getgh api_url
    fi
    
    # 获取原始下载URL
    original_download_url=$(curl -s "${api_url}" | jq -r --arg filename "${download_filename}" '.[0].assets[] | select(.name == $filename) | .browser_download_url')
    
    if [ -z "${original_download_url}" ] || [ "${original_download_url}" = "null" ]; then
        log "未找到安装包: ${download_filename}"
        exit 1
    fi
    # 下载地址同样通过 github.sh 进行代理处理
    download_url="${original_download_url}"
    if [ "${proxy_num}" != "0" ] && command -v getgh >/dev/null 2>&1; then
        getgh download_url
    fi
    
    log "下载地址: ${download_url}"
}

function verify_file() {
    local file_path="$1"
    
    # 检查文件是否存在
    if [ ! -f "${file_path}" ]; then
        log "文件不存在: ${file_path}"
        return 1
    fi
    
    # 检查文件大小
    local file_size=$(stat -c%s "${file_path}" 2>/dev/null || stat -f%z "${file_path}" 2>/dev/null)
    if [ "${file_size}" -eq 0 ]; then
        log "文件大小为0，可能下载失败"
        return 1
    fi
    
    log "文件大小: ${file_size} 字节"
    
    # 检查文件类型
    local file_type=$(file -b "${file_path}")
    log "文件类型: ${file_type}"
    
    # 验证是否为gzip格式
    if ! file "${file_path}" | grep -q "gzip compressed"; then
        log "文件不是有效的gzip格式"
        log "文件内容预览: $(head -3 "${file_path}" 2>/dev/null | tr '\n' ' ')"
        return 1
    fi
    
    return 0
}

function download_and_extract() {
    temp_dir="/tmp/lagrange_$$"
    mkdir -p "${temp_dir}" && cd "${temp_dir}"
    
    log "下载安装包..."
    
    # 添加更多curl选项以提高下载稳定性
    if ! curl -L --progress-bar --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 2 "${download_url}" -o "${download_filename}"; then
        log "下载失败"
        cleanup_and_exit
    fi
    
    # 验证下载的文件
    if ! verify_file "${download_filename}"; then
        log "文件验证失败，尝试重新下载..."
        rm -f "${download_filename}"
        
        # 尝试直连下载（如果之前使用了代理）
        if [ -n "${target_proxy}" ]; then
            log "尝试直连下载..."
            direct_url=$(echo "${download_url}" | sed "s|${target_proxy}/||g")
            if curl -L --progress-bar --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 2 "${direct_url}" -o "${download_filename}"; then
                if verify_file "${download_filename}"; then
                    log "直连下载成功"
                else
                    log "直连下载的文件仍然无效"
                    cleanup_and_exit
                fi
            else
                log "直连下载也失败"
                cleanup_and_exit
            fi
        else
            cleanup_and_exit
        fi
    fi
    
    log "解压安装包..."
    
    # 使用更安全的解压方式
    if ! tar -tzf "${download_filename}" >/dev/null 2>&1; then
        log "tar文件格式验证失败"
        cleanup_and_exit
    fi
    
    if ! tar -xzf "${download_filename}"; then
        log "解压失败，尝试其他解压方式..."
        
        # 尝试分步解压
        if gunzip -t "${download_filename}" 2>/dev/null; then
            if gunzip -c "${download_filename}" | tar -xf -; then
                log "分步解压成功"
            else
                log "分步解压失败"
                cleanup_and_exit
            fi
        else
            log "gzip格式验证失败"
            cleanup_and_exit
        fi
    fi
    
    executable_path=$(find . -name "${TARGET_EXECUTABLE}" -type f | head -1)
    if [ -z "${executable_path}" ]; then
        log "未找到可执行文件"
        log "当前目录内容："
        ls -la
        cleanup_and_exit
    fi
    
    log "找到可执行文件: ${executable_path}"
}

function install_lagrange() {
    log "安装到 ${INSTALL_DIR}..."
    
    mkdir -p "${INSTALL_DIR}"
    cp "${executable_path}" "${INSTALL_DIR}/${TARGET_EXECUTABLE}"
    chmod +x "${INSTALL_DIR}/${TARGET_EXECUTABLE}"
    
    # 复制依赖文件
    executable_dir=$(dirname "${executable_path}")
    for ext in dll so json; do
        find "${executable_dir}" -name "*.${ext}" -exec cp {} "${INSTALL_DIR}/" \; 2>/dev/null
    done
    
    log "安装成功"
    log "可执行文件: ${INSTALL_DIR}/${TARGET_EXECUTABLE}"
}

function cleanup_and_exit() {
    [ -n "${temp_dir}" ] && rm -rf "${temp_dir}"
    exit 1
}

function cleanup() {
    [ -n "${temp_dir}" ] && rm -rf "${temp_dir}"
}

function main() {
    while [[ $# -ge 1 ]]; do
        case $1 in
            --proxy)
                shift; proxy_num="$1"; shift
                ;;
            --force)
                shift; force="y"
                ;;
            --help)
                echo "用法: $0 [--proxy 0-5] [--force] [--help]"
                exit 0
                ;;
            *)
                echo "未知参数: $1"; exit 1
                ;;
        esac
    done

    if [ "$EUID" -ne 0 ]; then
        log "请以root权限运行"
        exit 1
    fi

    if [ -f "${INSTALL_DIR}/${TARGET_EXECUTABLE}" ] && [ "${force}" != "y" ]; then
        log "已安装，使用 --force 重装"
        exit 0
    fi
    
    get_system_info
    install_dependency
    get_download_url
    download_and_extract
    install_lagrange
    cleanup
    
    log "Lagrange.Core 安装完成！"
}

trap cleanup EXIT
main "$@"