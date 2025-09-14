#!/bin/bash
#拆那人活着好累啊，还是中文好
function 确定系统安装器魔法() {
    if grep -Eqi "Ubuntu" /etc/issue && grep -Eq "Ubuntu" /etc/*-release; then
        source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Linux/debian-and-ubuntu_install.sh")
    elif grep -Eqi "Debian" /etc/issue && grep -Eq "Debian" /etc/*-release; then
        source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Linux/debian-and-ubuntu_install.sh")
    elif [ -f /etc/arch-release ]; then
        source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Linux/arch_install.sh")
    elif grep -Eqi "CentOS|Red Hat" /etc/issue && grep -Eq "CentOS|Red Hat" /etc/*-release; then
        source <(curl -sL "https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/shell_modules/Linux/centos_install.sh")
    else
        echo "无法识别的系统类型，脚本退出。"
        exit 1
    fi
}