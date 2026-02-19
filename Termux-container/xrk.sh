#!/data/data/com.termux/files/usr/bin/bash

# 确保在Termux环境中运行
if [[ "$(pwd)" != *com.termux* ]]; then
    echo -e "\033[1;31m请在 Termux 原生环境下运行此脚本\033[0m"
    exit 1
fi


# 参数：$2 = 1 GitCode 2 GitHub 3 Gitee（默认 1），与 bootstrap 统一
XRK_SOURCE="${2:-1}"
source <(curl -sL "https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master/shell_modules/bootstrap.sh")
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg "$XRK_SOURCE")}"
export SCRIPT_RAW_BASE XRK_SOURCE

# 引入外部函数（Termux 换源、字体键盘等）
source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/Termux.sh")

# 参数解析：支持多种发行版
case "$1" in
  --ubuntu)
    DISTRO="ubuntu"
    RELEASE="noble"
    SHORTCUT="u"
    ;;
  --debian)
    DISTRO="debian"
    RELEASE="bookworm"
    SHORTCUT="d"
    ;;
  --alpine)
    DISTRO="alpine"
    RELEASE="3.22"
    SHORTCUT="a"
    ;;
  --arch)
    DISTRO="archlinux"
    RELEASE="current"
    SHORTCUT="c"
    ;;
  --fedora)
    DISTRO="fedora"
    RELEASE="43"
    SHORTCUT="f"
    ;;
  --centos)
    DISTRO="centos"
    RELEASE="9-Stream"
    SHORTCUT="s"
    ;;
  --help|-h)
    echo "用法: bash xrk.sh --<发行版> [源: 1=GitCode 2=GitHub 3=Gitee]"
    echo ""
    echo "支持的发行版:"
    echo "  --ubuntu    Ubuntu (noble)"
    echo "  --debian    Debian (bookworm)"
    echo "  --alpine    Alpine Linux (3.22)"
    echo "  --arch      Arch Linux (current)"
    echo "  --fedora    Fedora (43)"
    echo "  --centos    CentOS Stream 9"
    exit 0
    ;;
  *)
    echo -e "\033[1;31m请使用 --ubuntu / --debian / --alpine / --arch / --fedora / --centos 或 --help 查看帮助\033[0m"
    exit 1
    ;;
esac

# 通用变量定义
INSTALL_DIR="$HOME/${DISTRO^}"
START_SCRIPT="$HOME/${DISTRO}_start"
SHORTCUT_CMD="$PREFIX/bin/$SHORTCUT"
INITIAL_SCRIPT_URL="$SCRIPT_RAW_BASE/.xrkinitial"
# LXC 镜像架构：arm64(aarch64) | amd64(x86_64)
case "$(uname -m)" in
    aarch64|arm64) ARCH="arm64" ;;
    x86_64|amd64)  ARCH="amd64" ;;
    *)             ARCH="arm64" ;;  # 默认 arm64（常见手机）
esac

# 镜像列表（USTC 无 LXC 镜像已移除，详见 MIRROR_CHECK.md）
declare -A MIRRORS
MIRRORS=(
    ["https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images"]="清华大学TUNA镜像站"
    ["https://mirror.nju.edu.cn/lxc-images/images"]="南京大学镜像站"
    ["https://mirrors.bfsu.edu.cn/lxc-images/images"]="北京外国语大学镜像站"
    ["https://images.linuxcontainers.org/images"]="官方Linux Containers镜像源"
)

SYS="$DISTRO/$RELEASE"

# 彩色和装饰函数
info() {
    echo -e "\033[1;32m[信息]\033[0m $*"
}

warn() {
    echo -e "\033[1;33m[警告]\033[0m $*"
}

error() {
    echo -e "\033[1;31m[错误]\033[0m $*"
}

sep() {
    echo -e "\033[1;34m========================================================\033[0m"
}

