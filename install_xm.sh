#!/bin/bash
# 安装 xm 到 bin：换源、安装 Git、克隆脚本仓库、安装云崽 的统一入口
# 参数：1=GitCode 2=GitHub 3=Gitee（默认 3）

XRK_SOURCE="${1:-3}"
# 与 bootstrap 一致：用 get_base_from_arg / get_clone_from_raw 统一换源逻辑（首跳按 XRK_SOURCE 选源）
if [ -f /xrk/shell_modules/bootstrap.sh ]; then
    source /xrk/shell_modules/bootstrap.sh
else
    case "${XRK_SOURCE#-}" in
        1) _BOOT_BASE="https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master" ;;
        2) _BOOT_BASE="https://raw.githubusercontent.com/sunflowermm/xrk-projects-scripts/master" ;;
        3|*) _BOOT_BASE="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master" ;;
    esac
    source <(curl -sL "${_BOOT_BASE}/shell_modules/bootstrap.sh")
fi
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-$(get_base_from_arg "$XRK_SOURCE")}"
SCRIPT_CLONE_URL="${SCRIPT_CLONE_URL:-$(get_clone_from_raw "$SCRIPT_RAW_BASE")}"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL

# 落盘供 xm 使用（xm 运行时可能尚无 /xrk）
mkdir -p "$HOME/.config"
cat > "$HOME/.xrk_repo" << EOF
SCRIPT_RAW_BASE="$SCRIPT_RAW_BASE"
SCRIPT_CLONE_URL="$SCRIPT_CLONE_URL"
EOF

# 无 curl 时需先安装（无 common 无法用 ensure_cmd）
if ! command -v curl &>/dev/null; then
    echo "[xm] 安装 curl..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y curl
    elif command -v yum &>/dev/null; then
        yum install -y curl
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm curl
    else
        echo "请先安装 curl"; exit 1
    fi
fi
# shellcheck source=/dev/null
source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
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
curl -sL "$SCRIPT_RAW_BASE/body/xm" -o "$XM_DEST" && chmod +x "$XM_DEST" || {
    echo "xm 下载失败"
    exit 1
}

echo "[xm] 安装完成，输入 xm 启动"
exec "$XM_DEST"
