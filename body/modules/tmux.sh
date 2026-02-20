#!/bin/bash
# 独立模块：安装并配置 tmux（oh-my-tmux + tpm + 脚本自带 .tmux.conf）
# 可单独执行：bash $XRK_ROOT/body/modules/tmux.sh 或 xrk-tmux

set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -d "$XRK_ROOT" ] || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }

install_tmux_pkg() {
    if command -v tmux &>/dev/null; then
        echo "[tmux] 已安装: $(tmux -V)"
        return 0
    fi
    echo "[tmux] 安装 tmux 包..."
    [ -f "$XRK_ROOT/shell_modules/install.sh" ] && source "$XRK_ROOT/shell_modules/install.sh"
    install_package "tmux" 2>/dev/null || true
    command -v tmux &>/dev/null || { [ -f "$XRK_ROOT/shell_modules/common.sh" ] && source "$XRK_ROOT/shell_modules/common.sh" && ensure_cmd tmux tmux; }
}

git_clone_gh() {
    local url="$1" dest="$2"
    [ -f "$XRK_ROOT/shell_modules/github.sh" ] && source "$XRK_ROOT/shell_modules/github.sh"
    type git &>/dev/null || { echo "[tmux] 未找到 git"; return 1; }
    # 国内时区：git() 函数会自动处理（不加代理，保持原样）
    # 国外时区：保持原样
    git clone --depth=1 "$url" "$dest"
}

setup_oh_my_tmux() {
    if [ ! -d "$HOME/.tmux" ]; then
        echo "[tmux] 克隆 oh-my-tmux..."
        git_clone_gh "https://github.com/gpakosz/.tmux.git" "$HOME/.tmux"
    fi
}

setup_tpm() {
    mkdir -p "$HOME/.tmux/plugins"
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "[tmux] 安装 tpm..."
        git_clone_gh "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"
    else
        [ -f "$XRK_ROOT/shell_modules/github.sh" ] && source "$XRK_ROOT/shell_modules/github.sh"
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
setup_oh_my_tmux
setup_tpm
link_conf
echo "[tmux] 配置完成。运行 tmux 启动；若已在 tmux 内，按 prefix+r 重载配置。"