download_rootfs() {
    sep
    info "开始下载 $DISTRO ($RELEASE) rootfs 镜像..."
    local shuffled_mirrors=($(printf "%s\n" "${!MIRRORS[@]}" | shuf))
    local success=0
    for mirror in "${shuffled_mirrors[@]}"; do
        local cname=${MIRRORS[$mirror]}
        info "尝试使用镜像源: $mirror ($cname)"
        data=$(curl -sL "$mirror/$SYS/$ARCH/default/" | \
               grep -Eo 'href="[0-9A-Za-z_%]+/"' | \
               grep -Eo '[0-9A-Za-z_%]+' | tail -n1)
        if [ -z "$data" ]; then
            warn "从 $cname 获取目录信息失败，尝试下一个镜像源"
            continue
        fi
        download_url="$mirror/$SYS/$ARCH/default/$data/rootfs.tar.xz"
        sha_url="$mirror/$SYS/$ARCH/default/$data/SHA256SUMS"
        if ! curl -sI "$download_url" | grep -q "200"; then
            warn "在 $cname 未找到有效的 rootfs 文件，尝试下一个镜像源"
            continue
        fi
        if [ -f "$HOME/rootfs.tar.xz" ]; then
            info "检测到已有 rootfs 文件，开始验证 SHA256 校验和..."
        else
            info "正在从 $cname 下载 rootfs，请耐心等待..."
            rm -f "$HOME/rootfs.tar.xz" # 确保干净环境
            if ! wget -q --show-progress "$download_url" -O "$HOME/rootfs.tar.xz"; then
                warn "从 $cname 下载失败，尝试下一个镜像源"
                continue
            fi
        fi
        rootfs_sha256=$(curl -sL "$sha_url" | grep 'rootfs.tar.xz' | awk '{print $1}')
        if [ -z "$rootfs_sha256" ]; then
            warn "未能从 $cname 获取到有效的 SHA256 校验和信息，尝试下一个镜像"
            rm -f "$HOME/rootfs.tar.xz"
            continue
        fi
        info "正在进行 SHA256 校验..."
        downloaded_sha=$(sha256sum "$HOME/rootfs.tar.xz" | awk '{print $1}')
        if [ "$downloaded_sha" = "$rootfs_sha256" ]; then
            info "从 $cname 获取的镜像文件校验通过！"
            success=1
            break
        else
            warn "校验失败，将尝试下一个镜像源"
            rm -f "$HOME/rootfs.tar.xz"
        fi
    done
    if [ $success -ne 1 ]; then
        error "所有镜像源均下载失败，请检查网络或稍后重试。"
        exit 1
    fi
    mkdir -p "$INSTALL_DIR/root"
    return 0
}

install_system() {
    sep
    info "开始解压 rootfs 到 $INSTALL_DIR"
    proot --link2symlink tar -xJf "$HOME/rootfs.tar.xz" -C "$INSTALL_DIR" --exclude='dev' || { error "解压失败"; exit 1; }
    rm -f "$INSTALL_DIR/etc/resolv.conf" "$INSTALL_DIR/etc/hosts"
    echo "127.0.0.1 localhost" > "$INSTALL_DIR/etc/hosts"
    echo -e "nameserver 223.5.5.5\nnameserver 223.6.6.6" > "$INSTALL_DIR/etc/resolv.conf"
    info "$DISTRO 系统安装完成"
    # Alpine 默认无 bash，需先安装
    if [ "$DISTRO" = "alpine" ]; then
        info "Alpine 需安装 bash，正在执行..."
        proot --link2symlink -0 -r "$INSTALL_DIR" -b /dev -b /proc -w /root \
            /usr/bin/env -i HOME=/root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
            /bin/sh -c "apk add --no-cache bash" 2>/dev/null || warn "bash 安装失败，将使用 sh"
    fi
}

setup_locale() {
    sep
    info "配置中文本地化..."
    locale_file="$INSTALL_DIR/etc/locale.conf"
    locale_gen="$INSTALL_DIR/etc/locale.gen"
    groups_ud="$INSTALL_DIR/root/.hushlogin"
    touch "$groups_ud"
    if [ "$DISTRO" = "alpine" ]; then
        echo 'LANG=zh_CN.UTF-8' > "$locale_file"
        [ -f "$INSTALL_DIR/etc/profile.d/locale.sh" ] || echo 'export LANG=zh_CN.UTF-8' > "$INSTALL_DIR/etc/profile.d/locale.sh"
    else
        [ -f "$locale_gen" ] && sed -i '/zh_CN.UTF-8 UTF-8/s/^#//' "$locale_gen"
        [ -f "$locale_gen" ] && sed -i '/en_US.UTF-8 UTF-8/s/^#//' "$locale_gen"
        echo 'LANG=zh_CN.UTF-8' > "$locale_file"
    fi
}

