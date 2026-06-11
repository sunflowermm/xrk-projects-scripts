#!/bin/bash
# JS 插件安装公共逻辑（供 js.sh / jsdialog.sh 复用）

XRK_JS_REPO_URL="${XRK_JS_REPO_URL:-https://gitcode.com/Xrkseek/collection-of-jses.git}"

xrk_js_init_paths() {
    XRK_JS_REPO="${XRK_JS_REPO:-$HOME/xrk}"
    local _yz
    _yz="${yz:-${xyz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}}"
    YZ_PLUGINS_JS="${YZ_PLUGINS_JS:-${_yz}/plugins/other}"
    YZ_RESOURCES="${YZ_RESOURCES:-${_yz}/resources}"
}

# 临时克隆 JS 仓库（安装后由调用方删除 dest）
xrk_js_clone_repo() {
    local dest="${1:-${XRK_JS_REPO:-$HOME/xrk}}"
    xrk_js_init_paths
    rm -rf "$dest"
    if type xrk_git_clone &>/dev/null; then
        xrk_git_clone "$XRK_JS_REPO_URL" "$dest"
    else
        git clone --depth=1 "$XRK_JS_REPO_URL" "$dest"
    fi
}

# 安装 vocal 类插件：资源目录 + js 目录
xrk_js_move_vocal() {
    local vocal_dir="$1" plugin_dir="$2"
    xrk_js_init_paths

    if [ -d "$YZ_RESOURCES/$vocal_dir" ]; then
        echo -e "${caidan1:-}已经安装过${vocal_dir}了，正在跳过${bg:-}"
    else
        mv -f "$XRK_JS_REPO/shell-js/$vocal_dir" "$YZ_RESOURCES/"
        echo -e "${caidan3:-}已安装 ${vocal_dir}${bg:-}"
    fi

    mkdir -p "$YZ_PLUGINS_JS"
    if [ -d "$YZ_PLUGINS_JS/$plugin_dir" ]; then
        echo -e "${caidan2:-}已经安装过${plugin_dir}了，正在跳过${bg:-}"
    else
        mv -f "$XRK_JS_REPO/shell-js/$plugin_dir" "$YZ_PLUGINS_JS/"
        echo -e "${caidan3:-}已安装 ${plugin_dir}${bg:-}"
    fi
}

# 列出 shell-js 下可用 .js 文件路径（数组友好：逐行输出）
xrk_js_list_files() {
    xrk_js_init_paths
    find "$XRK_JS_REPO/shell-js/" -maxdepth 1 -type f -name "*.js" 2>/dev/null
}

# 更新名称回复.js 第 11 行引号内文本
xrk_js_set_name_reply() {
    local bot_name="$1" target="${2:-}"
    xrk_js_init_paths
    target="${target:-$YZ_PLUGINS_JS/名称回复.js}"
    [ -f "$target" ] || return 1
    # 避免 sed 注入：拒绝含单引号的名字
    [[ "$bot_name" == *"'"* ]] && return 1
    sed -i "11 s/'[^']*'/'${bot_name}'/" "$target"
}

初始化JS路径() { xrk_js_init_paths; }
克隆JS仓库() { xrk_js_clone_repo "$@"; }
