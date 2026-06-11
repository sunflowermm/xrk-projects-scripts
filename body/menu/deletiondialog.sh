#!/bin/bash
# 文件/目录删除（dialog 触屏版）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1 deletion_common.sh
xrk_deletion_paths

export DIALOG_OK=0
export DIALOG_CANCEL=1
export DIALOG_ESC=255

temp_file=$(mktemp)
trap 'rm -f $temp_file' EXIT

function show_file_menu() {
    local want_path=$1
    local title=$2
    
    if [ ! -d "$want_path" ]; then
        xrk_dialog --title "错误" --msgbox "目录 $want_path 不存在" 8 40
        return 1
    fi
    
    local files=($(xrk_list_dir_entries "$want_path"))
    
    if [ ${#files[@]} -eq 0 ]; then
        xrk_dialog --title "提示" --msgbox "当前目录为空" 8 40
        return 1
    fi
    
    local dialog_options=()
    for i in "${!files[@]}"; do
        if [ -d "$want_path/${files[i]}" ]; then
            dialog_options+=("${files[i]}" "📁 文件夹" "off")
        else
            dialog_options+=("${files[i]}" "📄 文件" "off")
        fi
    done
    
    xrk_dialog --title "$title" \
           --checklist "使用空格键选择要删除的文件/文件夹" \
           20 70 15 \
           "${dialog_options[@]}" \
           2>"$temp_file"
    
    if [ $? -eq 0 ]; then
        local selected_files=($(cat "$temp_file"))
        
        if [ ${#selected_files[@]} -gt 0 ]; then
            local files_list=""
            for file in "${selected_files[@]}"; do
                files_list="$files_list\n$file"
            done
            
            xrk_dialog --title "确认删除" \
                   --yesno "确定要删除以下文件/文件夹吗？$files_list" \
                   15 60
            
            if [ $? -eq 0 ]; then
                local deleted=0 failed=0 error_msg="" file
                xrk_delete_items "$want_path" deleted failed "${selected_files[@]}"
                for file in "${selected_files[@]}"; do
                    [ -e "$want_path/$file" ] && error_msg="$error_msg\n$file"
                done

                local result_msg="成功删除 $deleted 个文件/文件夹"
                [ "$failed" -gt 0 ] && result_msg="$result_msg\n删除失败 $failed 个：$error_msg"
                
                xrk_dialog --title "删除结果" --msgbox "$result_msg" 15 60
            fi
        fi
    fi
}

function main_menu() {
    while true; do
        xrk_dialog --title "文件管理器" \
               --menu "选择要管理的目录" \
               15 60 4 \
               1 "插件包目录" \
               2 "js插件目录" \
               3 "Bot目录" \
               4 "自定义目录管理" \
               2>"$temp_file"
        
        local choice
        choice=$(cat "$temp_file")
        case $choice in
            1) show_file_menu "$XRK_DEL_PLUGINS" "插件包目录" ;;
            2) show_file_menu "$XRK_DEL_JS" "js插件目录" ;;
            3) show_file_menu "$XRK_DEL_BOT" "Bot目录" ;;
            4)
                xrk_dialog --title "自定义目录" \
                       --inputbox "输入要管理的目录路径：" \
                       8 60 \
                       2>"$temp_file"
                
                if [ $? -eq 0 ]; then
                    local custom_path
                    custom_path=$(cat "$temp_file")
                    show_file_menu "$custom_path" "自定义目录"
                fi
                ;;
            *) exit 0 ;;
        esac
    done
}

main_menu
