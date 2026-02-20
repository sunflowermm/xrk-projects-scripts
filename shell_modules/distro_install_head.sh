#!/bin/bash
# 各发行版安装脚本公共头部：加载依赖、日志、确定安装器（供 project-install/Yunzai/* 等调用）
root="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
if [ -f "$root/shell_modules/bootstrap.sh" ]; then
    source "$root/shell_modules/bootstrap.sh"
else
    source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/bootstrap.sh")
fi
load_distro_deps

run_yq() {
    [ -f "$root/project-install/software/yq" ] && bash "$root/project-install/software/yq" || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/yq")
}
run_chromium() {
    [ -f "$root/project-install/software/chromium" ] && bash "$root/project-install/software/chromium" || bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/chromium")
}
