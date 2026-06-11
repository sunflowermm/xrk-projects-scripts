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

# 卸载系统包（供 errorbg、xrkk 等复用）
remove_pkg() {
    local pkg="$1" os
    [ -z "$pkg" ] && return 1
    os=$(detect_os)
    case "$os" in
        termux)   pkg uninstall -y "$pkg" 2>/dev/null ;;
        debian|ubuntu) apt-get remove --purge -y "${pkg}"* 2>/dev/null; apt-get autoremove -y 2>/dev/null ;;
        centos|opensuse) command -v dnf &>/dev/null && dnf remove -y "${pkg}"* 2>/dev/null || yum remove -y "${pkg}"* 2>/dev/null ;;
        arch) pacman -Rns --noconfirm "$pkg" 2>/dev/null ;;
        alpine) apk del "$pkg" 2>/dev/null ;;
        *) return 1 ;;
    esac
}

remove_pkgs() {
    local pkg
    for pkg in "$@"; do remove_pkg "$pkg"; done
}

install_pkgs() {
    local pkg
    for pkg in "$@"; do install_pkg "$pkg" || return 1; done
}

# 系统更新（葵崽发行版安装等复用）
# 用法：system_update [ubuntu|debian|arch|centos|opensuse|alpine|generic]
system_update() {
    local os="${1:-$(detect_os)}"
    case "$os" in
        ubuntu)   apt update -qq && apt upgrade -y ;;
        debian)   apt-get update -qq && apt-get upgrade -y ;;
        arch)     pacman -Syu --noconfirm ;;
        centos)   command -v dnf &>/dev/null && dnf update -y || yum update -y ;;
        opensuse) zypper -n refresh && zypper -n update -y ;;
        alpine)   apk update && apk upgrade -y ;;
        generic)  return 0 ;;
        *)        return 1 ;;
    esac
}

# NapCat 等仅支持 apt/dnf 的场景（无 dnf 时回退 yum）
detect_apt_dnf_pm() {
    local os
    os=$(detect_os)
    case "$os" in
        debian|ubuntu) echo "apt-get"; return 0 ;;
        centos|rhel|fedora|rocky|almalinux)
            command -v dnf &>/dev/null && echo "dnf" && return 0
            command -v yum &>/dev/null && echo "yum" && return 0
            return 1
            ;;
        *) return 1 ;;
    esac
}

# 首跳安装 curl（install_xm 等）
ensure_curl() {
    command -v curl &>/dev/null && return 0
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y curl
    elif command -v yum &>/dev/null; then
        yum install -y curl
    elif command -v dnf &>/dev/null; then
        dnf install -y curl
    elif command -v pacman &>/dev/null; then
        pacman --disable-sandbox -Sy --noconfirm curl
    else
        return 1
    fi
    command -v curl &>/dev/null
}

