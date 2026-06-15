#!/bin/bash
# 安装 tmux + 写入配置（纯 conf，无插件，对齐 sunflower）
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
    local mouse_conf="$HOME/.tmux/xrk-mouse.conf"
    mkdir -p "$HOME/.tmux"
    cat > "$menu" << EOF
#!/bin/bash
export HOME="${HOME:-$(getent passwd "$(id -un 2>/dev/null || echo root)" | cut -d: -f6)}"
[ -f "\$HOME/.xrk_repo" ] && source "\$HOME/.xrk_repo"
XRK_ROOT="${XRK_ROOT:-/xrk}"
exec bash "\$XRK_ROOT/body/tmux-menu.sh" "\$@"
EOF
    chmod +x "$menu"
    cat > "$mouse_conf" << EOF
# 由 xrk-tmux --setup 生成
bind ? run-shell '$menu help'
bind -n MouseDown3Pane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "run-shell '$menu pane'"
bind -n MouseDown3StatusLeft run-shell '$menu session'
bind -n M-MouseDown3StatusLeft run-shell '$menu session'
bind -n MouseDown3Status run-shell '$menu window'
bind -n MouseDown3StatusRight run-shell '$menu system'
EOF
}

link_conf() {
    local main mouse_conf entry root_abs
    root_abs="$(cd "$XRK_ROOT" 2>/dev/null && pwd)" || root_abs="$XRK_ROOT"
    entry="$HOME/.tmux.conf"
    mouse_conf="$HOME/.tmux/xrk-mouse.conf"
    main="$(_tmux_main_src "$root_abs")" || {
        echo "[tmux] 未找到主配置: ${root_abs}/body/tmux.conf" >&2
        echo "[tmux] 请确认仓库在 $root_abs 且已 git 同步" >&2
        return 1
    }
    install_menu_wrapper
    {
        echo "# 向日葵 tmux 入口（xrk-tmux --setup 生成；更新配置请重跑 setup）"
        echo "# xrk-src: ${main}"
        cat "$main"
        echo ""
        echo "# 鼠标右键菜单"
        echo "source-file ${mouse_conf}"
    } > "$entry"
    echo "[tmux] 已写入 $entry"
    echo "[tmux]   ← ${main}"
}

cleanup_legacy_tmux_plugins() {
    if [ -d "$HOME/.tmux/plugins" ] || [ -d "$HOME/.tmux/resurrect" ]; then
        rm -rf "$HOME/.tmux/plugins" "$HOME/.tmux/resurrect" 2>/dev/null || true
        echo "[tmux] 已移除旧 tpm/插件目录（纯配置模式）"
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
echo "[tmux] 完成。纯配置模式（无插件）"
