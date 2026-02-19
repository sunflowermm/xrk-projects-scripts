#!/bin/bash
# 主流程依赖：克隆脚本/云崽、检测、安装 Node/pnpm、Redis、菜单（依赖 bootstrap 的 get_clone_from_raw）
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
[ -z "$SCRIPT_CLONE_URL" ] && type get_clone_from_raw &>/dev/null && SCRIPT_CLONE_URL="$(get_clone_from_raw "$SCRIPT_RAW_BASE")"
[ -z "$SCRIPT_CLONE_URL" ] && SCRIPT_CLONE_URL="https://gitcode.com/Xrkseek/xrk-projects-scripts.git"
export SCRIPT_RAW_BASE SCRIPT_CLONE_URL

# 克隆脚本
function 克隆脚本 {
    echo -e "${color_light_blue}正在克隆脚本文件...${reset_color}"
    if git clone --depth=1 "$SCRIPT_CLONE_URL" /xrk; then
        # 落盘当前源，供 /xrk 内脚本后续使用
        printf 'SCRIPT_RAW_BASE="%s"\nSCRIPT_CLONE_URL="%s"\n' "$SCRIPT_RAW_BASE" "$SCRIPT_CLONE_URL" > /xrk/.repo_source
        bash /xrk/judge.sh
        source /xrk/.init
    else
        echo -e "${color_red}脚本克隆失败${reset_color}"
        exit 1
    fi
}

# 克隆指定的云崽版本
function 克隆云崽 {
    local repo_url="$1"
    local repo_name="$2"
    echo -e "${color_light_blue}正在克隆 $repo_name...${reset_color}"
    if git clone --depth=1 "$repo_url" "$HOME/$repo_name"; then
        echo -e "${color_light_green}$repo_name 克隆成功${reset_color}"
        chmod +x /xrk/judge.sh
        . /xrk/judge.sh
    else
        echo -e "${color_red}$repo_name 克隆失败${reset_color}"
        exit 1
    fi
}

# 检查是否已安装云崽
function 检测云崽存在魔法 {
    source /xrk/shell_modules/init.sh
    # 主逻辑
    check_changes
    search_directories
    if [[ -n "$myz" || -n "$tyz" || -n "$xyz" ]]; then
        read -rp "检测到已安装云崽，是否删除并继续脚本 (是/否)： " user_input
        case "$user_input" in
            "是")
                # 确定要删除的目录：优先 yz/xyz（葵崽），否则 myz/tyz
                to_del="${yz:-$xyz}"
                [ -z "$to_del" ] && to_del="${myz:-$tyz}"
                if [ -z "$to_del" ]; then
                    echo -e "${color_red}未找到云崽路径，无法删除${reset_color}"
                    exit 1
                fi
                echo -e "${color_light_blue}正在删除云崽...${reset_color}"
                if rm -rf "$to_del"; then
                    echo -e "${color_light_green}云崽已成功删除${reset_color}"
                else
                    echo -e "${color_red}删除云崽失败${reset_color}"
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

# 检查并安装 npm、node 和 pnpm（优先本地）
function 检测npm-node-pnpm安装 {
    if [ -f /xrk/Yunzai-install/software/node ]; then
        # 使用 run_software 统一执行（支持远程/本地）
        if type run_software &>/dev/null; then
            run_software "Yunzai-install/software/node"
            run_software "Yunzai-install/software/pnpm"
        else
            bash /xrk/Yunzai-install/software/node
            bash /xrk/Yunzai-install/software/pnpm
        fi
    else
        bash <(curl -sL "$SCRIPT_RAW_BASE/Yunzai-install/software/node")
        bash <(curl -sL "$SCRIPT_RAW_BASE/Yunzai-install/software/pnpm")
    fi
}

# 检查并启动 Redis
function 检测redis安装 {
    echo -e "${color_light_blue}正在启动 Redis 服务...${reset_color}"
    redis-server --daemonize yes --save 900 1 --save 300 10
}

# 显示安装菜单并处理选择
function 云崽安装菜单 {
    echo -e "${color_cyan}++++++++++++++++++++++++${reset_color}"
    echo " 1. XRK-Yunzai  (NTQQ/ICQQ)"
    echo -e "${color_cyan}++++++++++++++++++++++++${reset_color}"
    read -t 1 -rp "[自动选择葵崽]： " choice
    if [[ -z "$choice" ]]; then
     echo -e "${color_red}超时未选择，默认选择葵崽崽${reset_color}"
     choice=1
    fi
    case "$choice" in
        1)
           克隆云崽 "https://gitcode.com/Xrkseek/XRK-Yunzai.git" "XRK-Yunzai"
           ;;
        *)
           echo -e "${color_red}无效选择，默认选择葵崽${reset_color}"
           克隆云崽 "https://gitcode.com/Xrkseek/XRK-Yunzai.git" "XRK-Yunzai"
           ;;
    esac
    if [[ -n "$xyz" ]]; then
    source /xrk/shell_modules/github.sh
    if [[ -d "$HOME/XRK-Yunzai" ]]; then
            echo -e "${color_light_blue}正在安装 XRK-Yunzai 依赖...${reset_color}"
            cd "$HOME/XRK-Yunzai" || exit
            git clone --depth=1 https://github.com/yoimiya-kokomi/miao-plugin.git ./plugins/miao-plugin/
            git clone https://gitee.com/TimeRainStarSky/Yunzai-genshin.git ./plugins/genshin/
            export PUPPETEER_SKIP_DOWNLOAD='true'
            pnpm update puppeteer@19.8.3 -w
            cd $HOME
            bash /xrk/body/xrkwrite.sh
            echo -e "${color_light_green}输入 xyz 启动葵崽${reset_color}"
        else
            echo -e "${color_red}安装过程出错，请检查${reset_color}"
            exit 1
        fi
    else
        echo -e "${color_red}云崽安装失败，请重试${reset_color}"
        exit 1
    fi
}

# 安装脚本
function 安装xrk脚本 {
if [ -d "/xrk" ]; then
    echo -e "${color_light_cyan}检测到你已安装代码库，是否要更新全部历史设置? (y/n)${reset_color}"
    echo -e "5秒后自动选择 n ..."
    read -t 5 -r confirm
    if [ $? -eq 0 ] && [ "$confirm" == "y" ]; then
        rm -rf /xrk
        克隆脚本
    else
        cd /xrk || exit
        git pull --no-rebase
    fi
else
    克隆脚本
fi
}