#!/data/data/com.termux/files/usr/bin/bash

# 确保在Termux环境中运行
if [[ "$(pwd)" != *com.termux* ]]; then
    echo -e "\033[1;31m请在 Termux 原生环境下运行此脚本\033[0m"
    exit 1
fi


# 引入外部函数
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Termux.sh")

# 参数解析
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
  *)
    echo -e "\033[1;31m老弟会不会用啊\033[0m"
    exit 1
    ;;
esac

# 通用变量定义
INSTALL_DIR="$HOME/${DISTRO^}"
START_SCRIPT="$HOME/${DISTRO}_start"
SHORTCUT_CMD="$PREFIX/bin/$SHORTCUT"
INITIAL_SCRIPT_URL="https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/.xrkinitial"
ARCH="arm64"

# 镜像列表
# 镜像与中文名对应关系 (使用关联数组)
declare -A MIRRORS
MIRRORS=(
    ["https://mirrors.bfsu.edu.cn/lxc-images/images"]="北京外国语大学镜像站"
    ["https://mirror.nju.edu.cn/lxc-images/images"]="南京大学镜像站"
    ["https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images"]="清华大学TUNA镜像站"
    ["https://mirrors.ustc.edu.cn/lxc-images/images"]="中国科学技术大学镜像站"
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
}

setup_locale() {
    sep
    info "配置中文本地化..."
    locale_file="$INSTALL_DIR/etc/locale.conf"
    locale_gen="$INSTALL_DIR/etc/locale.gen"
    groups_ud="$INSTALL_DIR/root/.hushlogin"
    [ -f "$locale_gen" ] && sed -i '/zh_CN.UTF-8 UTF-8/s/^#//' "$locale_gen"
    [ -f "$locale_gen" ] && sed -i '/en_US.UTF-8 UTF-8/s/^#//' "$locale_gen"
    echo 'LANG=zh_CN.UTF-8' > "$locale_file"
    touch "$groups_ud"
}

create_start_script() {
    sep
    info "创建启动脚本 $START_SCRIPT"
    cat > "$START_SCRIPT" <<- EOM
#!/bin/bash
echo "启动 $DISTRO ($RELEASE) ..."
unset LD_PRELOAD
cd \$(dirname \$0)
command="proot --link2symlink -0 -r $INSTALL_DIR -b /dev -b /dev/null:/proc/sys/kernel/cap_last_cap -b /proc -b /data/data/com.termux/files/usr/tmp:/tmp -b $INSTALL_DIR/root:/dev/shm -w /root /usr/bin/env -i HOME=/root TERM=\$TERM LANG=zh_CN.UTF-8"
if [ "$DISTRO" = "ubuntu" ]; then
    command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
elif [ "$DISTRO" = "debian" ]; then
    command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
fi
command+=" /bin/bash --login"
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
    cat >> "$INSTALL_DIR/etc/profile.d/1.sh" <<- EOM
rm -f \${BASH_SOURCE[0]}
locale-gen || true
update-locale LANG=zh_CN.UTF-8
bash .xrk
EOM

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