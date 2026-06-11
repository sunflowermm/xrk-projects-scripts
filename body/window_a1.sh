#!/bin/bash
# tmux 窗格：复制提示（需 .init 提供 caidan/bg）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/window_head.sh"

echo -e "${caidan1}• 复制文本: ${caidan3}shift➕鼠标选择${bg}"

