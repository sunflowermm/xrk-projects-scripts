#!/bin/bash
# tmux 窗格：复制提示（需 .init 提供 caidan/bg）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/window_head.sh"

echo -e "${caidan1}• 复制: ${caidan3}鼠标拖选 / Vi 模式按 y${bg}"
echo -e "${caidan2}• 右键: 窗格 / 窗口栏 / 左下角「新年快乐」均有中文菜单${bg}"

