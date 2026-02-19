#!/bin/bash
# 公共模块：环境检测、多架构、统一包安装、Linux 换源（不包含 Termux 换源）
# 供 xm / install_xm / 主流程 / 容器 / 菜单脚本 等复用；Termux 换源见 Termux.sh 换源魔法 + repo.sh
# 提供：detect_arch, detect_arch_raw, detect_platform, detect_os, install_pkg, ensure_cmd, change_source_linux*

SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"

# 检测架构：x64|arm64|armv7l|ppc64le|s390x（Node/ffmpeg 等用）
# 返回 uname -m 原始值供部分脚本使用，标准化名供下载 URL 用
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armhf) echo "armv7l" ;;
        ppc64le) echo "ppc64le" ;;
        s390x) echo "s390x" ;;
        i386|i686) echo "x86" ;;
        *) echo "$(uname -m)" ;;
    esac
}

# 原始架构（uname -m），供 yq/pnpm 等需要 x86_64/aarch64 的脚本用
detect_arch_raw() {
    uname -m
}

# 平台：linux | macos（供 ffmpeg 等二进制下载用，与发行版无关）
detect_platform() {
    case "$(uname -s)" in
        Linux) echo "linux" ;;
        Darwin) echo "macos" ;;
        *) echo "unknown" ;;
    esac
}

# 检测当前环境：termux | debian | ubuntu | arch | centos | opensuse | alpine | void | unknown
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
            arch|manjaro) echo "arch" ;;
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

# 是否已安装（按系统判断）
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

# 最大重试次数
_INSTALL_MAX_RETRIES=3

# 统一安装单个包：自动检测系统、已安装则跳过、失败重试
install_pkg() {
    local pkg="$1"
    [ -z "$pkg" ] && return 1
    local os
    os=$(detect_os)
    if _is_pkg_installed "$pkg" "$os"; then
        echo -e "\033[0;32m$pkg 已安装，无需重复安装\033[0m"
        return 0
    fi
    local retry=0
    while [ "$retry" -lt "$_INSTALL_MAX_RETRIES" ]; do
        echo -e "\033[0;34m正在安装 $pkg...\033[0m"
        case "$os" in
            termux)
                if pkg install -y "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            debian|ubuntu)
                if apt-get update -qq && apt-get install -y "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            arch)
                if pacman -Sy --noconfirm "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            centos)
                if command -v dnf &>/dev/null; then
                    dnf install -y "$pkg"
                else
                    yum install -y "$pkg"
                fi
                if [ $? -eq 0 ]; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            opensuse)
                if zypper -n install "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            alpine)
                if apk add --no-cache "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            void)
                if xbps-install -Sy "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            gentoo)
                if emerge -q "$pkg"; then
                    echo -e "\033[0;32m$pkg 安装成功\033[0m"
                    return 0
                fi
                ;;
            *)
                echo -e "\033[0;31m无法识别的系统类型($os)，请手动安装 $pkg\033[0m"
                return 1
                ;;
        esac
        retry=$((retry + 1))
        echo -e "\033[0;33m重试安装 $pkg ($retry/$_INSTALL_MAX_RETRIES)...\033[0m"
    done
    echo -e "\033[0;31m$pkg 安装失败次数达到上限\033[0m"
    return 1
}

# 确保命令存在，不存在则安装（curl / git 等）
ensure_cmd() {
    local cmd="$1"
    local pkg="${2:-$cmd}"
    [ -z "$cmd" ] && return 1
    if command -v "$cmd" &>/dev/null; then
        return 0
    fi
    install_pkg "$pkg"
}

# ---------- 换源：仅 Linux（本机或容器），Termux 使用 Termux.sh 换源魔法 + repo.sh ----------

# 交互式换源：使用 linuxmirrors.cn（xm 菜单选项 1）
change_source_linux() {
    ensure_cmd curl curl
    bash <(curl -sSL https://linuxmirrors.cn/main.sh)
}

# 非交互式换源：Debian/Ubuntu 写死国内镜像（容器等无交互场景）
change_source_linux_auto() {
    [ ! -f /etc/os-release ] && return 0
    # shellcheck source=/dev/null
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
        [ -f /etc/apt/sources.list ] && sed -i 's/ports.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list 2>/dev/null
    elif [ "$ID" = "debian" ]; then
        [ -f /etc/apt/sources.list ] && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list 2>/dev/null
    fi
    return 0
}