create_start_script() {
    sep
    info "创建启动脚本 $START_SCRIPT"
    # 通用 PATH，各发行版兼容
    case "$DISTRO" in
        ubuntu)  path_add="PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin" ;;
        debian)  path_add="PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games" ;;
        alpine)  path_add="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" ;;
        *)       path_add="PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin" ;;
    esac
    # Alpine 若无 bash 则用 sh
    login_shell="/bin/bash --login"
    [ ! -f "$INSTALL_DIR/bin/bash" ] && [ -f "$INSTALL_DIR/bin/sh" ] && login_shell="/bin/sh -l"
    cat > "$START_SCRIPT" <<- EOM
#!/bin/bash
echo "启动 $DISTRO ($RELEASE) ..."
unset LD_PRELOAD
cd \$(dirname \$0)
command="proot --link2symlink -0 -r $INSTALL_DIR -b /dev -b /dev/null:/proc/sys/kernel/cap_last_cap -b /proc -b /data/data/com.termux/files/usr/tmp:/tmp -b $INSTALL_DIR/root:/dev/shm -w /root /usr/bin/env -i HOME=/root TERM=\$TERM LANG=zh_CN.UTF-8 $path_add"
command+=" $login_shell"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$@"
fi
EOM

    termux-fix-shebang "$START_SCRIPT"
    chmod +x "$START_SCRIPT"
    curl -o "$INSTALL_DIR/root/.xrk" "$INITIAL_SCRIPT_URL"
    info "配置一次性启动脚本..."
    printf 'XRK_SOURCE="%s"\n' "$XRK_SOURCE" > "$INSTALL_DIR/root/.xrk_env"
    if [ "$DISTRO" = "alpine" ]; then
        cat >> "$INSTALL_DIR/etc/profile.d/1.sh" <<- EOM
rm -f \${BASH_SOURCE[0]}
[ -f /root/.xrk_env ] && source /root/.xrk_env && rm -f /root/.xrk_env
export LANG=zh_CN.UTF-8
bash .xrk 2>/dev/null || sh .xrk
EOM
    else
        cat >> "$INSTALL_DIR/etc/profile.d/1.sh" <<- EOM
rm -f \${BASH_SOURCE[0]}
[ -f /root/.xrk_env ] && source /root/.xrk_env && rm -f /root/.xrk_env
locale-gen 2>/dev/null || true
update-locale LANG=zh_CN.UTF-8 2>/dev/null || true
bash .xrk
EOM
    fi

    cat > "$SHORTCUT_CMD" <<- EOM
#!/bin/bash
bash "$START_SCRIPT" "\$@"
EOM
    chmod +x "$SHORTCUT_CMD"
    info "写入启动脚本成功，输入 \033[1;32m$SHORTCUT\033[0m 启动 $DISTRO"
}

ensure_bashrc() {
    [ ! -f "$HOME/.bashrc" ] && touch "$HOME/.bashrc"
    line="echo 输入 $SHORTCUT 启动 $DISTRO"
    grep -qxF "$line" "$HOME/.bashrc" || echo "$line" >> "$HOME/.bashrc"
    grep -qxF "termux-wake-lock" "$HOME/.bashrc" || echo "termux-wake-lock" >> "$HOME/.bashrc"
    termux-wake-lock
}

main() {
    sep
    echo -e "\033[1;35m欢迎使用 $DISTRO ($RELEASE) 安装脚本！\033[0m"
    sep
    if [ -d "$INSTALL_DIR/root" ] && [ -f "$START_SCRIPT" ]; then
        info "检测到 $DISTRO 已安装，开始启动..."
        bash "$START_SCRIPT"
        exit 0
    fi
    ensure_bashrc
    换源魔法
    yes | pkg update -y
    字体键盘魔法
    download_rootfs
    install_system
    setup_locale
    create_start_script
    sep
    info "安装完成！直接输入 \033[1;32m$SHORTCUT\033[0m 启动 $DISTRO"
    sep
}

main