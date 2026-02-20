#!/bin/bash
# 独立模块：安装 uv + Python（可选依赖 XRK_ROOT）

UV_INSTALL_URL="https://astral.sh/uv/install.sh"
root="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
[ -f "$root/shell_modules/versions.sh" ] && source "$root/shell_modules/versions.sh" || source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/versions.sh" 2>/dev/null)
PYTHON_VERSION="${UV_PYTHON_VERSION:-${PYTHON_LTS_VERSION:-3.12}}"
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:$PATH"

if [ -f "$root/shell_modules/common.sh" ]; then
    source "$root/shell_modules/common.sh"
else
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/common.sh")
fi
ensure_cmd curl curl

if ! command -v uv &>/dev/null; then
    echo "[uv] 正在安装..."
    curl -LsSf "$UV_INSTALL_URL" | sh
fi
command -v uv &>/dev/null || { echo "[uv] 安装失败"; exit 1; }
echo "[uv] $(uv --version)"

echo "[python] 确保 $PYTHON_VERSION..."
uv python install "$PYTHON_VERSION"
echo "[python_uv] 完成。使用: uv run python 或 uv venv"
