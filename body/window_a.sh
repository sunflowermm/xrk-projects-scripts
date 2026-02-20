#!/bin/bash
# tmux 窗格：显示葵崽(XRK-Yunzai)与向日葵命令（需 .init 提供 caidan/bg）
root="${XRK_ROOT:-/xrk}"
[ -f "$root/.init" ] && source "$root/.init"
source "$root/shell_modules/init.sh"
check_changes
search_directories

cd /root
yz="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}"
if [ -n "$yz" ] && [ -d "$yz" ]; then
    echo -e "${caidan1}葵崽启动命令为 xyz${bg}"
    echo -e "${caidan3}重新配置账号命令为 xyzlogin${bg}"
fi
echo -e "${caidan2}启动向日葵脚本命令为 xrk${bg}"
echo -e "${caidan1}向日葵软件包命令为 xrkk${bg}"
if [ -d "/opt/QQ" ]; then
    echo -e "${caidan3}输入 nt 启动 ncqq 客户端${bg}"
fi