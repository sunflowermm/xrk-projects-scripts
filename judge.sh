#!/bin/bash

# 导入函数模块
source /xrk/shell_modules/init.sh

# 主逻辑
check_changes
search_directories

# 输出结果（仅在需要时打印）
if [[ -z "$tyz" && -z "$myz" ]]; then
    echo "未检测到云崽目录，正在展开后续安装或者安装失败"
else
    [[ -n "$tyz" ]] && echo "检测到时雨崽目录：$tyz"
    [[ -n "$myz" ]] && echo "检测到喵崽目录：$myz"
fi