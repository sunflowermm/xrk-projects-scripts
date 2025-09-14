#!/data/data/com.termux/files/usr/bin/bash

FONT_URL="https://gitcode.com/Xrkseek/sunflower-yunzai-scripts/releases/download/font"
Termux_URL="https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Termux-container"

#修改键盘和字体布局
function 字体键盘魔法() {
    local font_dir="$HOME/.termux"
    local font_file="$font_dir/font.ttf"
    local prop_file="$font_dir/termux.properties"
    local font_url="${FONT_URL}/font.ttf"
    local prop_url="${Termux_URL}/termux.properties"
    local need_reload=false

    mkdir -p "$font_dir"

    # 获取远程文件大小
    local remote_font_size=$(curl -sI "$font_url" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    local remote_prop_size=$(curl -sI "$prop_url" | grep -i "content-length" | awk '{print $2}' | tr -d '\r')
    
    # 获取本地文件大小
    local local_font_size=0
    local local_prop_size=0
    if [ -f "$font_file" ]; then
        local_font_size=$(stat -c%s "$font_file" 2>/dev/null || stat -f%z "$font_file" 2>/dev/null || echo "0")
    fi
    if [ -f "$prop_file" ]; then
        local_prop_size=$(stat -c%s "$prop_file" 2>/dev/null || stat -f%z "$prop_file" 2>/dev/null || echo "0")
    fi

    # 检查字体文件
    if [ ! -f "$font_file" ] || [ "$local_font_size" != "$remote_font_size" ]; then
        echo "下载字体文件..."
        curl -L -o "$font_file" "$font_url"
        if [ $? -eq 0 ]; then
            echo "字体文件下载成功"
            need_reload=true
        else
            echo "字体文件下载失败"
            return 1
        fi
    else
        echo "字体文件已是最新版本"
    fi

    # 检查键盘布局文件
    if [ ! -f "$prop_file" ] || [ "$local_prop_size" != "$remote_prop_size" ]; then
        echo "下载键盘布局..."
        curl -L -o "$prop_file" "$prop_url"
        if [ $? -eq 0 ]; then
            echo "键盘布局下载成功"
            need_reload=true
        else
            echo "键盘布局下载失败"
            return 1
        fi
    else
        echo "键盘布局已是最新版本"
    fi

    # 只在有更新时才reload
    if [ "$need_reload" = true ]; then
        termux-reload-settings
        echo "字体和键盘布局设置已更新并重载。"
    else
        echo "字体和键盘布局无需更新。"
    fi
}

#换源与安装必备软件包
function 换源魔法() {
    bash <(curl -sL https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Termux-container/repo.sh)
    yes | apt update -y || { echo "更新失败，请检查网络连接"; exit 1; }
    
    # 检查并安装必备软件包
    local packages=("tar" "proot" "wget" "git")
    local need_install=()
    
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" &>/dev/null; then
            need_install+=("$pkg")
        fi
    done
    
    if [ ${#need_install[@]} -gt 0 ]; then
        echo "需要安装的软件包: ${need_install[*]}"
        pkg install -y "${need_install[@]}"
    else
        echo "所有必备软件包已安装"
    fi
}