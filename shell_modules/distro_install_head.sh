#!/bin/bash
# 各发行版安装脚本公共头部（project-install/Yunzai/*）

root="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
# shellcheck source=/dev/null
if [ -f "$root/shell_modules/xrk_base.sh" ]; then
    source "$root/shell_modules/xrk_base.sh"
    xrk_加载底层 distro
else
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/bootstrap.sh")
    xrk_ensure_bootstrap
    load_module "shell_modules/xrk_base.sh" && xrk_加载底层 distro 2>/dev/null \
        || { load_distro_deps; load_module "shell_modules/common.sh"; safe_source "shell_modules/yunzai_distro.sh"; }
fi

run_yq() { xrk_run_script "project-install/software/yq"; }
run_chromium() { xrk_run_script "project-install/software/chromium"; }
