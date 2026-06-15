#!/bin/bash
# 安装 tmux，写入 ~/.tmux.conf（纯 conf，无插件）
set -e
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"

link_conf() {
    local root_abs main menus_tpl menus_out entry menu_cmd
    root_abs="$(cd "$XRK_ROOT" 2>/dev/null && pwd)" || root_abs="$XRK_ROOT"
    main="${root_abs}/body/tmux.conf"
    menus_tpl="${root_abs}/body/tmux-menus.conf"
    entry="$HOME/.tmux.conf"
    menus_out="$HOME/.tmux/xrk-menus.conf"
    menu_cmd="bash ${root_abs}/body/tmux-menu.sh"

    [ -f "$main" ] && [ -f "$menus_tpl" ] || {
        echo "[tmux] 缺少 body/tmux.conf 或 body/tmux-menus.conf" >&2
        return 1
    }

    mkdir -p "$HOME/.tmux"
    sed "s|@XRK_MENU@|${menu_cmd}|g" "$menus_tpl" > "$menus_out"
    {
        echo "# 向日葵 tmux（xrk-tmux --setup 生成）"
        cat "$main"
        echo ""
        echo "source-file ${menus_out}"
    } > "$entry"
    echo "[tmux] 已写入 $entry"
}

install_tmux_pkg() {
    command -v tmux &>/dev/null && {
        echo "[tmux] 已安装: $(tmux -V)"
        return 0
    }
    echo "[tmux] 安装 tmux…"
    if command -v apt-get &>/dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq tmux
    elif command -v dnf &>/dev/null; then
        dnf install -y -q tmux
    elif command -v yum &>/dev/null; then
        yum install -y -q tmux
    else
        echo "[tmux] 请手动安装 tmux" >&2
        return 1
    fi
    echo "[tmux] 已安装: $(tmux -V)"
}

case "${1:-}" in
    --link-only) link_conf; exit 0 ;;
esac

rm -rf "$HOME/.tmux/plugins" "$HOME/.tmux/resurrect" 2>/dev/null || true
rm -f "$HOME/.tmux/xrk-mouse.conf" "$HOME/.tmux/xrk-menu" 2>/dev/null || true
install_tmux_pkg
link_conf
echo "[tmux] 完成"
