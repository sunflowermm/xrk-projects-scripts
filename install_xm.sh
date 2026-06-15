#!/bin/bash
# 安装 xm 到 bin：换源、安装 Git、克隆脚本仓库
# 参数：1=GitCode 2=GitHub 3=Gitee auto=按区域自动（国内 Gitee，海外 GitHub）

XRK_SOURCE="${1:-auto}"
XRK_ROOT="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
if [ -f "$XRK_ROOT/shell_modules/xrk_boot.sh" ]; then
    source "$XRK_ROOT/shell_modules/xrk_boot.sh"
elif [ -f "$XRK_ROOT/shell_modules/bootstrap.sh" ]; then
    source "$XRK_ROOT/shell_modules/bootstrap.sh"
else
    tmp=$(mktemp "${TMPDIR:-/tmp}/xrk-bootstrap.XXXXXX") || exit 1
    curl -fsSL --connect-timeout 10 --max-time 30 \
        "https://gitee.com/xrkseek/xrk-projects-scripts/raw/master/shell_modules/bootstrap.sh" \
        -o "$tmp" || { rm -f "$tmp"; echo "bootstrap 下载失败"; exit 1; }
    source "$tmp"
    rm -f "$tmp"
fi
xrk_bootstrap "$XRK_SOURCE" 1

mkdir -p "$HOME/.config"
cat > "$HOME/.xrk_repo" << EOF
XRK_SOURCE="$XRK_SOURCE"
SCRIPT_RAW_BASE="$SCRIPT_RAW_BASE"
SCRIPT_CLONE_URL="$SCRIPT_CLONE_URL"
XRK_ROOT="$XRK_ROOT"
EOF

if [ -f "$XRK_ROOT/shell_modules/xrk_base.sh" ]; then
    # shellcheck source=/dev/null
    source "$XRK_ROOT/shell_modules/xrk_base.sh"
    xrk_加载底层 common
else
    load_module "shell_modules/xrk_base.sh" 2>/dev/null \
        && xrk_加载底层 common 2>/dev/null \
        || load_module "shell_modules/common.sh"
fi
ensure_curl || { echo "请先安装 curl"; exit 1; }
ensure_cmd git git

# 下载 xm 并安装到 bin
XM_DEST=""
if [ -w /usr/local/bin ]; then
    XM_DEST="/usr/local/bin/xm"
elif [ -d "$HOME/bin" ] && [ -w "$HOME/bin" ]; then
    XM_DEST="$HOME/bin/xm"
else
    mkdir -p "$HOME/bin"
    XM_DEST="$HOME/bin/xm"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || true
fi

echo "[xm] 正在安装 xm 到 $XM_DEST ..."
xrk_download "$SCRIPT_RAW_BASE/body/xm" "$XM_DEST" 3 && chmod +x "$XM_DEST" || {
    echo "xm 下载失败"
    exit 1
}

echo "[xm] 安装完成。"
echo "[xm] 请输入 xm 启动主菜单。"
