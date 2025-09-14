#!/bin/bash
# 导入函数与变量
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/color.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Yunzai_pieces.sh")
source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/install.sh")
确定系统安装器魔法

# 更新系统
echo -e "${color_light_blue}正在更新系统软件包...${reset_color}"
if apt update && apt upgrade -y; then
    echo -e "${color_light_green}系统更新完成${reset_color}"
else
    echo -e "${color_red}系统更新失败，请重新运行脚本${reset_color}"
    exit 1
fi

bash <(curl -sL https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/software/yq)
# 安装基本工具
for package in git wget tar dialog xz-utils jq redis sudo tmux fonts-wqy*; do
    install_package "$package"
done

# 安装脚本
安装xrk脚本

# 删除云崽（如果存在）
检测云崽存在魔法

# 下载 Node 和 npm
检测npm-node-pnpm安装

# 检查浏览器
echo -e "${color_light_blue}开始检查 Chromium ${reset_color}"
bash <(curl https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/software/chromium)

# 启动 Redis
检测redis安装

# 提供 menu
云崽安装菜单