#!/bin/bash
# 文件/目录删除（dialog 触屏版），依赖 yz
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 0 0

export DIALOG_OK=0
export DIALOG_CANCEL=1
export DIALOG_ESC=255

temp_file=$(mktemp)
trap 'rm -f $temp_file' EXIT

function show_file_menu() {
    local want_path=$1
    local title=$2
    
    if [ ! -d "$want_path" ]; then
        dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "错误" --msgbox "目录 $want_path 不存在" 8 40
        return 1
    fi
    
    local files=($(find "$want_path" -mindepth 1 -maxdepth 1 -printf "%f\n" 2>/dev/null))
    
    if [ ${#files[@]} -eq 0 ]; then
        dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "提示" --msgbox "当前目录为空" 8 40
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
    
    dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "$title" \
           --checklist "使用空格键选择要删除的文件/文件夹" \
           20 70 15 \
           "${dialog_options[@]}" \
           2>$temp_file
    
    if [ $? -eq 0 ]; then
        local selected_files=($(cat $temp_file))
        
        if [ ${#selected_files[@]} -gt 0 ]; then
            local files_list=""
            for file in "${selected_files[@]}"; do
                files_list="$files_list\n$file"
            done
            
            dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "确认删除" \
                   --yesno "确定要删除以下文件/文件夹吗？$files_list" \
                   15 60
            
            if [ $? -eq 0 ]; then
                local deleted=0
                local failed=0
                local error_msg=""
                
                for file in "${selected_files[@]}"; do
                    if rm -rf "$want_path/$file" 2>/dev/null; then
                        ((deleted++))
                    else
                        ((failed++))
                        error_msg="$error_msg\n$file"
                    fi
                done
                
                local result_msg="成功删除 $deleted 个文件/文件夹"
                [ $failed -gt 0 ] && result_msg="$result_msg\n删除失败 $failed 个：$error_msg"
                
                dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "删除结果" --msgbox "$result_msg" 15 60
            fi
        fi
    fi
}

function main_menu() {
    while true; do
        dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "文件管理器" \
               --menu "选择要管理的目录" \
               15 60 4 \
               1 "插件包目录" \
               2 "js插件目录" \
               3 "Bot目录" \
               4 "自定义目录管理" \
               2>$temp_file
        
        local choice=$(cat $temp_file)
        case $choice in
            1) show_file_menu "$yz/plugins" "插件包目录" ;;
            2) show_file_menu "$yz/plugins/other" "js插件目录" ;;
            3) show_file_menu "$yz" "Bot目录" ;;
            4)
                dialog --backtitle "$XRK_DIALOG_BACKTITLE" --title "自定义目录" \
                       --inputbox "输入要管理的目录路径：" \
                       8 60 \
                       2>$temp_file
                
                if [ $? -eq 0 ]; then
                    local custom_path=$(cat $temp_file)
                    show_file_menu "$custom_path" "自定义目录"
                fi
                ;;
            *) exit 0 ;;
        esac
    done
}

main_menu
