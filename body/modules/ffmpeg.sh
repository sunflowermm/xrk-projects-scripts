#!/bin/bash
# 独立模块：安装 ffmpeg（支持远程/本地执行，供环境与模块调用）

command -v ffmpeg &>/dev/null && { echo "[ffmpeg] 已安装: $(ffmpeg -version | head -1)"; exit 0; }
XRK_ROOT="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
if [ -f "$XRK_ROOT/shell_modules/menu_common.sh" ]; then
    source "$XRK_ROOT/shell_modules/menu_common.sh"
elif [ -f "$XRK_ROOT/shell_modules/repo_source.sh" ]; then
    source "$XRK_ROOT/shell_modules/repo_source.sh"
fi

if type run_software &>/dev/null; then
    run_software "project-install/software/ffmpeg"
else
    if [ -f "$XRK_ROOT/project-install/software/ffmpeg" ]; then
        bash "$XRK_ROOT/project-install/software/ffmpeg"
    else
        bash <(curl -sL "${SCRIPT_RAW_BASE}/project-install/software/ffmpeg")
    fi
fi
echo "[ffmpeg] 安装完成"
