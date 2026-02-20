#!/bin/bash
# 公共模块：detect_arch/platform/os、install_pkg、ensure_cmd、换源（Termux 见 Termux.sh）
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"

detect_arch() {
    local m; m=$(uname -m)
    case "$m" in
        x86_64|amd64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf) echo "armv7l" ;;
        ppc64le) echo "ppc64le" ;;
        s390x) echo "s390x" ;;
        i386|i686) echo "x86" ;;
        *) echo "$m" ;;
    esac
}

detect_arch_raw() { uname -m; }

detect_platform() {
    case "$(uname -s)" in
        Linux) echo "linux" ;;
        Darwin) echo "macos" ;;
        *) echo "unknown" ;;
    esac
}

detect_os() {
    if [ -n "${TERMUX_VERSION:-}" ] && [ -n "${PREFIX:-}" ]; then
        echo "termux"
        return
    fi
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            ubuntu) echo "ubuntu" ;;
            debian) echo "debian" ;;
            arch|archarm|archlinuxarm|manjaro) echo "arch" ;;
            centos|rhel|fedora|rocky|almalinux) echo "centos" ;;
            opensuse*|sles) echo "opensuse" ;;
            alpine) echo "alpine" ;;
            void) echo "void" ;;
            gentoo) echo "gentoo" ;;
            *) echo "${ID:-unknown}" ;;
        esac
    else
        echo "unknown"
    fi
}

_is_pkg_installed() {
    local pkg="$1"
    local os="${2:-$(detect_os)}"
    case "$os" in
        termux)   pkg list-installed 2>/dev/null | grep -q "^${pkg}/" ;;
        debian|ubuntu) dpkg -s "$pkg" >/dev/null 2>&1 ;;
        arch)     pacman -Qi "$pkg" >/dev/null 2>&1 ;;
        centos)   rpm -q "$pkg" >/dev/null 2>&1 ;;
        opensuse) rpm -q "$pkg" >/dev/null 2>&1 ;;
        alpine)   apk info -e "$pkg" >/dev/null 2>&1 ;;
        void)     xbps-query -S "$pkg" 2>/dev/null | grep -q "^ii" ;;
        gentoo)   qlist -I 2>/dev/null | grep -qE "/${pkg}$" ;;
        *)       return 1 ;;
    esac
}

_INSTALL_MAX_RETRIES=3

_install_success() {
    local pkg="$1"
    echo -e "\033[0;32m$pkg 安装成功\033[0m"
    return 0
}

install_pkg() {
    local pkg="$1" os retry=0
    [ -z "$pkg" ] && return 1
    os=$(detect_os)
    _is_pkg_installed "$pkg" "$os" && echo -e "\033[0;32m$pkg 已安装，无需重复安装\033[0m" && return 0
    while [ "$retry" -lt "$_INSTALL_MAX_RETRIES" ]; do
        echo -e "\033[0;34m正在安装 $pkg...\033[0m"
        case "$os" in
            termux) pkg install -y "$pkg" && _install_success "$pkg" && return 0 ;;
            debian|ubuntu) apt-get update -qq && apt-get install -y "$pkg" && _install_success "$pkg" && return 0 ;;
            arch) pacman --disable-sandbox -Sy --noconfirm "$pkg" && _install_success "$pkg" && return 0 ;;
            centos) (command -v dnf &>/dev/null && dnf install -y "$pkg" || yum install -y "$pkg") && _install_success "$pkg" && return 0 ;;
            opensuse) zypper -n install "$pkg" && _install_success "$pkg" && return 0 ;;
            alpine) apk add --no-cache "$pkg" && _install_success "$pkg" && return 0 ;;
            void) xbps-install -Sy "$pkg" && _install_success "$pkg" && return 0 ;;
            gentoo) emerge -q "$pkg" && _install_success "$pkg" && return 0 ;;
            *) echo -e "\033[0;31m无法识别的系统类型($os)，请手动安装 $pkg\033[0m"; return 1 ;;
        esac
        retry=$((retry + 1))
        echo -e "\033[0;33m重试安装 $pkg ($retry/$_INSTALL_MAX_RETRIES)...\033[0m"
    done
    echo -e "\033[0;31m$pkg 安装失败次数达到上限\033[0m"
    return 1
}

ensure_cmd() {
    local cmd="$1" pkg="${2:-$cmd}"
    [ -z "$cmd" ] && return 1
    command -v "$cmd" &>/dev/null && return 0
    install_pkg "$pkg"
}

_xrk_is_tty() { [ -t 1 ] && [ -n "${TERM:-}" ]; }
_xrk_has() { command -v "$1" >/dev/null 2>&1; }

_xrk_c_blue='\033[0;34m'
_xrk_c_green='\033[0;32m'
_xrk_c_yellow='\033[0;33m'
_xrk_c_red='\033[0;31m'
_xrk_c_nc='\033[0m'

