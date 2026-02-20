#!/bin/bash
# Copyright (c) 2026 Xrkseek
# Licensed under MIT License
# 主流程依赖：克隆脚本/葵崽(XRK-Yunzai)、检测、安装 Node/pnpm、Redis、菜单
[ -f /xrk/shell_modules/xrk_config.sh ] 2>/dev/null && source /xrk/shell_modules/xrk_config.sh
XRK_ROOT="${XRK_ROOT:-/xrk}"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}"
[ -z "$SCRIPT_CLONE_URL" ] && type get_clone_from_raw &>/dev/null && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
[ -z "$SCRIPT_CLONE_URL" ] && SCRIPT_CLONE_URL="${_XRK_DEFAULT_CLONE:-https://gitcode.com/Xrkseek/xrk-projects-scripts.git}"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL XRK_ROOT

克隆脚本() {
    echo -e "${color_light_blue}正在克隆脚本文件...${reset_color}"
    if git clone --depth=1 "$SCRIPT_CLONE_URL" "$XRK_ROOT"; then
        printf 'SCRIPT_RAW_BASE="%s"\nSCRIPT_CLONE_URL="%s"\n' "$SCRIPT_RAW_BASE" "$SCRIPT_CLONE_URL" > "$XRK_ROOT/.repo_source"
        bash "$XRK_ROOT/judge.sh"
        source "$XRK_ROOT/.init"
    else
        echo -e "${color_red}脚本克隆失败${reset_color}"
        exit 1
    fi
}

克隆葵崽() {
    local repo_url="$1"
    local repo_name="$2"
    echo -e "${color_light_blue}正在克隆 $repo_name...${reset_color}"
    if git clone --depth=1 "$repo_url" "$HOME/$repo_name"; then
        echo -e "${color_light_green}$repo_name 克隆成功${reset_color}"
        chmod +x "$XRK_ROOT/judge.sh"
        . "$XRK_ROOT/judge.sh"
    else
        echo -e "${color_red}$repo_name 克隆失败${reset_color}"
        exit 1
    fi
}

# 检测已安装葵崽(XRK-Yunzai)，若存在则询问是否删除后继续
检测葵崽存在魔法() {
    source "$XRK_ROOT/shell_modules/init.sh"
    check_changes
    search_directories
    if [ -n "${xyz:-}" ] || [ -n "${yz:-}" ]; then
        read -rp "检测到已安装葵崽(XRK-Yunzai)，是否删除并继续脚本 (是/否)： " user_input
        case "$user_input" in
            "是")
                to_del="${yz:-$xyz}"
                [ -z "$to_del" ] && to_del="${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
                if [ -z "$to_del" ] || [ ! -d "$to_del" ]; then
                    echo -e "${color_red}未找到葵崽路径，无法删除${reset_color}"
                    exit 1
                fi
                echo -e "${color_light_blue}正在删除葵崽...${reset_color}"
                if rm -rf "$to_del"; then
                    echo -e "${color_light_green}葵崽已成功删除${reset_color}"
                else
                    echo -e "${color_red}删除葵崽失败${reset_color}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${color_red}操作取消，退出脚本${reset_color}"
                exit 1
                ;;
        esac
    fi
}

检测npm-node-pnpm安装() {
    if type run_software &>/dev/null && [ -f "$XRK_ROOT/project-install/software/node" ]; then
        run_software "project-install/software/node"
        run_software "project-install/software/pnpm"
    elif [ -f "$XRK_ROOT/project-install/software/node" ]; then
        bash "$XRK_ROOT/project-install/software/node"
        bash "$XRK_ROOT/project-install/software/pnpm"
    else
        bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/node")
        bash <(curl -sL "$SCRIPT_RAW_BASE/project-install/software/pnpm")
    fi
}

检测redis安装() {
    echo -e "${color_light_blue}正在启动 Redis 服务...${reset_color}"
    redis-server --daemonize yes --save 900 1 --save 300 10
}

葵崽安装菜单() {
    local yz_dir="${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}" name="${YZ_DEFAULT_NAME:-XRK-Yunzai}"
    echo -e "${color_cyan}++++++++++++++++++++++++${reset_color}"
    echo " 1. $name (葵崽)"
    echo -e "${color_cyan}++++++++++++++++++++++++${reset_color}"
    read -t 1 -rp "[自动选择葵崽]： " choice
    [ -z "$choice" ] && { echo -e "${color_red}超时未选择，默认选择葵崽${reset_color}"; choice=1; }
    [ "$choice" != "1" ] && echo -e "${color_red}无效选择，默认选择葵崽${reset_color}"
    克隆葵崽 "https://gitcode.com/Xrkseek/XRK-Yunzai.git" "$name"
    export xyz="$yz_dir" yz="$yz_dir"
    source "$XRK_ROOT/shell_modules/github.sh"
    if [[ -d "$yz_dir" ]]; then
        echo -e "${color_light_blue}正在安装 $name 依赖...${reset_color}"
        cd "$yz_dir" || exit
        git clone --depth=1 https://github.com/yoimiya-kokomi/miao-plugin.git ./plugins/miao-plugin/
        git clone https://gitee.com/TimeRainStarSky/Yunzai-genshin.git ./plugins/genshin/
        export PUPPETEER_SKIP_DOWNLOAD='true'
        pnpm update puppeteer@19.8.3 -w
        cd "$HOME" || exit
        bash "$XRK_ROOT/body/xrkwrite.sh"
        echo -e "${color_light_green}输入 xyz 启动葵崽 ($name)${reset_color}"
    else
        echo -e "${color_red}安装过程出错，请检查${reset_color}"
        exit 1
    fi
}

安装xrk脚本() {
    if [ -d "$XRK_ROOT" ]; then
        echo -e "${color_light_cyan}检测到你已安装代码库，是否要更新全部历史设置? (y/n)${reset_color}"
        echo -e "5秒后自动选择 n ..."
        read -t 5 -r confirm
        if [ "$confirm" = "y" ]; then
            rm -rf "$XRK_ROOT"
            克隆脚本
        else
            (cd "$XRK_ROOT" && git pull --no-rebase)
        fi
    else
        克隆脚本
    fi
}

# 葵崽主流程：脚本仓库 → 检测/删除旧葵崽 → Node/pnpm → Redis → 葵崽安装菜单（供 project-install/Yunzai/* 调用）
葵崽主流程安装() {
    安装xrk脚本
    检测葵崽存在魔法
    检测npm-node-pnpm安装
    检测redis安装
    葵崽安装菜单
}