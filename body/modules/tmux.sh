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
    local dir="$1" url="$2" cur
    [ -d "$dir/.git" ] || return 0
    cur=$(git -C "$dir" remote get-url origin 2>/dev/null) || return 0
    [ "$cur" = "$url" ] && return 0
    git -C "$dir" remote set-url origin "$url"
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
    cat > "$HOME/.tmux/xrk-menu" << 'EOF'
#!/bin/bash
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
XRK_ROOT="${XRK_ROOT:-/xrk}"
exec bash "$XRK_ROOT/body/tmux-menu.sh" "$@"
EOF
    chmod +x "$HOME/.tmux/xrk-menu"
    echo "[tmux] 已安装 ~/.tmux/xrk-menu"
}

install_plugins() {
    local installer="$HOME/.tmux/plugins/tpm/bin/install_plugins"
    [ -x "$installer" ] || return 1
    echo "[tmux] 安装 tpm 插件…"
    if bash "$installer"; then
        echo "[tmux] 插件安装完成"
        return 0
    fi
    echo "[tmux] 插件安装部分失败，可稍后重试: bash $installer" >&2
    return 1
}

install_tmux_pkg
install_clipboard_tools
setup_tpm
link_conf
install_menu_wrapper
install_plugins || true
echo "[tmux] 完成。进入桌面: xrk-tmux | 检查: xrk-tmux --status"
