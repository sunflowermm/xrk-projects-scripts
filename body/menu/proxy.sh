#!/bin/bash
# 插件代理：测试并切换 GitHub 代理（共用 github.sh 的 PROXIES）
root="${XRK_ROOT:-/xrk}"
[ -f "$root/.init" ] && source "$root/.init"
[ -f "$root/shell_modules/github.sh" ] && source "$root/shell_modules/github.sh"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 0 0

red="$RED"
green="$GREEN"
yellow="$YELLOW"
bg="$NC"

FILTER_DIRS=('example' 'other' 'system' 'adapter')

function test_proxy() {
    local proxy=$1
    local check_path="NapNeko/NapCatQQ/main/package.json"
    local speed_threshold=2
    local curl_timeout=3

    local proxied_check_url="${proxy}/https://raw.githubusercontent.com/${check_path}"
    local result
    result=$(curl --silent --fail --max-time $curl_timeout -w "%{http_code} %{time_total}" -o /dev/null "$proxied_check_url")
    local http_code=$(echo "$result" | awk '{print $1}')
    local time_total=$(echo "$result" | awk '{print $2}')

    if [ "$http_code" = "200" ]; then
        if awk "BEGIN{exit($time_total<$speed_threshold?0:1)}"; then
            echo -e "${green}✅ 代理可用: ${proxy}, 响应时间: ${time_total}s${bg}"
            return 0
        else
            echo -e "${yellow}⚠️ 代理可用但响应偏慢(${time_total}s): ${proxy}${bg}"
            return 1
        fi
    else
        echo -e "${red}❌ 代理不可用: ${proxy}${bg}"
        return 2
    fi
}

function change_proxy() {
    local target_dir=$1
    local plugin_name=$2
    
    menu_check_dir "$target_dir/.git" "$target_dir 不是Git仓库" || { read -rp "按回车键继续..." _; return 1; }
    
    local current_url=$(cd "$target_dir" && git config --get remote.origin.url)
    [ -z "$current_url" ] && { echo -e "${red}错误: 无法获取远程URL${bg}"; read -rp "按回车键继续..." _; return 1; }
    
    echo -e "${yellow}当前远程URL: $current_url${bg}"
    
    local shuffled_proxies=($(printf "%s\n" "${PROXIES[@]}" | shuf))
    local fast_proxies=()
    
    echo -e "${yellow}正在测试代理速度...${bg}"
    for proxy in "${shuffled_proxies[@]}"; do
        if [ -z "$proxy" ]; then
            continue
        fi
        
        if test_proxy "$proxy"; then
            fast_proxies+=("$proxy")
            if [ ${#fast_proxies[@]} -ge 5 ]; then
                break
            fi
        fi
    done
    
    if [ ${#fast_proxies[@]} -eq 0 ]; then
        echo -e "${red}没有找到可用的快速代理${bg}"
        read -rp "按回车键继续..." _
        return 1
    fi
    
    local proxy_opts=("${fast_proxies[@]}" "不修改代理")
    menu_show "为 $plugin_name 选择代理" "${proxy_opts[@]}"
    read -rp "请选择 [1-${MENU_OPT_COUNT}]，q 跳过: " raw_choice
    choice=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
    [ "$choice" = "0" ] || [ "$choice" = "q" ] && return
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$MENU_OPT_COUNT" ]; then
        if [ "$choice" -eq "$MENU_OPT_COUNT" ]; then
            echo -e "${yellow}保持原有URL不变${bg}"
        else
            local selected_proxy=${fast_proxies[$((choice-1))]}
            if [[ "$current_url" == https://github.com/* ]]; then
                local new_url="${selected_proxy}/${current_url}"
                if (cd "$target_dir" && git config remote.origin.url "$new_url"); then
                    echo -e "${green}成功更新代理为: $selected_proxy${bg}"
                    echo -e "${green}新的远程URL: $new_url${bg}"
                    echo -e "${yellow}正在尝试更新插件...${bg}"
                    if (cd "$target_dir" && git pull); then
                        echo -e "${green}插件更新成功！${bg}"
                    else
                        echo -e "${red}插件更新失败，请手动检查${bg}"
                    fi
                else
                    echo -e "${red}更新代理失败${bg}"
                fi
            else
                echo -e "${yellow}当前URL不是GitHub URL，无法应用代理${bg}"
            fi
        fi
    else
        echo -e "${red}无效选择${bg}"
    fi
    read -rp "按回车键继续..." _
}

function manage_plugins() {
    local plugins_path="$yz/plugins"
    
    while true; do
        menu_check_dir "$plugins_path" "插件包目录不存在" || exit 1
        
        IFS=$'\n'
        local all_dirs=($(find "$plugins_path" -mindepth 1 -maxdepth 1 -type d 2>/dev/null))
        local filtered_dirs=()
        
        for dir in "${all_dirs[@]}"; do
            local base_name=$(basename "$dir")
            local should_filter=false
            
            for filter in "${FILTER_DIRS[@]}"; do
                if [ "$base_name" = "$filter" ]; then
                    should_filter=true
                    break
                fi
            done
            
            if [ "$should_filter" = false ]; then
                filtered_dirs+=("$dir")
            fi
        done
        
        if [ ${#filtered_dirs[@]} -eq 0 ]; then
            echo -e "${yellow}没有找到可以管理的插件${bg}"
            exit 1
        fi

        local plugin_names=()
        for dir in "${filtered_dirs[@]}"; do
            plugin_names+=($(basename "$dir"))
        done
        
        local plugin_opts=()
        for name in "${plugin_names[@]}"; do
            plugin_opts+=("📁 $name")
        done
        menu_show "插件包目录" "${plugin_opts[@]}"
        
    read -rp "输入要切换代理的插件序号 [1-${MENU_OPT_COUNT}]，0 或 q 退出: " raw_input
        input=$(echo "$raw_input" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [ "$input" = "0" ] || [ "$input" = "q" ] && { echo "程序已退出"; exit 0; }
        
        if menu_validate_input "$input" 1 ${#plugin_names[@]} "序号 $input 超出范围"; then
            index=$((input - 1))
            change_proxy "${filtered_dirs[index]}" "${plugin_names[index]}"
            clear_menu
        else
            read -rp "按回车键继续..." _
            clear_menu
        fi
    done
}

manage_plugins
