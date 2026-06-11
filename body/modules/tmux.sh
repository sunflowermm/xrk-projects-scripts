#!/bin/bash
# 安装并配置 tmux（oh-my-tmux + tpm + .tmux.conf 链接）
# 安装：xrk-tmux-setup 或 bash $XRK_ROOT/body/modules/tmux.sh
# 进入会话（恢复已有）：xrk-tmux 或 bash $XRK_ROOT/body/tmux.sh
# 仅装包：XRK_TMUX_PKG_ONLY=1 bash .../tmux.sh

set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
[ -d "$XRK_ROOT" ] || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }

# shellcheck source=/dev/null
if [ -f "${XRK_ROOT}/shell_modules/xrk_base.sh" ]; then
    source "${XRK_ROOT}/shell_modules/xrk_base.sh"
    xrk_加载底层 install
elif type xrk_ensure_bootstrap &>/dev/null || [ -f "${XRK_ROOT}/shell_modules/bootstrap.sh" ]; then
    [ -f "${XRK_ROOT}/shell_modules/bootstrap.sh" ] && source "${XRK_ROOT}/shell_modules/bootstrap.sh"
    xrk_ensure_bootstrap
    load_module "shell_modules/common.sh"
    load_module "shell_modules/install.sh"
else
    echo "[tmux] 缺少 $XRK_ROOT/shell_modules/bootstrap.sh，请先 xm→2 安装或 git pull"
    exit 1
fi
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
    [ -f "$XRK_ROOT/body/.tmux.conf" ] || { echo "[tmux] 未找到 $XRK_ROOT/body/.tmux.conf"; return 1; }
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
