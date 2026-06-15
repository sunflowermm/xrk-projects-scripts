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

# name|git_url|core|optional（与 body/.tmux.conf 中 @plugin 对应）
XRK_TMUX_PLUGIN_REPOS=(
    "tmux-sensible|https://github.com/tmux-plugins/tmux-sensible.git|core"
    "tmux-resurrect|https://github.com/tmux-plugins/tmux-resurrect.git|core"
    "tmux-continuum|https://github.com/tmux-plugins/tmux-continuum.git|core"
    "tmux-yank|https://github.com/tmux-plugins/tmux-yank.git|core"
    "tmux-cpu|https://github.com/tmux-plugins/tmux-cpu.git|core"
    "tmux-open|https://github.com/tmux-plugins/tmux-open.git|core"
    "tmux-prefix-highlight|https://github.com/tmux-plugins/tmux-prefix-highlight.git|core"
    "tmux-mem|https://github.com/tmux-plugins/tmux-mem.git|optional"
    "tmux-fzf|https://github.com/sainnhe/tmux-fzf.git|optional"
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

install_fzf_if_missing() {
    command -v fzf &>/dev/null && return 0
    echo "[tmux] 安装 fzf（tmux-fzf 依赖）…"
    安装系统包 "fzf" 2>/dev/null || install_package "fzf" 2>/dev/null || true
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
    [ -f "$XRK_ROOT/body/.tmux.conf" ] || { echo "[tmux] 未找到 body/.tmux.conf"; return 1; }
    ln -sf "$XRK_ROOT/body/.tmux.conf" "$HOME/.tmux.conf"
    echo "[tmux] 已链接 ~/.tmux.conf"
}

install_menu_wrapper() {
    mkdir -p "$HOME/.tmux"
    cat > "$HOME/.tmux/xrk-menu" << EOF
#!/bin/bash
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
XRK_ROOT="${XRK_ROOT:-/xrk}"
exec bash "\$XRK_ROOT/body/tmux-menu.sh" "\$@"
EOF
    chmod +x "$HOME/.tmux/xrk-menu"
    echo "[tmux] 已安装 $HOME/.tmux/xrk-menu"
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
    local entry name repo tier failed_core=0 failed_opt=0
    local total="${#XRK_TMUX_PLUGIN_REPOS[@]}"

    install_fzf_if_missing

    echo "[tmux] 安装/校验插件（共 ${total} 个，git 克隆可能需 1～2 分钟）…"

    for entry in "${XRK_TMUX_PLUGIN_REPOS[@]}"; do
        name="${entry%%|*}"
        repo="${entry#*|}"
        repo="${repo%%|*}"
        tier="${entry##*|}"
        if _ensure_tpm_plugin "$name" "$repo"; then
            continue
        fi
        if [ "$tier" = "optional" ]; then
            failed_opt=$((failed_opt + 1))
            echo "[tmux] 可选插件 $name 未装成（不影响进入桌面）" >&2
        else
            failed_core=$((failed_core + 1))
        fi
    done

    if [ "$failed_core" -gt 0 ]; then
        echo "[tmux] ${failed_core} 个核心插件克隆失败，请重试: xrk-tmux --setup" >&2
        return 1
    fi
    if [ "$failed_opt" -gt 0 ]; then
        echo "[tmux] ${failed_opt} 个可选插件未装成（mem/fzf），可稍后 xrk-tmux --setup 重试" >&2
    else
        echo "[tmux] 插件安装完成"
    fi
    return 0
}

install_tmux_pkg
install_clipboard_tools
setup_tpm
link_conf
install_menu_wrapper
install_plugins || true
echo "[tmux] 完成。进入桌面: xrk-tmux | 检查: xrk-tmux --status"
