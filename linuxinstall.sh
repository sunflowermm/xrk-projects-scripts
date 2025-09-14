#!/bin/bash
#拆那人活着好累啊，还是中文好
function 安装云崽机器人魔法() {
    if grep -Eqi "Ubuntu" /etc/issue && grep -Eq "Ubuntu" /etc/*-release; then
        bash <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/ubuntuinstall.sh")
    elif grep -Eqi "Debian" /etc/issue && grep -Eq "Debian" /etc/*-release; then
        bash <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/debianinstall.sh")
    elif [ -f /etc/arch-release ]; then
        bash <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/archinstall.sh")
    elif grep -Eqi "CentOS|Red Hat" /etc/issue && grep -Eq "CentOS|Red Hat" /etc/*-release; then
        bash <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/centosinstall.sh")
    else
        echo "无法识别的系统类型，脚本退出。"
        exit 1
    fi
}

安装云崽机器人魔法