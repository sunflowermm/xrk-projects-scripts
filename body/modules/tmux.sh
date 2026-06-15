#!/bin/bash
# 安装 tmux，写入 ~/.tmux.conf 与右键菜单（无 tpm/插件）
set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

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
    local main="$XRK_ROOT/body/.tmux.conf"
    local entry="$HOME/.tmux.conf"
    local mouse_conf="$HOME/.tmux/xrk-mouse.conf"
    [ -f "$main" ] || { echo "[tmux] 未找到 body/.tmux.conf" >&2; return 1; }
    install_menu_wrapper
    cat > "$entry" << EOF
# 向日葵 tmux 入口（xrk-tmux --setup 生成）
source-file $main
source-file $mouse_conf
EOF
    echo "[tmux] 已写入 $entry"
}

cleanup_legacy_plugins() {
    local removed=0
    for path in "$HOME/.tmux/plugins" "$HOME/.tmux/resurrect"; do
        [ -e "$path" ] || continue
        rm -rf "$path"
        removed=1
    done
    [ "$removed" = "1" ] && echo "[tmux] 已删除旧版 tpm 插件与 resurrect 数据"
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

cleanup_legacy_plugins
install_tmux_pkg
link_conf
echo "[tmux] 完成。进入桌面: xrk-tmux | 检查: xrk-tmux --status"
