#!/bin/bash
# 安装 tmux + tpm，链接配置，生成 ~/.tmux/xrk-menu
set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
# shellcheck source=/dev/null
[ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ] && source "$XRK_ROOT/shell_modules/bootstrap.sh"
xrk_ensure_bootstrap
# shellcheck source=/dev/null
source "$XRK_ROOT/shell_modules/xrk_base.sh"
xrk_加载底层 install
safe_source "shell_modules/github.sh"

# name|git_url（与 body/.tmux.conf 中 @plugin 对应）
XRK_TMUX_PLUGIN_REPOS=(
    "tmux-sensible|https://github.com/tmux-plugins/tmux-sensible.git"
    "tmux-resurrect|https://github.com/tmux-plugins/tmux-resurrect.git"
    "tmux-continuum|https://github.com/tmux-plugins/tmux-continuum.git"
    "tmux-yank|https://github.com/tmux-plugins/tmux-yank.git"
    "tmux-open|https://github.com/tmux-plugins/tmux-open.git"
    "tmux-prefix-highlight|https://github.com/tmux-plugins/tmux-prefix-highlight.git"
)

install_tmux_pkg() {
    if command -v tmux &>/dev/null; then
        echo "[tmux] 已安装: $(tmux -V)"
        return 0
    fi
    echo "[tmux] 安装 tmux…"
    安装系统包 "tmux" 2>/dev/null || install_package "tmux" 2>/dev/null || 确保命令 tmux tmux
}

install_clipboard_tools() {
    command -v xclip &>/dev/null || command -v xsel &>/dev/null || command -v wl-copy &>/dev/null \
        && return 0
    echo "[tmux] 安装剪贴板工具 xclip…"
    安装系统包 "xclip" 2>/dev/null || install_package "xclip" 2>/dev/null || true
}

_tmux_fix_github_remote() {
    local dir="$1" url="$2" cur clean want
    [ -d "$dir/.git" ] || return 0
    cur=$(git -C "$dir" remote get-url origin 2>/dev/null) || return 0
    clean=$(xrk_clean_github_url "$cur")
    want=$(xrk_clean_github_url "$url")
    [ "$clean" = "$want" ] && return 0
    git -C "$dir" remote set-url origin "$want"
}

setup_tpm() {
    mkdir -p "$HOME/.tmux/plugins"
    if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
        rm -rf "$HOME/.tmux/plugins/tpm"
        echo "[tmux] 安装 tpm…"
        xrk_git_clone "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"
    else
        _tmux_fix_github_remote "$HOME/.tmux/plugins/tpm" "https://github.com/tmux-plugins/tpm.git"
        (cd "$HOME/.tmux/plugins/tpm" && git pull --rebase --autostash) 2>/dev/null || true
    fi
    chmod -R 755 "$HOME/.tmux/plugins" 2>/dev/null || true
}

link_conf() {
    local main="$XRK_ROOT/body/.tmux.conf"
    local entry="$HOME/.tmux.conf"
    local mouse_conf="$HOME/.tmux/xrk-mouse.conf"
    [ -f "$main" ] || { echo "[tmux] 未找到 body/.tmux.conf"; return 1; }
    install_menu_wrapper
    cat > "$entry" << EOF
# 向日葵 tmux 入口（setup 生成，含绝对路径）
source-file $main
source-file $mouse_conf
EOF
    echo "[tmux] 已写入 $entry"
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
# 由 xrk-tmux --setup 生成（绝对路径，避免 tmux 内 HOME 为空）
bind ? run-shell '$menu help'
bind -n MouseDown3Pane if-shell -F -t = "#{mouse_any_flag}" "send-keys -M" "run-shell '$menu pane'"
bind -n MouseDown3StatusLeft run-shell '$menu session'
bind -n M-MouseDown3StatusLeft run-shell '$menu session'
bind -n MouseDown3Status run-shell '$menu window'
bind -n MouseDown3StatusRight run-shell '$menu system'
EOF
    echo "[tmux] 已安装 $menu"
    echo "[tmux] 已安装 $mouse_conf"
}

_ensure_tpm_plugin() {
    local name="$1" repo="$2"
    local dest="$HOME/.tmux/plugins/$name"
    if [ -d "$dest/.git" ]; then
        _tmux_fix_github_remote "$dest" "$repo"
        return 0
    fi
    echo "[tmux] git 克隆插件 $name…"
    rm -rf "$dest"
    xrk_git_clone "$repo" "$dest" || {
        echo "[tmux] 插件 $name 克隆失败: $repo" >&2
        return 1
    }
}

install_plugins() {
    local entry name repo failed=0
    local total="${#XRK_TMUX_PLUGIN_REPOS[@]}"
    local dir="$HOME/.tmux/resurrect" sz

    # 已下架/已移除插件残留
    rm -rf "$HOME/.tmux/plugins/tmux-mem" "$HOME/.tmux/plugins/tmux-fzf" "$HOME/.tmux/plugins/tmux-cpu" 2>/dev/null || true

    if [ -d "$dir" ]; then
        sz=$(du -sm "$dir" 2>/dev/null | cut -f1)
        if [ "${sz:-0}" -gt 20 ]; then
            rm -rf "${dir:?}"/*
            echo "[tmux] 已清理 resurrect 缓存 (${sz}MB)，避免进入桌面时卡死"
        fi
    fi

    echo "[tmux] 安装/校验插件（共 ${total} 个）…"

    for entry in "${XRK_TMUX_PLUGIN_REPOS[@]}"; do
        name="${entry%%|*}"
        repo="${entry#*|}"
        _ensure_tpm_plugin "$name" "$repo" || failed=$((failed + 1))
    done

    if [ "$failed" -gt 0 ]; then
        echo "[tmux] ${failed} 个插件克隆失败，请重试: xrk-tmux --setup" >&2
        return 1
    fi
    echo "[tmux] 插件安装完成"
    return 0
}

install_tmux_pkg
install_clipboard_tools
setup_tpm
link_conf
install_plugins || true
echo "[tmux] 完成。进入桌面: xrk-tmux | 检查: xrk-tmux --status"
