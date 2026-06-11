#!/bin/bash
# js 插件：克隆仓库、选择安装、名称回复（目录 plugins/other）
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1 js_plugins.sh
xrk_js_init_paths
jh="$YZ_PLUGINS_JS"
xrk="$XRK_JS_REPO"

select_js_plugins() {
    echo -e "${caidan3}获取 JS 插件列表...${bg}"
    mkdir -p "$jh"
    mapfile -t js_files < <(xrk_js_list_files)

    if [ ${#js_files[@]} -eq 0 ]; then
        echo -e "${caidan1}未找到任何 JS 插件${bg}"
        return
    fi

    echo -e "${caidan2}可用的 JS 插件:${bg}"
    for i in "${!js_files[@]}"; do
        echo -e "${caidan1}$i: ${js_files[$i]##*/}${bg}"
    done

    echo -e "${caidan2}输入你想要安装的插件编号(空格分隔，直接回车安装全部):${bg}"
    read -a selections

    if [ ${#selections[@]} -eq 0 ]; then
        mapfile -t selections < <(seq 0 $((${#js_files[@]}-1)))
    fi

    local selected_name_reply_js=false i selected_file

    for i in "${selections[@]}"; do
        if [[ $i =~ ^[0-9]+$ ]] && [ "$i" -ge 0 ] && [ "$i" -lt ${#js_files[@]} ]; then
            selected_file=${js_files[$i]}
            if [ "${selected_file##*/}" = "名称回复.js" ]; then
                selected_name_reply_js=true
            fi
            mv -n "$selected_file" "$jh/"
            echo -e "${caidan3}已安装 $(basename "$selected_file")${bg}"
        else
            echo -e "${caidan1}无效的选择: $i${bg}"
        fi
    done

    if [ "$selected_name_reply_js" = true ]; then
        echo -e "${caidan3}检测到名称回复插件，请配置机器人名字${bg}"
        add_text=$(menu_read_text "输入你想要的机器人名字: ")
        xrk_js_set_name_reply "$add_text" "$jh/名称回复.js" \
            && echo -e "${caidan2}机器人名字已更新为: ${add_text}${bg}" \
            || echo -e "${caidan1}名称无效或文件不存在${bg}"
    fi
}

show_menu() {
    menu_show "js插件" "安装全部 js 插件" "安装或更新向日葵插件" "修改名称回复机器人名字"
}

while true; do
    clear_menu
    show_menu
    mainmenu=$(menu_read_choice "请选择 [0-${MENU_OPT_COUNT}]，0/q 退出: ") || exit 0
    echo
    menu_should_exit "$mainmenu" quit && { echo -e "${caidan2}感谢使用！${bg}"; exit 0; }
    case "$mainmenu" in
        1)
            echo -e "${caidan3}正在克隆插件仓库...${bg}"
            xrk_js_clone_repo "$xrk" && select_js_plugins
            chmod 755 "$xrk" 2>/dev/null || true
            rm -rf "$xrk"
            echo -e "${caidan2}操作完成${bg}"
            ;;
        2)
            echo -e "${caidan2}去下载xrk-plugin吧，见鬼吧你，还在这安装${bg}"
            ;;
        3)
            add_text=$(menu_read_text "输入你想要的机器人名字: ")
            xrk_js_set_name_reply "$add_text" "$jh/名称回复.js" \
                && echo -e "${caidan2}机器人名字已更新为: ${add_text}${bg}" \
                || echo -e "${caidan1}名称无效或文件不存在${bg}"
            ;;
        *)
            menu_msg_err "无效选择 [0-${MENU_OPT_COUNT}]"
            ;;
    esac
    echo
done
