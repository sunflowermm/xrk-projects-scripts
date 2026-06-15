#!/bin/bash
# 集中路径与默认源，避免硬编码；供 bootstrap / .init / 各模块 使用
# 仅定义常量，不 source 其他脚本
# 源编号：1=GitCode 2=GitHub 3=Gitee；未指定时 init_repo_source 按区域自动

XRK_ROOT="${XRK_ROOT:-/xrk}"
XRK_BIN="${XRK_BIN:-/usr/local/bin}"
_XRK_DEFAULT_RAW_BASE="https://gitee.com/xrkseek/xrk-projects-scripts/raw/master"
_XRK_DEFAULT_CLONE="https://gitee.com/xrkseek/xrk-projects-scripts.git"

# 葵崽 XRK-Yunzai（三仓库）
YZ_DEFAULT_NAME="XRK-Yunzai"
YZ_DEFAULT_DIR="${HOME}/${YZ_DEFAULT_NAME}"
YZ_REPO_GITCODE="https://gitcode.com/Xrkseek/XRK-Yunzai.git"
YZ_REPO_GITEE="https://gitee.com/xrkseek/XRK-Yunzai.git"
YZ_REPO_GITHUB="https://github.com/sunflowermm/XRK-Yunzai.git"
# 葵崽子仓库（插件，安装时额外克隆）
YZ_EXTRA_MIAO="plugins/miao-plugin|https://github.com/yoimiya-kokomi/miao-plugin.git"
YZ_EXTRA_GENSHIN="plugins/genshin|https://gitee.com/TimeRainStarSky/Yunzai-genshin.git"

# 葵子 XRK-AGT（三仓库）
AGT_DEFAULT_NAME="XRK-AGT"
AGT_DEFAULT_DIR="${HOME}/${AGT_DEFAULT_NAME}"
AGT_REPO_GITCODE="https://gitcode.com/Xrkseek/XRK-AGT.git"
AGT_REPO_GITEE="https://gitee.com/xrkseek/XRK-AGT.git"
AGT_REPO_GITHUB="https://github.com/sunflowermm/XRK-AGT.git"

# tmux 向日葵桌面
XRK_TMUX_SESSION="新年快乐"
XRK_TMUX_WINDOW_NAMES="来财 来福 来运"

export XRK_ROOT XRK_BIN
export XRK_TMUX_SESSION XRK_TMUX_WINDOW_NAMES
export YZ_DEFAULT_NAME YZ_DEFAULT_DIR
export YZ_REPO_GITCODE YZ_REPO_GITEE YZ_REPO_GITHUB
export AGT_DEFAULT_NAME AGT_DEFAULT_DIR
export AGT_REPO_GITCODE AGT_REPO_GITEE AGT_REPO_GITHUB
