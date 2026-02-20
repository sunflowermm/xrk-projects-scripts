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
