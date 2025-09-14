#!/bin/bash

# 切换到用户目录
cd ~ || exit

# 导入函数与变量
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/install.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Yunzai_pieces.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/github.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/init.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/update.sh")


# 安装和配置自定义脚本
function install_and_configure_scripts() {
    安装xrk脚本
    source /xrk/.init
    葵崽升级
}

# 主执行函数
function main() {
    确定系统安装器魔法
    install_package "git" 
    install_package "jq" 
    install_package "tmux"
    install_and_configure_scripts
    tmux配置检查
    profile配置检查
    ffmpeg配置检查
    双崽linux脚本升级
    echo "所有配置完成，即将进入窗口..."
    source $HOME/.profile
}

# 开始执行
main