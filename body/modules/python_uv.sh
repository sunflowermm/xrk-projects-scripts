#!/bin/bash
# 独立模块：安装 uv + Python
# shellcheck source=/dev/null
source "${XRK_ROOT:-/xrk}/shell_modules/software_head.sh"

UV_INSTALL_URL="https://astral.sh/uv/install.sh"
PYTHON_VERSION="${UV_PYTHON_VERSION:-${PYTHON_LTS_VERSION:-3.12}}"
export PATH="${HOME}/.local/bin:${HOME}/.cargo/bin:$PATH"

ensure_cmd curl curl

if ! command -v uv &>/dev/null; then
    echo "[uv] 正在安装..."
    curl -LsSf "$UV_INSTALL_URL" | sh
fi
command -v uv &>/dev/null || { echo "[uv] 安装失败"; exit 1; }
echo "[uv] $(uv --version)"

echo "[python] 确保 $PYTHON_VERSION..."
uv python install "$PYTHON_VERSION" 2>/dev/null || uv python pin "$PYTHON_VERSION" 2>/dev/null || true
echo "[python] 完成"
