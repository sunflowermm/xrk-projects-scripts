#!/bin/bash
# 插件代理：测试并切换 GitHub 代理
root="${XRK_ROOT:-/xrk}"
# shellcheck source=/dev/null
[ -f "$root/shell_modules/menu_boot.sh" ] && source "$root/shell_modules/menu_boot.sh" || {
    [ -f "$HOME/.xrk_repo" ] && source "$HOME/.xrk_repo"
    source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/bootstrap.sh")
}
xrk_source_menu_head 0 1 github.sh plugin_proxy.sh

test_proxy() {
    local proxy="$1" rc=0
    xrk_test_github_proxy "$proxy"
    rc=$?
    case "$rc" in
        0) menu_msg_ok "✅ 代理可用: ${proxy}"; return 0 ;;
        1) menu_msg_warn "⚠️ 代理可用但响应偏慢: ${proxy}"; return 1 ;;
        *) menu_msg_err "❌ 代理不可用: ${proxy}"; return 2 ;;
    esac
}

change_proxy() {
    local target_dir=$1 plugin_name=$2
    local current_url fast_proxies=() proxy_opts=() selected_proxy choice

    menu_check_dir "$target_dir/.git" "$target_dir 不是Git仓库" || { menu_pause; return 1; }

    current_url=$(cd "$target_dir" && git config --get remote.origin.url)
    [ -z "$current_url" ] && { menu_msg_err "无法获取远程URL"; menu_pause; return 1; }

    menu_msg_warn "当前远程URL: $current_url"
    menu_msg_warn "正在测试代理速度..."

    mapfile -t fast_proxies < <(xrk_pick_fast_proxies 5)
    if [ ${#fast_proxies[@]} -eq 0 ]; then
        menu_msg_err "没有找到可用的快速代理"
        menu_pause
        return 1
    fi

    proxy_opts=("${fast_proxies[@]}" "不修改代理")
    menu_show "为 $plugin_name 选择代理" "${proxy_opts[@]}"
    choice=$(menu_read_choice "请选择 [1-${MENU_OPT_COUNT}]，q 跳过: ") || return
    menu_should_exit "$choice" quit && return

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$MENU_OPT_COUNT" ]; then
        if [ "$choice" -eq "$MENU_OPT_COUNT" ]; then
            menu_msg_warn "保持原有URL不变"
        else
            selected_proxy=${fast_proxies[$((choice-1))]}
            if xrk_apply_github_proxy "$target_dir" "$selected_proxy"; then
                menu_msg_ok "成功更新代理为: $selected_proxy"
                menu_msg_ok "插件更新成功！"
            else
                menu_msg_err "更新代理或拉取失败"
            fi
        fi
    else
        menu_msg_err
    fi
    menu_pause
}

manage_plugins() {
    local plugins_path="${XRK_DEL_PLUGINS:-$(xrk_yz_dir)/plugins}" filtered_dirs=() plugin_names=() input

    while true; do
        menu_check_dir "$plugins_path" "插件包目录不存在" || exit 1

        mapfile -t filtered_dirs < <(xrk_list_plugin_dirs "$plugins_path")
        if [ ${#filtered_dirs[@]} -eq 0 ]; then
            menu_msg_warn "没有找到可以管理的插件"
            exit 1
        fi

        plugin_names=()
        for dir in "${filtered_dirs[@]}"; do plugin_names+=("$(basename "$dir")"); done

        local plugin_opts=()
        for name in "${plugin_names[@]}"; do plugin_opts+=("📁 $name"); done
        menu_show "插件包目录" "${plugin_opts[@]}"

        input=$(menu_read_choice "输入要切换代理的插件序号 [1-${MENU_OPT_COUNT}]，0 或 q 退出: ") || exit 0
        menu_should_exit "$input" quit && { echo "程序已退出"; exit 0; }

        if menu_validate_input "$input" 1 ${#plugin_names[@]} "序号 $input 超出范围"; then
            change_proxy "${filtered_dirs[$((input-1))]}" "${plugin_names[$((input-1))]}"
            clear_menu
        else
            menu_pause
            clear_menu
        fi
    done
}

manage_plugins
