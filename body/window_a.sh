#!/bin/bash
# tmux 窗格：显示葵崽(XRK-Yunzai)与向日葵命令（需 .init 提供 caidan/bg）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/window_head.sh"

cd /root
yz="$(xrk_yz_dir)"
agt="$(xrk_agt_dir)"
if [ -n "$yz" ] && [ -d "$yz" ]; then
    echo -e "${caidan1}葵崽启动命令为 xyz${bg}"
    echo -e "${caidan3}重新配置账号命令为 xyzlogin${bg}"
fi
if [ -n "$agt" ] && [ -d "$agt" ]; then
    echo -e "${caidan2}葵子启动命令为 xag${bg}"
fi
echo -e "${caidan2}主菜单: xrk  工具箱: xrkk sync|menu|path${bg}"
if [ -d "/opt/QQ" ]; then
    echo -e "${caidan3}输入 nt 启动 ncqq 客户端${bg}"
fi