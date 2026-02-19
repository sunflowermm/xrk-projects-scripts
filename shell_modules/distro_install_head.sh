#!/bin/bash
# 各发行版安装脚本公共头部：加载依赖、日志、确定安装器
# 用法：source 本文件后执行发行版特有逻辑

SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
if [ -f /xrk/shell_modules/bootstrap.sh ]; then
    source /xrk/shell_modules/bootstrap.sh
else
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/bootstrap.sh")
fi
load_distro_deps
确定系统安装器魔法
