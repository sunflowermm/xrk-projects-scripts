#!/bin/bash
# 拆那人活着好累啊，还是中文好

function 安装云崽机器人魔法() {
    # 检查是否在 Termux 环境中运行
    if [ -n "$TERMUX_VERSION" ]; then
        echo "检测到 Termux 环境"
        # 使用 while 循环确保用户输入有效选项
        while true; do
            read -p "请选择系统（Ubuntu(1) 或 Debian(2)）: " choice
            case $choice in
                Ubuntu|ubuntu|1)
                    curl -o xrk.sh https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Termux-container/xrk.sh && bash xrk.sh --ubuntu
                    break
                    ;;
                Debian|debian|2)
                    curl -o xrk.sh https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Termux-container/xrk.sh && bash xrk.sh --debian
                    break
                    ;;
                *)
                    echo "无效的选择，请输入 Ubuntu 或 Debian。"
                    ;;
            esac
        done
    else
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
    fi
}

# 调用函数执行安装
安装云崽机器人魔法