#!/data/data/com.termux/files/usr/bin/bash

# 脚本仓库源：由调用方 export SCRIPT_RAW_BASE，未设置则默认 GitCode
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
if [[ "$SCRIPT_RAW_BASE" == *"raw.gitcode.com"* ]]; then
    FONT_URL="https://gitcode.com/Xrkseek/xrk-projects-scripts/releases/download/font"
elif [[ "$SCRIPT_RAW_BASE" == *"raw.githubusercontent.com"* ]]; then
    FONT_URL="https://github.com/sunflowermm/xrk-projects-scripts/releases/download/font"
else
    FONT_URL="https://gitee.com/xrkseek/xrk-projects-scripts/releases/download/font"
fi
Termux_URL="$SCRIPT_RAW_BASE/Termux-container"

# 修改键盘和字体布局
function 字体键盘魔法() {
    local font_dir="$HOME/.termux"
    local font_file="$font_dir/font.ttf"
    local prop_file="$font_dir/termux.properties"
    # 使用 Termux 的临时目录而不是 /tmp
    local temp_dir="$HOME/.cache"
    local temp_font="$temp_dir/font.ttf.tmp"
    local temp_prop="$temp_dir/termux.properties.tmp"
    local need_reload=false

    # 创建必要的目录
    mkdir -p "$font_dir"
    mkdir -p "$temp_dir"

    # 处理字体文件
    echo "检查字体文件..."
    if curl -L -o "$temp_font" "${FONT_URL}/font.ttf"; then
        if [ -f "$font_file" ] && cmp -s "$temp_font" "$font_file"; then
            echo "字体文件无需更新"
            rm -f "$temp_font"
        else
            mv "$temp_font" "$font_file"
            echo "字体文件已更新"
            need_reload=true
        fi
    else
        echo "字体下载失败"
        rm -f "$temp_font"
    fi

    # 处理键盘布局文件
    echo "检查键盘布局..."
    if curl -L -o "$temp_prop" "${Termux_URL}/termux.properties"; then
        if [ -f "$prop_file" ] && cmp -s "$temp_prop" "$prop_file"; then
            echo "键盘布局无需更新"
            rm -f "$temp_prop"
        else
            mv "$temp_prop" "$prop_file"
            chmod 644 "$prop_file"
            echo "键盘布局已更新"
            need_reload=true
        fi
    else
        echo "键盘布局下载失败"
        rm -f "$temp_prop"
    fi

    # 只在有更新时才reload
    if [ "$need_reload" = true ]; then
        termux-reload-settings
        echo "设置已更新并重载"
    else
        echo "无需重载"
    fi
}

# 换源与安装必备软件包
function 换源魔法() {
    bash <(curl -sL "$SCRIPT_RAW_BASE/Termux-container/repo.sh")
    yes | apt update -y || { echo "更新失败"; return 1; }
    
    local packages=("tar" "proot" "wget" "git")
    local need_install=()
    
    for pkg in "${packages[@]}"; do
        command -v "$pkg" &>/dev/null || need_install+=("$pkg")
    done
    
    [ ${#need_install[@]} -gt 0 ] && pkg install -y "${need_install[@]}" || echo "必备软件包已安装"
}