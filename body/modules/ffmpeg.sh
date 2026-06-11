#!/bin/bash
# ffmpeg 安装入口（委托 project-install/software/ffmpeg）
command -v ffmpeg &>/dev/null && { echo "[ffmpeg] 已安装: $(ffmpeg -version | head -1)"; exit 0; }
# shellcheck source=/dev/null
source "${XRK_ROOT:-/xrk}/shell_modules/software_head.sh"
xrk_run_script "project-install/software/ffmpeg"
