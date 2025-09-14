#!/bin/bash

# 定义常量
MAX_RETRIES=3
RETRY_COUNT=0

function install_package {
    local package_name="$1"
    
    if ! dpkg -s "$package_name" >/dev/null 2>&1; then
        echo -e "\033[0;34m正在安装 $package_name...\033[0m"
        if apt install -y "$package_name"; then
            echo -e "\033[0;32m$package_name 安装成功\033[0m"
        else
            echo -e "\033[0;31m$package_name 安装失败\033[0m"
            RETRY_COUNT=$((RETRY_COUNT + 1))
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo -e "\033[0;33m重试安装 $package_name...\033[0m"
                install_package "$package_name"
            else
                echo -e "\033[0;31m安装失败次数达到上限，退出脚本\033[0m"
                exit 1
            fi
        fi
    else
        echo -e "\033[0;32m$package_name 已安装，无需重复安装\033[0m"
    fi
}