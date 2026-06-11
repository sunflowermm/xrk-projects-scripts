#!/bin/bash
# js 插件（dialog 触屏版），目录 plugins/other
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
source "$root/shell_modules/menu_head.sh" 1 1 js_plugins.sh
xrk_js_init_paths
jh="$YZ_PLUGINS_JS"
xrk="$XRK_JS_REPO"

menu_check_deps dialog 1

select_js_plugins() {
    mapfile -t js_files < <(xrk_js_list_files)
    local options="" i=0 file basename selected_plugins selection selected_file

    for file in "${js_files[@]}"; do
        basename="${file##*/}"
        options="$options $i $basename off"
        ((i++))
    done

    selected_plugins=$(xrk_dialog --separate-output \
        --checklist "选择要安装的插件:" \
        "$XRK_DIALOG_HEIGHT" "$XRK_DIALOG_WIDTH" 10 \
        $options \
        2>&1 >/dev/tty)

    local selected_name_reply_js=false

    for selection in $selected_plugins; do
        if [[ $selection =~ ^[0-9]+$ ]] && [ "$selection" -ge 0 ] && [ "$selection" -lt ${#js_files[@]} ]; then
            selected_file=${js_files[$selection]}
            if [ "${selected_file##*/}" = "名称回复.js" ]; then
                selected_name_reply_js=true
            fi
            mv -n "$selected_file" "$jh/"
            xrk_dialog_infobox "已安装 $(basename "$selected_file")" 3 40
            sleep 1
        fi
    done

    if [ "$selected_name_reply_js" = true ]; then
        local bot_name
        bot_name=$(xrk_dialog --inputbox "输入你想要的机器人名字:" \
            8 40 \
            2>&1 >/dev/tty)

        if [ $? -eq 0 ]; then
            xrk_js_set_name_reply "$bot_name" "$jh/名称回复.js" \
                && xrk_dialog_msgbox "机器人名字已更新为: $bot_name" 6 40 \
                || xrk_dialog_msgbox "名称无效或更新失败" 6 40
        fi
    fi
}

while true; do
    exec 3>&1
    selection=$(xrk_dialog \
        --title "js插件" \
        --clear \
        --cancel-label "退出" \
        --menu "请选择一个选项:" \
        "$XRK_DIALOG_HEIGHT" "$XRK_DIALOG_WIDTH" 4 \
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
            xrk_dialog_infobox "正在克隆插件仓库..." 3 40
            if xrk_js_clone_repo "$xrk"; then
                select_js_plugins
            fi
            chmod 755 "$xrk" 2>/dev/null || true
            rm -rf "$xrk"
            ;;
        2)
            xrk_dialog_msgbox "去下载xrk-plugin吧，见鬼吧你，还在这安装" 6 40
            ;;
        3)
            bot_name=$(xrk_dialog --inputbox "输入你想要的机器人名字:" \
                8 40 \
                2>&1 >/dev/tty)

            if [ $? -eq 0 ]; then
                xrk_js_set_name_reply "$bot_name" "$jh/名称回复.js" \
                    && xrk_dialog_msgbox "机器人名字已更新为: $bot_name" 6 40 \
                    || xrk_dialog_msgbox "名称无效或更新失败" 6 40
            fi
            ;;
    esac
done
