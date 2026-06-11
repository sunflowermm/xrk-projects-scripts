#!/bin/bash
# 文件/目录管理：插件、js、Bot、自定义目录删除
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1 deletion_common.sh
xrk_deletion_paths

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
    if menu_confirm "确定要删除这些文件吗? (y/n)"; then
        xrk_delete_items "$want_path" deleted failed "${files[@]}"
        menu_msg_ok "成功删除 $deleted 个文件/文件夹"
        [ "$failed" -gt 0 ] && menu_msg_err "删除失败 $failed 个文件/文件夹"
    else
        menu_msg_warn "已取消删除操作"
    fi
    echo
}

function manage_files() {
    local want_path=$1
    local folder_name=$2
    
    while true; do
        menu_check_dir "$want_path" "目录 $want_path 不存在" || return
        
        IFS=$'\n'
        file_list=($(xrk_list_dir_entries "$want_path"))
        
        if [ ${#file_list[@]} -eq 0 ]; then
            menu_msg_warn "当前目录为空"
            menu_pause "按回车键返回主菜单..."
            return
        fi
        
        local file_opts=()
        for file in "${file_list[@]}"; do
            if [ -d "$want_path/$file" ]; then
                file_opts+=("📁 $file")
            else
                file_opts+=("📄 $file")
            fi
        done
        menu_show "$folder_name" "${file_opts[@]}"
        
        raw_input=$(menu_read_choice "输入序号 [1-${MENU_OPT_COUNT}] 多选用空格，回车返回 q 退出: ") || return
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
            menu_pause
            clear_menu
        fi
    done
}

function main() {
    local options=("插件包目录" "js插件目录" "Bot目录" "自定义目录管理")
    
    while true; do
        show_menu "选择目录" "${options[@]}"
        choice=$(menu_read_choice "请选择 [1-${MENU_OPT_COUNT}]，q 退出: ") || exit 0
        menu_should_exit "$choice" quit && { echo "程序已退出"; exit 0; }
        case "$choice" in
            1) manage_files "$XRK_DEL_PLUGINS" "${options[0]}" ;;
            2) manage_files "$XRK_DEL_JS" "${options[1]}" ;;
            3) manage_files "$XRK_DEL_BOT" "${options[2]}" ;;
            4)
               want_path=$(menu_read_text "输入要管理的目录: ")
               menu_check_dir "$want_path" "目录不存在" || continue
               manage_files "$want_path" "自定义目录"
               ;;
            *) menu_msg_err "无效选择 [1-${MENU_OPT_COUNT}]" ;;
        esac
        clear_menu
    done
}

main