_xrk_msg() {
    local tag="$1"; shift
    if _xrk_is_tty; then
        case "$tag" in
            info) echo -e "${_xrk_c_blue}[下载]${_xrk_c_nc} $*" ;;
            ok)   echo -e "${_xrk_c_green}[完成]${_xrk_c_nc} $*" ;;
            warn) echo -e "${_xrk_c_yellow}[重试]${_xrk_c_nc} $*" ;;
            err)  echo -e "${_xrk_c_red}[失败]${_xrk_c_nc} $*" ;;
            *)    echo "$*" ;;
        esac
    else
        case "$tag" in
            info) echo "[download] $*" ;;
            ok)   echo "[done] $*" ;;
            warn) echo "[retry] $*" ;;
            err)  echo "[error] $*" ;;
            *)    echo "$*" ;;
        esac
    fi
}

_xrk_prepare_downloader() {
    # 优先 curl，其次 wget；只安装“至少一个”即可，避免重复冗余安装
    _xrk_has curl && return 0
    _xrk_has wget && return 0
    ensure_cmd curl curl 2>/dev/null || true
    _xrk_has curl && return 0
    ensure_cmd wget wget 2>/dev/null || true
    _xrk_has wget && return 0
    return 1
}

_xrk_apply_getgh_if_possible() {
    # 内置 GitHub 加速：有 getgh 就用（避免脚本里重复 getgh）
    local __var="$1"
    type getgh >/dev/null 2>&1 || return 0
    getgh "$__var" 2>/dev/null || true
}

_xrk_download_once() {
    local url="$1" out="$2"
    if _xrk_has curl; then
        if [ "${XRK_DL_QUIET:-0}" = "1" ] || ! _xrk_is_tty; then
            curl -fsSL --connect-timeout 10 --max-time 300 -o "$out" "$url" 2>/dev/null
        else
            curl -fL --progress-bar --connect-timeout 10 --max-time 300 -o "$out" "$url"
        fi
        return $?
    fi
    if _xrk_has wget; then
        if [ "${XRK_DL_QUIET:-0}" = "1" ] || ! _xrk_is_tty; then
            wget -q --tries=3 --timeout=30 -O "$out" "$url" 2>/dev/null
        else
            wget --tries=3 --timeout=30 --show-progress -O "$out" "$url"
        fi
        return $?
    fi
    return 127
}

# 统一下载：自动加速(getgh)、统一输出/进度、临时文件落盘、失败重试
# 用法：xrk_download <url> <out> [tries]
xrk_download() {
    local url="$1" out="$2" tries="${3:-3}" i tmp dir name size
    [ -z "$url" ] || [ -z "$out" ] && return 1
    _xrk_prepare_downloader || { _xrk_msg err "缺少 curl/wget，且自动安装失败"; return 1; }

    dir=$(dirname "$out")
    [ -n "$dir" ] && [ "$dir" != "." ] && mkdir -p "$dir" 2>/dev/null || true

    name=$(basename "$out")
    tmp="${out}.tmp.$$"

    local _url="$url"
    _xrk_apply_getgh_if_possible _url

    [ "${XRK_DL_QUIET:-0}" = "1" ] || _xrk_msg info "$name"
    for ((i=1; i<=tries; i++)); do
        rm -f "$tmp" 2>/dev/null || true
        if _xrk_download_once "$_url" "$tmp"; then
            mv -f "$tmp" "$out" 2>/dev/null || { rm -f "$tmp" 2>/dev/null || true; return 1; }
            if [ "${XRK_DL_QUIET:-0}" != "1" ]; then
                size=$(wc -c <"$out" 2>/dev/null | tr -d ' ')
                [ -n "$size" ] && _xrk_msg ok "$name (${size}B)" || _xrk_msg ok "$name"
            fi
            return 0
        fi
        [ "$i" -lt "$tries" ] && { [ "${XRK_DL_QUIET:-0}" = "1" ] || _xrk_msg warn "$name ($i/$tries)"; sleep 1; }
    done
    rm -f "$tmp" 2>/dev/null || true
    [ "${XRK_DL_QUIET:-0}" = "1" ] || _xrk_msg err "$name"
    return 1
}

# 静默下载（适配后台任务/自定义进度条）
xrk_download_quiet() { XRK_DL_QUIET=1 xrk_download "$@"; }

# 统一 JS 包管理换源（npm/pnpm）：国内优先 npmmirror，国外不强制
xrk_setup_js_mirrors() {
    if command -v npm &>/dev/null; then
        npm config set registry https://registry.npmmirror.com 2>/dev/null || true
    fi
    if command -v pnpm &>/dev/null; then
        pnpm config set registry https://registry.npmmirror.com 2>/dev/null || true
    fi
}

change_source_linux() {
    ensure_cmd curl curl
    bash <(curl -sSL https://linuxmirrors.cn/main.sh)
}

change_source_linux_auto() {
    [ ! -f /etc/os-release ] && return 0
    # shellcheck source=/dev/null
    . /etc/os-release
    [ "$ID" = "ubuntu" ] && [ -f /etc/apt/sources.list ] && sed -i 's/ports.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list 2>/dev/null
    [ "$ID" = "debian" ] && [ -f /etc/apt/sources.list ] && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list 2>/dev/null
}
