#!/bin/bash
# 集中路径与默认源，避免硬编码；供 bootstrap / .init / 各模块 使用
# 仅定义常量，不 source 其他脚本

XRK_ROOT="${XRK_ROOT:-/xrk}"
XRK_BIN="${XRK_BIN:-/usr/local/bin}"
_XRK_DEFAULT_RAW_BASE="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master"
_XRK_DEFAULT_CLONE="https://gitcode.com/Xrkseek/xrk-projects-scripts.git"
YZ_DEFAULT_NAME="XRK-Yunzai"
YZ_DEFAULT_DIR="${HOME}/${YZ_DEFAULT_NAME}"

export XRK_ROOT XRK_BIN YZ_DEFAULT_NAME YZ_DEFAULT_DIR
