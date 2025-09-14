#!/bin/bash

source /xrk/shell_modules/init.sh
source /xrk/shell_modules/github.sh
check_changes
search_directories

cd /root
if [ -n "$xyz" ]; then
   echo -e "${caidan1}葵崽启动命令为 xyz${bg}"
   echo -e "${caidan3}重新配置账号命令为 xyzlogin${bg}"
fi
if [ -n "$tyz" ]; then
   echo -e "${caidan1}笨比启动时雨崽命令为 tyz${bg}"
   echo -e "${caidan2}后台查看日志命令为 tyzlog${bg}"
   echo -e "${caidan3}停止时雨崽运行命令为 tyzstop${bg}"
fi
echo -e "${caidan2}启动向日葵脚本命令为 xrk${bg}"
echo -e "${caidan1}向日葵软件包命令为 xrkk${bg}"
if [ -d "/opt/QQ" ]; then
   echo -e "${caidan3}输入‘nt’启动 ncqq 客户端${bg}"
fi
if [ -d "/root/lagelan" ]; then
   echo -e "${caidan3}输入‘lg’启动 拉格朗日 客户端${bg}"
fi