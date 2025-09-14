#!/bin/bash

function 葵崽升级 {
    declare -A files=(
        ["/usr/local/bin/nt"]="/xrk/body/writeto/nt"
        ["/usr/local/bin/lg"]="/xrk/body/writeto/lg"
        ["/usr/local/bin/xyz"]="/xrk/body/writeto/xrk/xyz"
        ["/usr/local/bin/xyzlogin"]="/xrk/body/writeto/xrk/xyzlogin"
        ["/usr/local/bin/xrk"]="/xrk/body/xrk"
    )
    for dest in "${!files[@]}"; do
        if [ -f "${files[$dest]}" ]; then
            cat "${files[$dest]}" > "$dest"
            chmod 755 "$dest"
        fi
    done
    cd $xyz && git pull
}

function 双崽linux脚本升级 {
    cat /xrk/body/Linux > /usr/local/bin/xrkk && chmod 755 /usr/local/bin/xrkk
}

function tmux配置检查 {
    echo "正在配置 oh my tmux..."
    if [ ! -d "$HOME/.tmux" ]; then
        echo "克隆 .tmux 配置仓库..."
        git clone https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
    fi
    if [ ! -d "$HOME/.tmux/plugins" ]; then
        mkdir -p "$HOME/.tmux/plugins"
    fi
    cd "$HOME/.tmux/plugins" || exit
    chmod 755 "$HOME/.tmux/plugins"
    chmod -R 755 ~/.tmux/plugins
    declare -A plugins=(
        ["tpm"]="https://github.com/tmux-plugins/tpm.git"
    )
    for plugin in "${!plugins[@]}"; do
        if [ ! -d "$plugin" ]; then
            echo "正在安装插件: $plugin"
            git clone "${plugins[$plugin]}" "$plugin"
        else
            echo "插件 $plugin 已存在，尝试更新..."
            cd "$plugin" || continue
            git pull --rebase --autostash
            cd ..
        fi
    done
    echo "tmux 配置与插件已完成安装和更新"
    cd $HOME
}

function ffmpeg配置检查 {
    if ! command -v ffmpeg &>/dev/null; then
     if grep -Eqi "Ubuntu" /etc/issue && grep -Eq "Ubuntu" /etc/*-release; then
     bash <(curl -sL https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/software/ffmpeg)
     elif grep -Eqi "Debian" /etc/issue && grep -Eq "Debian" /etc/*-release; then
     bash <(curl -sL https://raw.gitcode.com/Xrkseek/sunflower-yunzai-scripts/raw/master/Yunzai-install/software/ffmpeg)
    else
      echo "ffmpeg 未安装，开始安装 ffmpeg"
      install_package "ffmpeg"
     fi
    fi
}

function profile配置检查 {
    echo "检查 .profile 文件..."
    local profile="$HOME/.profile"
    local needed_lines=(
        "[[ -f /xrk/.init ]] && source /xrk/.init"
        "export PUPPETEER_SKIP_DOWNLOAD='true'"
    )
    if [ ! -f "$profile" ]; then
        touch "$profile"
    fi
    for line in "${needed_lines[@]}"; do
        if ! grep -Fxq "$line" "$profile"; then
            echo "$line" >> "$profile"
        fi
    done
}