#!/bin/bash
# 独立模块：仅写入 .profile 所需行（xrk 环境与 puppeteer）
# 可单独执行：bash $XRK_ROOT/body/modules/profile.sh
XRK_ROOT="${XRK_ROOT:-/xrk}"
[ -d "$XRK_ROOT" ] || { echo "请先安装脚本仓库到 $XRK_ROOT"; exit 1; }

profile="$HOME/.profile"
needed=(
    "[[ -f $XRK_ROOT/.init ]] && source $XRK_ROOT/.init"
    "export PUPPETEER_SKIP_DOWNLOAD='true'"
)
[ -f "$profile" ] || touch "$profile"
for line in "${needed[@]}"; do
    grep -Fxq "$line" "$profile" || echo "$line" >> "$profile"
done
echo "[profile] 已写入 $profile"
