#!/bin/bash
# 插件菜单：安装/管理插件、Python 环境、代理
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 1 0  # 初始化：需要common（install_pkg），不需要check_changes
YZ_DIR="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}"
MENU_DIR="$YZ_DIR/plugins/XRK-plugin/resources/plugins"

# 确保 github.sh 可用：统一 GitHub 加速（git 包装 + getgh），避免各处重复判断
_PLUGIN_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
type getgh &>/dev/null || {
    [ -f "$root/shell_modules/github.sh" ] && source "$root/shell_modules/github.sh" \
        || source <(curl -sL "${_PLUGIN_RAW_BASE}/shell_modules/github.sh" 2>/dev/null) 2>/dev/null \
        || true
}

CATEGORIES=(
    "推荐插件:recommended_plugins.json"
    "文娱插件:entertainment_plugins.json"
    "IP类插件:ip_plugins.json"
    "游戏插件:game_plugins.json"
    "JS插件:js.json"
)

# 检查依赖（使用统一函数）
check_dependencies() {
    clear
    menu_check_deps jq dialog git pnpm curl
}

# 统一执行 pnpm 安装（合并重复逻辑）
run_pnpm_install() {
    [ -d "$YZ_DIR" ] && (cd "$YZ_DIR" && pnpm i) || echo -e "${red}葵崽目录不存在${bg}"
}

# 配置 Python 环境：统一走 uv 模块
install_python_env() {
    if [ -f "$root/body/modules/python_uv.sh" ]; then
        bash "$root/body/modules/python_uv.sh"
    else
        echo -e "${red}未找到 python_uv 模块${bg}"
    fi
    read -rp "按Enter继续..." _
}

# 加载插件数据（使用统一文件检查）
load_plugins() {
    local category_file="$1"
    local json_file="$MENU_DIR/$category_file"
    
    menu_check_file "$json_file" "找不到配置文件 $json_file" || return 1
    
    jq -r '.[] | "\(.cn_name)|\(.name)|\(.description)|\(.git)"' "$json_file"
}

# 显示插件选择界面（使用统一函数）
show_plugin_selection() {
    local category_names=()
    for category in "${CATEGORIES[@]}"; do
        IFS=":" read -r name _ <<< "$category"
        category_names+=("$name")
    done
    menu_show "插件类别选择" "${category_names[@]}"
}

# 安装普通插件
install_normal_plugin() {
    local name="$1"
    local git_url="$2"
    local cn_name="$3"
    local target_dir="$YZ_DIR/plugins/$name"

    if [ -d "$target_dir" ]; then
        echo -e "${yellow}! $cn_name 已安装${bg}"
        return 0
    fi
    
    echo -e "${caidan2}正在安装 $cn_name...${bg}"
    if git clone --depth=1 "$git_url" "$target_dir"; then
        echo -e "${green}✓ $cn_name 安装成功!${bg}"
        return 0
    else
        echo -e "${red}✗ $cn_name 安装失败${bg}"
        return 1
    fi
}

# 安装 js 插件（目录 plugins/other）
install_js_plugin() {
    local cn_name="$1"
    local git_url="$2"
    local target_dir="$YZ_DIR/plugins/other"
    local target_file="$target_dir/${cn_name}.js"

    mkdir -p "$target_dir"
    
    if [ -f "$target_file" ]; then
        echo -e "${yellow}! $cn_name 已安装${bg}"
        return 0
    fi
    
    echo -e "${caidan2}正在安装 $cn_name...${bg}"
    if xrk_download "$git_url" "$target_file" 3; then
        echo -e "${green}✓ $cn_name 安装成功!${bg}"
        return 0
    else
        echo -e "${red}✗ $cn_name 安装失败${bg}"
        return 1
    fi
}

