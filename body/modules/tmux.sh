#!/bin/bash
# 安装并配置 tmux（oh-my-tmux + tpm + .tmux.conf 链接）
set -e
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/xrk_boot.sh" ] && source "$root/shell_modules/xrk_boot.sh"
xrk_ensure_bootstrap
xrk_prepare_root
load_module "shell_modules/common.sh"
load_module "shell_modules/install.sh"
safe_source "shell_modules/github.sh"

install_tmux_pkg() {
    if command -v tmux &>/dev/null; then
        echo "[tmux] 已安装: $(tmux -V)"
        return 0
    fi
    echo "[tmux] 安装 tmux 包..."
    安装系统包 "tmux" 2>/dev/null || install_package "tmux" 2>/dev/null || 确保命令 tmux tmux
}

setup_oh_my_tmux() {
    if [ ! -d "$HOME/.tmux" ]; then
        echo "[tmux] 克隆 oh-my-tmux..."
        xrk_git_clone "https://github.com/gpakosz/.tmux.git" "$HOME/.tmux"
    fi
}

setup_tpm() {
    mkdir -p "$HOME/.tmux/plugins"
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[tmux] 安装 tpm..."
        xrk_git_clone "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"
    else
        (cd "$HOME/.tmux/plugins/tpm" && git pull --rebase --autostash)
    fi
    chmod -R 755 "$HOME/.tmux/plugins" 2>/dev/null || true
}

link_conf() {
    xrk_ensure_repo_file "body/.tmux.conf" || { echo "[tmux] 无法获取 body/.tmux.conf"; return 1; }
    ln -sf "$XRK_ROOT/body/.tmux.conf" "$HOME/.tmux.conf"
    echo "[tmux] 已链接 ~/.tmux.conf -> $XRK_ROOT/body/.tmux.conf"
}

install_tmux_pkg
[ "${XRK_TMUX_PKG_ONLY:-0}" = "1" ] && exit 0
setup_oh_my_tmux
setup_tpm
link_conf
if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    echo "[tmux] 安装/更新 tpm 插件（含 resurrect、continuum）..."
    bash "$HOME/.tmux/plugins/tpm/bin/install_plugins" 2>/dev/null || true
fi
echo "[tmux] 配置完成。运行 xrk-tmux 进入已有会话；Alt+Space+d 可 detach。"
