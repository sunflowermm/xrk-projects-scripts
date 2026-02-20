#!/bin/bash
# 文件/目录管理：插件、js、Bot、自定义目录删除
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 0 0  # 初始化：不需要common，不需要check_changes

function show_menu() {
    local title="${1:-文件管理}"
    local options=("${@:2}")
    menu_show "$title" "${options[@]}" "请输入要管理的序号"
}

function delete_files() {
    local want_path=$1
    local files=("${@:2}")
    local deleted=0
    local failed=0
    
    echo -e "${yellow}将要删除以下文件/文件夹：${bg}"
    for file in "${files[@]}"; do
        local type_str=$([ -d "$want_path/$file" ] && echo "文件夹" || echo "文件")
        echo "- $type_str: $file"
    done
    echo
    read -rp "确定要删除这些文件吗? (y/n): " confirm
    case $confirm in
        [Yy]*)
            for file in "${files[@]}"; do
                if rm -rf "$want_path/$file"; then
                    ((deleted++))
                else
                    echo -e "${red}删除失败: $file${bg}"
                    ((failed++))
                fi
            done
            echo -e "${green}成功删除 $deleted 个文件/文件夹${bg}"
            [ $failed -gt 0 ] && echo -e "${red}删除失败 $failed 个文件/文件夹${bg}"
            ;;
        *)
            echo -e "${yellow}已取消删除操作${bg}"
            ;;
    esac
    echo
}

function manage_files() {
    local want_path=$1
    local folder_name=$2
    
    while true; do
        menu_check_dir "$want_path" "目录 $want_path 不存在" || return
        
        IFS=$'\n'
        file_list=($(find "$want_path" -mindepth 1 -maxdepth 1 2>/dev/null))
        
        if [ ${#file_list[@]} -eq 0 ]; then
            echo -e "${yellow}当前目录为空${bg}"
            read -rp "按回车键返回主菜单..." _
            return
        fi

        for i in "${!file_list[@]}"; do
            file_list[$i]=$(basename "${file_list[$i]}")
        done
        
        local file_opts=()
        for file in "${file_list[@]}"; do
            if [ -d "$want_path/$file" ]; then
                file_opts+=("📁 $file")
            else
                file_opts+=("📄 $file")
            fi
        done
        menu_show "$folder_name" "${file_opts[@]}"
        
        read -rp "输入序号 [1-${MENU_OPT_COUNT}] 多选用空格，回车返回 q 退出: " raw_input
        [ -z "$raw_input" ] && { clear_menu; return; }
        first=$(echo "$raw_input" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
        [ "$first" = "q" ] && { echo "程序已退出"; exit 0; }
        IFS=' ' read -ra inputs <<< "$raw_input"
        local files_to_delete=()
        local invalid_input=false
        
        for num in "${inputs[@]}"; do
            if menu_validate_input "$num" 1 ${#file_list[@]} "序号 $num 超出范围"; then
                index=$((num - 1))
                files_to_delete+=("${file_list[index]}")
            else
                invalid_input=true
            fi
        done
        
        if [ ${#files_to_delete[@]} -gt 0 ] && [ "$invalid_input" = false ]; then
            delete_files "$want_path" "${files_to_delete[@]}"
            read -rp "按回车键继续..." _
            clear_menu
        fi
    done
}

function main() {
    local options=("插件包目录" "js插件目录" "Bot目录" "自定义目录管理")
    
    while true; do
        show_menu "选择目录" "${options[@]}"
        read -rp "请选择 [1-${MENU_OPT_COUNT}]，q 退出: " raw_choice
        choice=$(echo "$raw_choice" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')
        [ "$choice" = "0" ] || [ "$choice" = "q" ] && { echo "程序已退出"; exit 0; }
        case "$choice" in
            1) want_path="$yz/plugins"; manage_files "$want_path" "${options[0]}" ;;
            2) want_path="$yz/plugins/other"; manage_files "$want_path" "${options[1]}" ;;
            3) want_path="$yz"; manage_files "$want_path" "${options[2]}" ;;
            4) read -rp "输入要管理的目录: " want_path
               menu_check_dir "$want_path" "目录不存在" || continue
               manage_files "$want_path" "自定义目录"
               ;;
            *) echo -e "${red}无效选择 [1-${MENU_OPT_COUNT}]${bg}" ;;
        esac
        clear_menu
    done
}

main
