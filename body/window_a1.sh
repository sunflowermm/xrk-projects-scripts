#!/bin/bash
# tmux 窗格：复制提示（需 .init 提供 caidan/bg）
[ -f /xrk/.init ] && source /xrk/.init
source /xrk/shell_modules/init.sh
source /xrk/shell_modules/github.sh
check_changes
search_directories

echo -e "${caidan1}• 复制文本: ${caidan3}shift➕鼠标选择${bg}"

