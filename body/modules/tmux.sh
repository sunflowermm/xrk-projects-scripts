#!/bin/bash
# 安装 tmux + 写入 ~/.tmux.conf（纯 conf，无插件）
set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

_tmux_main_src() {
    local root_abs="$1"
    if [ -f "${root_abs}/body/tmux.conf" ]; then
        echo "${root_abs}/body/tmux.conf"
    elif [ -f "${root_abs}/body/.tmux.conf" ]; then
        echo "${root_abs}/body/.tmux.conf"
    else
        return 1
    fi
}

install_menu_wrapper() {
    local menu="$HOME/.tmux/xrk-menu"
    mkdir -p "$HOME/.tmux"
    cat > "$menu" << EOF
#!/bin/bash
export HOME="${HOME:-$(getent passwd "$(id -un 2>/dev/null || echo root)" | cut -d: -f6)}"
[ -f "\$HOME/.xrk_repo" ] && source "\$HOME/.xrk_repo"
XRK_ROOT="${XRK_ROOT:-/xrk}"
exec bash "\$XRK_ROOT/body/tmux-menu.sh" "\$@"
EOF
    chmod +x "$menu"
}

link_conf() {
    local main menus_tpl menus_out entry root_abs menu
    root_abs="$(cd "$XRK_ROOT" 2>/dev/null && pwd)" || root_abs="$XRK_ROOT"
    entry="$HOME/.tmux.conf"
    main="$(_tmux_main_src "$root_abs")" || {
        echo "[tmux] 未找到主配置: ${root_abs}/body/tmux.conf" >&2
        return 1
    }
    menus_tpl="${root_abs}/body/tmux-menus.conf"
    [ -f "$menus_tpl" ] || {
        echo "[tmux] 未找到菜单配置: $menus_tpl" >&2
        return 1
    }
    install_menu_wrapper
    menu="$HOME/.tmux/xrk-menu"
    menus_out="$HOME/.tmux/xrk-menus.conf"
    sed "s|@XRK_MENU@|${menu}|g" "$menus_tpl" > "$menus_out"
    {
        echo "# 向日葵 tmux（xrk-tmux --setup 生成；更新请重跑 setup）"
        echo "# xrk-src: ${main}"
        sed "s|@XRK_MENU@|${menu}|g" "$main"
        echo ""
        echo "# 鼠标右键菜单（内联 display-menu）"
        echo "source-file ${menus_out}"
    } > "$entry"
    echo "[tmux] 已写入 $entry"
    echo "[tmux]   ← ${main}"
    echo "[tmux]   ← ${menus_out}"
}

cleanup_legacy_tmux_plugins() {
    rm -f "$HOME/.tmux/xrk-mouse.conf" 2>/dev/null || true
    if [ -d "$HOME/.tmux/plugins" ] || [ -d "$HOME/.tmux/resurrect" ]; then
        rm -rf "$HOME/.tmux/plugins" "$HOME/.tmux/resurrect" 2>/dev/null || true
        echo "[tmux] 已移除旧 tpm/插件目录"
    fi
}

install_tmux_pkg() {
    if command -v tmux &>/dev/null; then
        echo "[tmux] 已安装: $(tmux -V)"
        return 0
    fi
    echo "[tmux] 安装 tmux…"
    if command -v apt-get &>/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tmux
    elif command -v dnf &>/dev/null; then
        dnf install -y -q tmux
    elif command -v yum &>/dev/null; then
        yum install -y -q tmux
    elif [ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ]; then
        # shellcheck source=/dev/null
        source "$XRK_ROOT/shell_modules/bootstrap.sh"
        xrk_ensure_bootstrap
        # shellcheck source=/dev/null
        source "$XRK_ROOT/shell_modules/xrk_base.sh"
        xrk_加载底层 install
        安装系统包 "tmux" 2>/dev/null || install_package "tmux" 2>/dev/null || return 1
    else
        echo "[tmux] 请手动安装 tmux" >&2
        return 1
    fi
    command -v tmux &>/dev/null || return 1
    echo "[tmux] 已安装: $(tmux -V)"
}

case "${1:-}" in
    --link-only)
        link_conf
        echo "[tmux] 已补写配置"
        exit 0
        ;;
esac

cleanup_legacy_tmux_plugins
install_tmux_pkg
link_conf
echo "[tmux] 完成 → tmux kill-server 2>/dev/null; xrk-tmux"
