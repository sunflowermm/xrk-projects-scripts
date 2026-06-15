#!/bin/bash
# 葵崽脚本统一底层：xrk_加载底层 [profile]
# profile: bootstrap common install menu software distro xm xrk deploy window full

[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
XRK_ROOT="${XRK_ROOT:-/xrk}"
XRK_BIN="${XRK_BIN:-/usr/local/bin}"
_XRK_BASE_DEFAULT_RAW="${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"

# 确保 bootstrap 已加载（load_module / xrk_bootstrap / log_*）
_xrk_ensure_bootstrap() {
    type load_module &>/dev/null && return 0
    if [ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ]; then
        # shellcheck source=/dev/null
        source "$XRK_ROOT/shell_modules/bootstrap.sh"
        return 0
    fi
    local base="${SCRIPT_RAW_BASE:-$_XRK_BASE_DEFAULT_RAW}"
    # shellcheck source=/dev/null
    source <(curl -sL --connect-timeout 10 --max-time 30 "${base}/shell_modules/bootstrap.sh")
}

# 确保 common 已加载
_xrk_ensure_common() {
    type detect_os &>/dev/null && return 0
    if type xrk_source_common &>/dev/null; then
        xrk_source_common
        return 0
    fi
    if type load_module &>/dev/null; then
        load_module "shell_modules/common.sh" && return 0
    fi
    if [ -f "$XRK_ROOT/shell_modules/common.sh" ]; then
        # shellcheck source=/dev/null
        source "$XRK_ROOT/shell_modules/common.sh"
        return 0
    fi
    local base="${SCRIPT_RAW_BASE:-$_XRK_BASE_DEFAULT_RAW}"
    # shellcheck source=/dev/null
    source <(curl -sL --connect-timeout 10 --max-time 30 "${base}/shell_modules/common.sh")
}

# 统一加载底层模块（profile 见文件头）
xrk_加载底层() {
    local profile="${1:-common}"

    case "$profile" in
        bootstrap)
            _xrk_ensure_bootstrap
            ;;
        common)
            _xrk_ensure_bootstrap
            _xrk_ensure_common
            ;;
        install)
            xrk_加载底层 common
            load_module "shell_modules/install.sh" 2>/dev/null \
                || safe_source "shell_modules/install.sh"
            ;;
        xm)
            xrk_加载底层 common
            safe_source "shell_modules/menu_common.sh"
            ;;
        xrk)
            _xrk_ensure_bootstrap
            init_repo_source "${XRK_SOURCE:-3}" 0
            export SCRIPT_RAW_BASE SCRIPT_CLONE_URL XRK_SOURCE
            xrk_加载底层 menu
            safe_source "shell_modules/update.sh"
            ;;
        menu)
            xrk_加载底层 common
            safe_source "shell_modules/init.sh"
            safe_source "shell_modules/menu_common.sh"
            ;;
        software)
            xrk_加载底层 common
            type load_install_deps &>/dev/null && load_install_deps
            type xrk_colors &>/dev/null && xrk_colors 2>/dev/null || true
            ;;
        distro)
            _xrk_ensure_bootstrap
            type load_distro_deps &>/dev/null && load_distro_deps
            _xrk_ensure_common
            safe_source "shell_modules/yunzai_distro.sh"
            ;;
        deploy)
            xrk_加载底层 install
            safe_source "shell_modules/Yunzai_pieces.sh"
            safe_source "shell_modules/github.sh"
            safe_source "shell_modules/init.sh"
            safe_source "shell_modules/update.sh"
            ;;
        window)
            _xrk_ensure_bootstrap
            _xrk_ensure_common
            safe_source "shell_modules/init.sh"
            safe_source "shell_modules/github.sh"
            safe_source "shell_modules/menu_common.sh"
            ;;
        full)
            xrk_加载底层 menu
            xrk_加载底层 install
            safe_source "shell_modules/update.sh"
            ;;
        *)
            echo "[xrk_base] 未知 profile: $profile" >&2
            return 1
            ;;
    esac
}

xrk_load_base() { xrk_加载底层 "$@"; }

# [中文 API] 与 common/bootstrap/update 等价，供菜单脚本直接使用
if ! type 检测系统 &>/dev/null; then
    检测系统() { detect_os "$@"; }
    检测架构() { detect_arch "$@"; }
    检测平台() { detect_platform "$@"; }
    安装包() { install_pkg "$@"; }
    批量安装包() { install_pkgs "$@"; }
    卸载包() { remove_pkg "$@"; }
    批量卸载包() { remove_pkgs "$@"; }
    确保命令() { ensure_cmd "$@"; }
    系统更新() { system_update "$@"; }
    执行脚本() { xrk_run_script "$@"; }
    下载文件() { xrk_download "$@"; }
    静默下载() { xrk_download_quiet "$@"; }
    加载公共模块() { xrk_source_common "$@"; }
    初始化软件环境() { xrk_init_software "$@"; }
    日志信息() { log_info "$@"; }
    日志成功() { log_success "$@"; }
    日志错误() { log_error "$@"; }
    安装系统包() {
        type install_package &>/dev/null || xrk_加载底层 install
        install_package "$@"
    }
fi
