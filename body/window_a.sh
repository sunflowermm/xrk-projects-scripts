#!/bin/bash
# tmux 窗格：显示葵崽(XRK-Yunzai)与向日葵命令（需 .init 提供 caidan/bg）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/window_head.sh"

cd /root
yz="$(xrk_yz_dir)"
if [ -n "$yz" ] && [ -d "$yz" ]; then
    echo -e "${caidan1}葵崽启动命令为 xyz${bg}"
    echo -e "${caidan3}重新配置账号命令为 xyzlogin${bg}"
fi
echo -e "${caidan2}启动向日葵脚本命令为 xrk${bg}"
echo -e "${caidan1}向日葵软件包命令为 xrkk${bg}"
if [ -d "/opt/QQ" ]; then
    echo -e "${caidan3}输入 nt 启动 ncqq 客户端${bg}"
fi