#!/bin/bash
# 葵崽(XRK-Yunzai) / 葵子(XRK-AGT) 路径、安装与管理

[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"
[ -f "${XRK_ROOT:-/xrk}/shell_modules/kuizi_repos.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/kuizi_repos.sh"

KUIZI_PKG_YUNZAI="xrk-yunzai"
KUIZI_PKG_AGT="xrk-agt"

kuizi_read_pkg_name() {
    local dir="$1" name
    [ -f "$dir/package.json" ] || return 1
    name=$(jq -r '.name // empty' "$dir/package.json" 2>/dev/null)
    if [ -z "$name" ]; then
        name=$(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$dir/package.json" 2>/dev/null \
            | head -1 | sed -n 's/.*"\([^"]*\)"$/\1/p')
    fi
    [ -n "$name" ] && echo "$name"
}

kuizi_validate_dir() {
    local dir="$1" expected="$2" name
    name=$(kuizi_read_pkg_name "$dir") || return 1
    [ "$name" = "$expected" ]
}

kuizi_bind_yunzai() {
    local dir="$1"
    kuizi_validate_dir "$dir" "$KUIZI_PKG_YUNZAI" || return 1
    export yz="$dir" xyz="$dir"
}

kuizi_bind_agt() {
    local dir="$1"
    kuizi_validate_dir "$dir" "$KUIZI_PKG_AGT" || return 1
    export agt="$dir"
}

kuizi_clear_yunzai() { unset yz xyz; }
kuizi_clear_agt()    { unset agt; }

kuizi_refresh_paths() {
    type check_changes &>/dev/null && check_changes
    type search_directories &>/dev/null && search_directories
}

kuizi_yunzai_dir() { echo "${yz:-${xyz:-}}"; }
kuizi_agt_dir()    { echo "${agt:-}"; }

kuizi_product_version() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    jq -r '.version // "?"' "$dir/package.json" 2>/dev/null || echo "?"
}

kuizi_show_status() {
    local yz_dir agt_dir
    kuizi_refresh_paths
    yz_dir=$(kuizi_yunzai_dir)
    agt_dir=$(kuizi_agt_dir)

    echo ""
    echo "── 葵崽 (XRK-Yunzai) ──"
    if [ -n "$yz_dir" ] && [ -d "$yz_dir" ]; then
        echo "  路径: $yz_dir"
        echo "  版本: $(kuizi_product_version "$yz_dir")"
        echo "  当前源: $(kuizi_product_source_display "$yz_dir" yunzai)"
        echo "  启动: xyz"
        echo "  三仓库:"
        kuizi_list_mirror_urls yunzai | sed 's/^/    /'
    else
        echo "  状态: 未安装（默认 ${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}）"
        echo "  默认源: $(kuizi_source_label) ($(kuizi_clone_url yunzai))"
    fi

    echo ""
    echo "── 葵子 (XRK-AGT) ──"
    if [ -n "$agt_dir" ] && [ -d "$agt_dir" ]; then
        echo "  路径: $agt_dir"
        echo "  版本: $(kuizi_product_version "$agt_dir")"
        echo "  当前源: $(kuizi_product_source_display "$agt_dir" agt)"
        echo "  启动: xag"
        echo "  三仓库:"
        kuizi_list_mirror_urls agt | sed 's/^/    /'
    else
        echo "  状态: 未安装（默认 ${AGT_DEFAULT_DIR:-$HOME/XRK-AGT}）"
        echo "  默认源: $(kuizi_source_label) ($(kuizi_clone_url agt))"
    fi
    echo ""
}

kuizi_ensure_node_pnpm() {
    command -v pnpm &>/dev/null || {
        type run_software &>/dev/null && run_software "project-install/software/pnpm" \
            || type xrk_run_script &>/dev/null && xrk_run_script "project-install/software/pnpm"
    }
    command -v node &>/dev/null || {
        type run_software &>/dev/null && run_software "project-install/software/node" \
            || type xrk_run_script &>/dev/null && xrk_run_script "project-install/software/node"
    }
}

kuizi_install_deps() {
    local dir="$1" label="$2"
    kuizi_ensure_node_pnpm
    echo "[$label] pnpm install …"
    (cd "$dir" && pnpm i)
}

kuizi_install_yunzai() {
    local dest="${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
    local name="${YZ_DEFAULT_NAME:-XRK-Yunzai}"

    if [ -d "$dest" ] && kuizi_validate_dir "$dest" "$KUIZI_PKG_YUNZAI"; then
        type xrk_confirm &>/dev/null && xrk_confirm "检测到葵崽 ($dest)，是否删除并重新安装? (是/否)" '^(是|[Yy])$' || return 0
        rm -rf "$dest"
        kuizi_clear_yunzai
    elif [ -d "$dest" ]; then
        echo "[葵崽] 目录 $dest 存在但不是葵崽，请手动处理" >&2
        return 1
    fi

    kuizi_clone_product yunzai "$dest" "$name" || return 1
    kuizi_install_yunzai_extras "$dest" || return 1
    kuizi_install_deps "$dest" "葵崽" || return 1
    kuizi_bind_yunzai "$dest"
    chmod +x "${XRK_ROOT:-/xrk}/judge.sh" 2>/dev/null || true
    [ -f "${XRK_ROOT:-/xrk}/judge.sh" ] && . "${XRK_ROOT:-/xrk}/judge.sh"
    echo "[葵崽] 已安装 ($dest)，源: $(kuizi_source_label)"
}

kuizi_install_agt() {
    local dest="${AGT_DEFAULT_DIR:-$HOME/XRK-AGT}"
    local name="${AGT_DEFAULT_NAME:-XRK-AGT}"

    if [ -d "$dest" ] && kuizi_validate_dir "$dest" "$KUIZI_PKG_AGT"; then
        menu_confirm "检测到葵子 ($dest)，是否删除并重新安装? (y/N)" || return 0
        rm -rf "$dest"
        kuizi_clear_agt
    elif [ -d "$dest" ]; then
        menu_msg_err "目录 $dest 存在但不是葵子 (xrk-agt)，请手动处理"
        return 1
    fi

    kuizi_clone_product agt "$dest" "$name" || return 1
    kuizi_install_deps "$dest" "葵子" || return 1
    kuizi_bind_agt "$dest"
    menu_msg_ok "葵子已安装到 $dest（源: $(kuizi_source_label)），使用 xag 启动"
}

kuizi_manage_menu() {
    local choice yz_dir agt_dir
    while true; do
        kuizi_show_status
        echo "  1  刷新路径"
        echo "  2  葵崽拉取（主仓 + 子仓）"
        echo "  3  葵子拉取（主仓）"
        echo "  0/q  返回"
        choice=$(menu_read_choice "请选择: ") || return 0
        menu_should_exit "$choice" quit && return 0
        case "$choice" in
            1) kuizi_refresh_paths; menu_msg_ok "路径已刷新" ;;
            2)
                yz_dir=$(kuizi_yunzai_dir)
                [ -n "$yz_dir" ] && [ -d "$yz_dir" ] \
                    && kuizi_pull_yunzai_tree "$yz_dir" \
                    || menu_msg_err "未找到葵崽目录"
                ;;
            3)
                agt_dir=$(kuizi_agt_dir)
                [ -n "$agt_dir" ] && [ -d "$agt_dir" ] \
                    && kuizi_pull_agt_tree "$agt_dir" \
                    || menu_msg_err "未找到葵子目录"
                ;;
            *) menu_msg_err ;;
        esac
        echo
    done
}
