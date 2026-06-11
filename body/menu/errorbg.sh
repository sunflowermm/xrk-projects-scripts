#!/bin/bash
# 报错修复：浏览器/Node/pnpm/yq/ffmpeg 重装
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/menu_head.sh" 1 1

clean_existing() {
    echo "清理现有 $1 安装..."
    remove_pkg "$1" 2>/dev/null || true
}

install_chromium() {
    clean_existing "chromium"
    if [ "$(detect_os)" = "ubuntu" ]; then
        run_software "project-install/software/chromium"
    else
        install_pkg chromium 2>/dev/null || run_software "project-install/software/chromium"
    fi
}

clean_and_install_node() {
    clean_existing "nodejs"
    clean_existing "npm"
    rm -rf /usr/local/bin/npm /usr/local/bin/node /usr/local/lib/node_modules /opt/node 2>/dev/null
    rm -rf "$HOME/.nvm/versions/node" 2>/dev/null
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
    local _yz
    _yz="$(xrk_yz_dir)"
    if [ -d "$_yz" ]; then
        (cd "$_yz" && pnpm update puppeteer@19.8.3 -w && pnpm i)
    else
        menu_msg_err "未找到葵崽目录"
        return 1
    fi
}

menu_check_deps curl wget git

_errorbg_handle() {
    local n="$1"
    case "$n" in
        1)
            menu_confirm "确认删除并重装浏览器？[y/N]" || return 0
            install_chromium && fix_puppeteer && menu_msg_ok "浏览器修复完成"
            ;;
        2) fix_puppeteer && menu_msg_ok "基础依赖修复完成" ;;
        3)
            local _yz
            _yz="$(xrk_yz_dir)"
            if [ -d "$_yz" ]; then
                rm -rf "$HOME/.pm2" "$_yz/node_modules"
                clean_and_install_node
                clean_and_install_pnpm
                fix_puppeteer
                menu_msg_ok "修复完成，请使用 xyz 启动葵崽"
            else
                menu_msg_err "未检测到葵崽安装"
            fi
            ;;
        4) clean_and_install_node ;;
        5) clean_and_install_pnpm ;;
        6) clean_and_install_yq ;;
        7) run_software "project-install/software/ffmpeg" ;;
    esac
}

while true; do
    menu_show_double "报错修复菜单" \
        "浏览器修复 [多系统支持]" "修复依赖项1 [智能诊断]" "修复依赖项2 [深度重装]" \
        "Node.js 完整重装" "PNPM 完整重装" "YQ 完整重装" "FFMPEG"
    choice=$(menu_read_choice "请选择 [1-${MENU_OPT_COUNT}]，0/q 返回: ") || exit 0
    clear_menu
    menu_should_exit "$choice" quit && exit 0
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$MENU_OPT_COUNT" ]; then
        _errorbg_handle "$choice"
    else
        menu_msg_err
    fi
done
