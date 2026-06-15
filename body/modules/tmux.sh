#!/bin/bash
# 安装 tmux + 插件，写入 ~/.tmux.conf（不含 tmux-yank）
set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

# 与 body/.tmux.conf 中 @plugin 一致
XRK_TMUX_PLUGIN_REPOS=(
    "tmux-sensible|https://github.com/tmux-plugins/tmux-sensible.git"
    "tmux-resurrect|https://github.com/tmux-plugins/tmux-resurrect.git"
    "tmux-continuum|https://github.com/tmux-plugins/tmux-continuum.git"
    "tmux-cpu|https://github.com/tmux-plugins/tmux-cpu.git"
    "tmux-open|https://github.com/tmux-plugins/tmux-open.git"
    "tmux-prefix-highlight|https://github.com/tmux-plugins/tmux-prefix-highlight.git"
)

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
    main="${root_abs}/body/.tmux.conf"
    entry="$HOME/.tmux.conf"
    mouse_conf="$HOME/.tmux/xrk-mouse.conf"
    [ -f "$main" ] || {
        echo "[tmux] 未找到主配置: $main" >&2
        echo "[tmux] 请确认仓库在 $root_abs 且已 git 同步" >&2
        return 1
    }
    install_menu_wrapper
    cat > "$entry" << EOF
# 向日葵 tmux 入口（xrk-tmux --setup 生成，勿手改路径）
source-file ${main}
source-file ${mouse_conf}
EOF
    echo "[tmux] 已写入 $entry"
    echo "[tmux]   → $main"
}

cleanup_removed_plugins() {
    rm -rf \
        "$HOME/.tmux/plugins/tmux-yank" \
        "$HOME/.tmux/plugins/tmux-mem" \
        "$HOME/.tmux/plugins/tmux-fzf" \
        2>/dev/null || true
    local dir="$HOME/.tmux/resurrect" sz
    if [ -d "$dir" ]; then
        sz=$(du -sm "$dir" 2>/dev/null | cut -f1)
        [ "${sz:-0}" -gt 50 ] && rm -rf "${dir:?}"/* && echo "[tmux] 已清理过大 resurrect 缓存 (${sz}MB)"
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

_setup_github() {
    # shellcheck source=/dev/null
    [ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ] && source "$XRK_ROOT/shell_modules/bootstrap.sh"
    xrk_ensure_bootstrap
    # shellcheck source=/dev/null
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
    safe_source "shell_modules/github.sh"
}

setup_tpm() {
    mkdir -p "$HOME/.tmux/plugins"
    if [ -d "$HOME/.tmux/plugins/tpm/.git" ]; then
        echo "[tmux]   tpm: 已有"
        return 0
    fi
    rm -rf "$HOME/.tmux/plugins/tpm"
    echo "[tmux] 安装 tpm…"
    if xrk_git_clone "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"; then
        echo "[tmux]   tpm: 完成"
        return 0
    fi
    echo "[tmux]   tpm: 失败（继续安装其它插件）" >&2
    return 1
}

_ensure_plugin() {
    local name="$1" repo="$2" dest="$HOME/.tmux/plugins/$name"
    if [ -d "$dest/.git" ]; then
        echo "[tmux]   $name: 已有"
        return 0
    fi
    if xrk_git_clone "$repo" "$dest"; then
        echo "[tmux]   $name: 完成"
        return 0
    fi
    echo "[tmux]   $name: 失败" >&2
    return 1
}

install_plugins() {
    local entry name repo failed=0 ok=0
    _setup_github
    type xrk_git_clone &>/dev/null || {
        echo "[tmux] github 模块未加载，无法克隆插件" >&2
        return 1
    }
    setup_tpm || failed=$((failed + 1))
    echo "[tmux] 安装插件（${#XRK_TMUX_PLUGIN_REPOS[@]} 个，不含 yank）…"
    for entry in "${XRK_TMUX_PLUGIN_REPOS[@]}"; do
        name="${entry%%|*}"
        repo="${entry#*|}"
        if _ensure_plugin "$name" "$repo"; then
            ok=$((ok + 1))
        else
            failed=$((failed + 1))
        fi
    done
    echo "[tmux] 插件结果: ${ok} 成功, ${failed} 失败"
    [ "$failed" -gt 0 ] && echo "[tmux] 失败项可重试: xrk-tmux --setup" >&2
    return 0
}

case "${1:-}" in
    --link-only)
        link_conf
        echo "[tmux] 已补写配置"
        exit 0
        ;;
esac

cleanup_removed_plugins
install_tmux_pkg
link_conf
install_plugins || true
echo "[tmux] 完成。已装: sensible/resurrect/continuum/cpu/open/样式 | 未装: yank"