# Dialog方式显示插件
show_dialog_plugins() {
    local category_name="$1"
    local category_file="$2"
     
    local options=()
    local index=1
    while IFS="|" read -r cn_name name description git; do
        if [ -n "$cn_name" ]; then
            options+=("$index" "$cn_name" "OFF")
            descriptions[$index]="$description"
            ((index++))
        fi
    done < <(load_plugins "$category_file")
    
    dialog --title "向日葵插件安装 - $category_name" \
           --backtitle "向日葵Bot插件管理系统" \
           --checklist "请选择要安装的插件 [空格选择，回车确认]：" 20 70 15 \
           "${options[@]}" 2>/tmp/plugin_selections
           
    if [ $? -eq 0 ]; then
        clear
        local selections=$(cat /tmp/plugin_selections)
        rm -f /tmp/plugin_selections
        
        for selection in $selections; do
            if [ "$selection" -ge 1 ] && [ "$selection" -le ${#options[@]} ]; then
                local plugin_data=($(load_plugins "$category_file" | sed -n "${selection}p"))
                IFS="|" read -r cn_name name description git <<< "${plugin_data[0]}"
                
                if [ "$category_file" = "js.json" ]; then
                    install_js_plugin "$cn_name" "$git"
                else
                    install_normal_plugin "$name" "$git" "$cn_name"
                fi
            fi
        done
    fi
}

# 文字界面显示插件
show_text_plugins() {
    local category_name="$1"
    local category_file="$2"
    
    while true; do
        clear
        local plugins_data=() plugin_names=()
        while IFS="|" read -r cn_name name description git; do
            if [ -n "$cn_name" ]; then
                plugins_data+=("$cn_name|$name|$description|$git")
                plugin_names+=("$cn_name")
            fi
        done < <(load_plugins "$category_file")
        menu_show "${category_name} 插件" "${plugin_names[@]}"
        read -rp "请选择 [1-${MENU_OPT_COUNT}] 多选用空格，0 返回: " raw_sel
        selections=$(echo "$raw_sel" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [ "$selections" = "0" ] || [ "$selections" = "q" ] && break
        
        for selection in $selections; do
            if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${MENU_OPT_COUNT}" ]; then
                IFS="|" read -r cn_name name description git <<< "${plugins_data[$selection-1]}"
                
                if [ "$category_file" = "js.json" ]; then
                    install_js_plugin "$cn_name" "$git"
                else
                    install_normal_plugin "$name" "$git" "$cn_name"
                fi
            fi
        done
        
        echo -e "${caidan2}是否继续安装此类别的其他插件? (y/n)${bg}"
        read -r continue_install
        if [[ "$continue_install" != "y" ]]; then
            break
        fi
    done
}

show_main_menu() {
    menu_show "葵崽插件菜单" "安装插件(触屏版)" "安装插件(文字版)" "js插件(触屏版)" "js插件(文字版)" "插件文件管理(触屏)" "插件文件管理(文字)" "配置 Python 环境" "切换插件代理(触屏)" "切换插件代理(文字)"
}

main() {
    check_dependencies
    
    while true; do
        clear
        show_main_menu
        read -rp "请选择 [0-${MENU_OPT_COUNT}]: " raw_choice
        choice=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [ "$choice" = "0" ] || [ "$choice" = "q" ] && { echo -e "${caidan2}感谢使用，再见！${bg}"; run_pnpm_install; exit 0; }
        case "$choice" in
            1|2)
                clear
                show_plugin_selection
                read -rp "请选择类别 [0-${MENU_OPT_COUNT}]: " raw_cat
                category_choice=$(echo "$raw_cat" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
                if [ -z "$category_choice" ] || [ "$category_choice" = "0" ] || [ "$category_choice" = "q" ]; then
                    echo -e "${red}已取消${bg}"; sleep 2
                elif [[ "$category_choice" =~ ^[0-9]+$ ]] && [ "$category_choice" -ge 1 ] && [ "$category_choice" -le "${MENU_OPT_COUNT}" ]; then
                    IFS=":" read -r category_name category_file <<< "${CATEGORIES[$category_choice-1]}"
                    if [ "$choice" = "1" ]; then
                        show_dialog_plugins "$category_name" "$category_file"
                    else
                        show_text_plugins "$category_name" "$category_file"
                    fi
                    clear
                    run_pnpm_install
                else
                    echo -e "${red}无效选择${bg}"; sleep 2
                fi
                ;;
            3)
                clear
                bash "$root/body/menu/jsdialog.sh"
                clear
                run_pnpm_install
                ;;
            4)
                clear
                bash "$root/body/menu/js.sh"
                clear
                [ -d "$YZ_DIR" ] && (cd "$YZ_DIR" && pnpm add axios -w && pnpm i) || echo -e "${red}葵崽目录不存在${bg}"
                ;;
            5)
                clear
                bash "$root/body/menu/deletiondialog.sh"
                clear
                run_pnpm_install
                ;;
            6)
                clear
                bash "$root/body/menu/deletion.sh"
                clear
                run_pnpm_install
                ;;
            7)
                clear
                install_python_env
                ;;
            8)
                clear
                bash "$root/body/menu/diaproxy.sh"
                clear
                ;;
            9)
                clear
                bash "$root/body/menu/proxy.sh"
                clear
                ;;
            *)
                echo -e "${red}无效选择 [0-${MENU_OPT_COUNT}]${bg}"
                sleep 1
                ;;
        esac
    done
}

main "$@"
