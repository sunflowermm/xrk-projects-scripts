#!/bin/bash
# 报错修复：浏览器/Node/pnpm/yq/ffmpeg 重装
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 1 0

clean_existing() {
    local package=$1
    local os
    os=$(detect_os)
    echo "清理现有 $package 安装..."
    case "$os" in
        debian|ubuntu) apt-get remove --purge -y "${package}"* 2>/dev/null; apt-get autoremove -y 2>/dev/null ;;
        centos)        command -v dnf &>/dev/null && dnf remove -y "${package}"* 2>/dev/null || yum remove -y "${package}"* 2>/dev/null ;;
        arch)          pacman -Rns --noconfirm "$package" 2>/dev/null ;;
        *)             ;;
    esac
}

install_chromium() {
    clean_existing "chromium"
    os=$(detect_os)
    if [ "$os" = "ubuntu" ]; then
        run_software "project-install/software/chromium"
    else
        install_pkg chromium 2>/dev/null || run_software "project-install/software/chromium"
    fi
}

clean_and_install_node() {
    clean_existing "nodejs"
    clean_existing "npm"
    rm -rf /usr/local/bin/npm /usr/local/lib/node_modules /opt/node 2>/dev/null
    find / -name npm -type f 2>/dev/null | head -5 | xargs -r rm -f 2>/dev/null
    run_software "project-install/software/node"
}

clean_and_install_pnpm() {
    npm uninstall -g pnpm 2>/dev/null
    rm -rf ~/.pnpm-store 2>/dev/null
    run_software "project-install/software/pnpm"
}

clean_and_install_yq() {
    clean_existing "yq"
    run_software "project-install/software/yq"
}

fix_puppeteer() {
    export PUPPETEER_SKIP_DOWNLOAD='true'
    pnpm config set node_sqlite3_binary_host_mirror https://npmmirror.com/mirrors/sqlite3 2>/dev/null
    if [ -d "$yz" ]; then
        (cd "$yz" && pnpm update puppeteer@19.8.3 -w && pnpm i)
    else
        echo "未找到葵崽目录"; return 1
    fi
}

show_menu() {
    menu_show_double "报错修复菜单" "浏览器修复 [多系统支持]" "修复依赖项1 [智能诊断]" "修复依赖项2 [深度重装]" "Node.js 完整重装" "PNPM 完整重装" "YQ 完整重装" "FFMPEG"
}

menu_check_deps curl wget git

while true; do
    show_menu
    read -rp "请选择 [1-${MENU_OPT_COUNT}]，q 退出: " raw_choice
    CHOICE=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    clear_menu
    [ "$CHOICE" = "0" ] || [ "$CHOICE" = "q" ] && { echo "退出"; exit 0; }
    case "$CHOICE" in
        1) read -rp "确认删除并重装浏览器？[y/N]: " confirm
           [[ "$confirm" =~ ^[Yy]$ ]] && install_chromium && fix_puppeteer && echo "浏览器修复完成" ;;
        2) fix_puppeteer; echo "基础依赖修复完成" ;;
        3) [ -d "$yz" ] && { rm -rf "$HOME/.pm2" "$yz/node_modules"; clean_and_install_node; clean_and_install_pnpm; fix_puppeteer; echo "修复完成，请使用 xyz 启动葵崽"; } || echo "未检测到葵崽安装" ;;
        4) clean_and_install_node ;;
        5) clean_and_install_pnpm ;;
        6) clean_and_install_yq ;;
        7) run_software "project-install/software/ffmpeg" ;;
        *) echo "无效选择" ;;
    esac
done
