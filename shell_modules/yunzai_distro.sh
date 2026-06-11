#!/bin/bash
# 葵崽各发行版安装公共逻辑（供 project-install/Yunzai/*.sh 复用）

_yunzai_distro_label() {
    case "$1" in
        ubuntu)   echo "Ubuntu" ;;
        debian)   echo "Debian" ;;
        arch)     echo "Arch" ;;
        centos)   echo "CentOS/RHEL/Fedora" ;;
        opensuse) echo "openSUSE" ;;
        alpine)   echo "Alpine" ;;
        generic)  echo "通用 ($(detect_os))" ;;
        *)        echo "$1" ;;
    esac
}

_yunzai_packages() {
    case "$1" in
        ubuntu)   echo "git wget tar dialog xz-utils jq redis sudo tmux fonts-wqy-microhei fonts-wqy-zenhei" ;;
        debian)   echo "git wget dialog tar xz-utils jq redis tmux fontconfig fonts-wqy-zenhei" ;;
        arch)     echo "git wget tar xz jq go-yq sudo nodejs-lts-iron npm redis wqy-bitmapfont wqy-zenhei ttf-arphic-ukai ttf-arphic-uming" ;;
        centos)   echo "git wget tar xz jq epel-release redis fontconfig wqy-zenhei" ;;
        opensuse) echo "git wget tar xz jq redis fontconfig" ;;
        alpine)   echo "git wget tar xz jq redis fontconfig" ;;
        generic)  echo "git wget tar xz jq redis" ;;
    esac
}

_yunzai_ensure_chromium() {
    command -v chromium &>/dev/null && return 0
    case "$1" in
        ubuntu) run_chromium ;;
        *)      install_package chromium 2>/dev/null || true ;;
    esac
}

# 用法：yunzai_distro_main <ubuntu|debian|arch|centos|opensuse|alpine|generic>
yunzai_distro_main() {
    local distro="${1:-$(detect_os)}"
    local label pkgs pkg

    label=$(_yunzai_distro_label "$distro")
    if [ "$distro" = "generic" ]; then
        log_info "通用安装 (OS: $(detect_os))"
    else
        log_success "${label} 主流程"
    fi

    if [ "$distro" != "generic" ]; then
        log_info "正在更新系统..."
        system_update "$distro" || { log_error "系统更新失败"; exit 1; }
    fi

    run_yq
    pkgs=$(_yunzai_packages "$distro")
    for pkg in $pkgs; do install_package "$pkg"; done
    _yunzai_ensure_chromium "$distro"
    葵崽主流程安装
}
