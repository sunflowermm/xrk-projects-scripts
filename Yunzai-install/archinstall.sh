#!/bin/bash
# 导入函数与变量
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/color.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Yunzai_pieces.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/install.sh")
确定系统安装器魔法

# 检查是否为 Arch Linux 系统
if [ ! -f /etc/arch-release ]; then
    echo -e "${color_red}此脚本仅适用于 Arch Linux 系统${reset_color}"
    exit 1
else
    echo -e "${color_light_green}系统为 Arch Linux${reset_color}"
fi

# 更新系统
echo -e "${color_light_blue}更新系统软件包...${reset_color}"
if pacman -Syu --noconfirm; then
    echo -e "${color_light_green}系统更新完成${reset_color}"
else
    echo -e "${color_red}系统更新失败，请重新运行脚本${reset_color}"
    exit 1
fi

bash <(curl -sL https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/software/yq)
# 安装基本工具
for package in git wget tar xz jq go-yq sudo nodejs-lts-iron npm redis wqy-bitmapfont wqy-zenhei ttf-arphic-ukai ttf-arphic-uming; do
    install_package "$package"
done

# 安装脚本
安装xrk脚本

# 删除云崽（如果存在）
检测云崽存在魔法

# 下载 Node 和 npm
检测npm-node-pnpm安装

# 检查和安装 Chromium
if ! command -v chromium &>/dev/null; then
    echo -e "${color_light_blue}开始安装 Chromium，请耐心等待...${reset_color}"
    if pacman -S --noconfirm chromium; then
        echo -e "${color_light_green}Chromium 安装成功${reset_color}"
    else
        echo -e "${color_red}Chromium 安装失败${reset_color}"
        exit 1
    fi
else
    echo -e "${color_light_green}Chromium 已安装${reset_color}"
fi

# 启动 Redis
检测redis安装

# 提供安装选项
云崽安装菜单