# 标准加载 common（本地 /xrk 优先，否则远程；可重复调用）
xrk_source_common() {
    type detect_os &>/dev/null && return 0
    local root="${XRK_ROOT:-/xrk}"
    SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    export SCRIPT_RAW_BASE
    if type load_module &>/dev/null; then
        load_module "shell_modules/common.sh" && return 0
    fi
    if [ -f "$root/shell_modules/common.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/common.sh"
        return 0
    fi
    # shellcheck source=/dev/null
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
}

# 软件/模块安装脚本标准入口：common + versions + github + 颜色
xrk_init_software() {
    xrk_source_common
    load_install_deps
    xrk_colors 2>/dev/null || true
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

# 加载软件安装脚本常用依赖（common 已由调用方 source，此处补 versions + github）
load_install_deps() {
    local root="${XRK_ROOT:-/xrk}"
    if type load_module &>/dev/null; then
        load_module "shell_modules/versions.sh"
        load_module "shell_modules/github.sh"
        return 0
    fi
    local base="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    [ -f "$root/shell_modules/versions.sh" ] && source "$root/shell_modules/versions.sh" \
        || source <(curl -sL "$base/shell_modules/versions.sh")
    [ -f "$root/shell_modules/github.sh" ] && source "$root/shell_modules/github.sh" \
        || source <(curl -sL "$base/shell_modules/github.sh")
}

# 从调用栈向上查找脚本仓库根目录（含 shell_modules/common.sh）
_xrk_script_repo_root() {
    local root="${XRK_ROOT:-/xrk}" dir script depth=0
    [ -f "$root/shell_modules/common.sh" ] && { echo "$root"; return 0; }
    for script in "${BASH_SOURCE[@]}"; do
        [[ "$script" == /dev/fd/* ]] && continue
        dir="$(cd "$(dirname "$script")" 2>/dev/null && pwd)" || continue
        depth=0
        while [ "$dir" != "/" ] && [ "$depth" -lt 10 ]; do
            [ -f "$dir/shell_modules/common.sh" ] && { echo "$dir"; return 0; }
            dir="$(dirname "$dir")"
            depth=$((depth + 1))
        done
    done
    return 1
}

# 统一脚本执行：本地优先，远程 curl 兜底，带重试
# 用法：xrk_run_script <repo内路径> [参数...]
xrk_run_script() {
    local path="$1"
    shift
    local args=("$@") base="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
    local retry=0 max_retries=3 repo_root

    repo_root=$(_xrk_script_repo_root 2>/dev/null) || repo_root=""
    [ -n "$repo_root" ] && [ -f "${repo_root}/${path}" ] && { bash "${repo_root}/${path}" "${args[@]}"; return $?; }

    while [ "$retry" -lt "$max_retries" ]; do
        if bash <(curl -sL --connect-timeout 10 --max-time 60 "$base/$path" 2>/dev/null) "${args[@]}"; then
            return 0
        fi
        retry=$((retry + 1))
        [ "$retry" -lt "$max_retries" ] && sleep 2
    done
    echo -e "\033[31m[错误] 远程执行失败: $base/$path\033[0m" >&2
    return 1
}

# 交互确认（deploy 等未加载 menu_common 时使用）
xrk_confirm() {
    local msg="$1" re="${2:-^[Yy]$}" ans
    read -rp "$msg " ans
    [[ "$ans" =~ $re ]]
}

# 下载 GitHub release 二进制到 /usr/local/bin
# 用法：xrk_install_github_binary <owner/repo> <version> <binary_name> <dest_cmd>
xrk_install_github_binary() {
    local repo="$1" version="$2" binary_name="$3" dest_name="${4:-}"
    local url dest_path tmp_ver

    [ -z "$repo" ] || [ -z "$version" ] || [ -z "$binary_name" ] && return 1
    if [ -z "$dest_name" ]; then
        case "$binary_name" in
            pnpm-linux-*) dest_name="pnpm" ;;
            yq_linux_*) dest_name="yq" ;;
            *) dest_name="${binary_name%%_linux*}"; dest_name="${dest_name#pnpm-}" ;;
        esac
    fi
    dest_path="/usr/local/bin/$dest_name"

    if command -v "$dest_name" &>/dev/null; then
        tmp_ver=$("$dest_name" --version 2>/dev/null || "$dest_name" -v 2>/dev/null || true)
        echo -e "\033[0;32m${dest_name} 已安装: ${tmp_ver}\033[0m"
        return 0
    fi

    url="https://github.com/${repo}/releases/download/${version}/${binary_name}"
    cd "$HOME" || return 1
    echo "开始安装 ${dest_name} ${version}..."
    xrk_download "$url" "$binary_name" 3 || { echo "下载失败"; return 1; }
    sudo mv "$binary_name" "$dest_path" && sudo chmod 755 "$dest_path"
    rm -f "$binary_name" 2>/dev/null

    if command -v "$dest_name" &>/dev/null; then
        tmp_ver=$("$dest_name" --version 2>/dev/null || "$dest_name" -v 2>/dev/null || true)
        echo -e "\033[0;32m${dest_name} ${tmp_ver} 安装成功\033[0m"
        return 0
    fi
    echo -e "\033[0;31m${dest_name} 安装失败\033[0m"
    return 1
}

# 后台任务进度指示（node/ffmpeg 等安装脚本复用）
show_progress() {
    local text="$1"
    local blue='\033[0;34m' green='\033[0;32m' nc='\033[0m'
    echo -ne "${blue}${text}...${nc}"
    while kill -0 "${2:-$!}" 2>/dev/null; do echo -n "."; sleep 0.5; done
    echo -e " ${green}✓${nc}"
}

# 导出简写颜色变量（供菜单/安装脚本复用 color.sh）
xrk_colors() {
    [ -n "${RED:-}" ] && return 0
    if [ -f "${XRK_ROOT:-/xrk}/shell_modules/color.sh" ]; then
        # shellcheck source=/dev/null
        source "${XRK_ROOT:-/xrk}/shell_modules/color.sh"
        return 0
    fi
    RED="${RED:-\033[31m}"
    GREEN="${GREEN:-\033[1;32m}"
    YELLOW="${YELLOW:-\033[33m}"
    BLUE="${BLUE:-\033[1;36m}"
    NC="${NC:-\033[0m}"
    export RED GREEN YELLOW BLUE NC
}
