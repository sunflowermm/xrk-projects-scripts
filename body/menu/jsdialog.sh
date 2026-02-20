#!/bin/bash
# js 插件（dialog 触屏版），目录 plugins/other
root="${XRK_ROOT:-/xrk}"
[ -f "$root/shell_modules/menu_common.sh" ] && source "$root/shell_modules/menu_common.sh"
menu_init 1 0

xrk="$HOME/xrk"
YZ_PLUGINS_JS="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}/plugins/other"
jh="$YZ_PLUGINS_JS"

menu_check_deps dialog 1

DIALOG_BACKTITLE="插件安装助手"
DIALOG_HEIGHT=20
DIALOG_WIDTH=60

move_vocal(){
    local woaini=$1
    local wogeng=$2
    sleep 1
    mkdir -p "$jh"

    dialog --infobox "正在检查 $woaini 安装状态..." 3 40
    if [ -d "$yz/resources/$woaini" ]; then
        dialog --msgbox "已经安装过 ${woaini} 了，正在跳过" 6 40
    else
        mv -f $xrk/shell-js/$woaini $yz/resources/
    fi
    
    dialog --infobox "正在检查 $wogeng 安装状态..." 3 40
    if [ -d "$jh/$wogeng" ]; then
        dialog --msgbox "已经安装过 ${wogeng} 了，正在跳过" 6 40
    else
        mv -f $xrk/shell-js/$wogeng $jh/
    fi
}

select_js_plugins() {
    local js_files=($(find $xrk/shell-js/ -maxdepth 1 -type f -name "*.js"))
    local options=""
    local i=0
    
    for file in "${js_files[@]}"; do
        basename="${file##*/}"
        options="$options $i $basename off"
        ((i++))
    done
    
    local selected_plugins=$(dialog --separate-output \
        --checklist "选择要安装的插件:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH 10 \
        $options \
        2>&1 >/dev/tty)
    
    local selected_name_reply_js=false
    
    for selection in $selected_plugins; do
        if [[ $selection =~ ^[0-9]+$ ]] && [ $selection -ge 0 ] && [ $selection -lt ${#js_files[@]} ]; then
            selected_file=${js_files[$selection]}
            if [ "${selected_file##*/}" == "名称回复.js" ]; then
                selected_name_reply_js=true
            fi
            mv -n "$selected_file" $jh/
            dialog --infobox "已安装 $(basename "$selected_file")" 3 40
            sleep 1
        fi
    done
    
    if [ "$selected_name_reply_js" = true ]; then
        local bot_name=$(dialog --inputbox "输入你想要的机器人名字:" \
            8 40 \
            2>&1 >/dev/tty)
            
        if [ $? -eq 0 ]; then
            [ -f "$jh/名称回复.js" ] && sed -i "11 s/'[^']*'/'${bot_name}'/" "$jh/名称回复.js"
            dialog --msgbox "机器人名字已更新为: $bot_name" 6 40
        fi
    fi
}

while true; do
    exec 3>&1
    selection=$(dialog \
        --backtitle "$DIALOG_BACKTITLE" \
        --title "js插件" \
        --clear \
        --cancel-label "退出" \
        --menu "请选择一个选项:" \
        $DIALOG_HEIGHT $DIALOG_WIDTH 4 \
        "1" "安装全部 js 插件" \
        "2" "安装或更新向日葵插件" \
        "3" "修改名称回复机器人名字" \
        2>&1 1>&3)
    exit_status=$?
    exec 3>&-
    
    case $exit_status in
        1|255)
            clear
            echo "感谢使用！"
            exit 0
            ;;
    esac
    
    case $selection in
        1)
            dialog --infobox "正在克隆插件仓库..." 3 40
            git clone --depth=1 https://gitcode.com/Xrkseek/collection-of-jses.git $xrk
            select_js_plugins
            chmod 755 $xrk
            rm -rf $xrk
            ;;
        2)
            dialog --msgbox "去下载xrk-plugin吧，见鬼吧你，还在这安装" 6 40
            ;;
        3)
            bot_name=$(dialog --inputbox "输入你想要的机器人名字:" \
                8 40 \
                2>&1 >/dev/tty)
            
            if [ $? -eq 0 ]; then
                [ -f "$jh/名称回复.js" ] && sed -i "11 s/'[^']*'/'${bot_name}'/" "$jh/名称回复.js"
                dialog --msgbox "机器人名字已更新为: $bot_name" 6 40
            fi
            ;;
    esac
done
