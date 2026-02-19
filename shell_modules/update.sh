#!/bin/bash

function 葵崽升级 {
    declare -A files=(
        ["/usr/local/bin/nt"]="/xrk/body/writeto/nt"
        ["/usr/local/bin/xyz"]="/xrk/body/writeto/xrk/xyz"
        ["/usr/local/bin/xyzlogin"]="/xrk/body/writeto/xrk/xyzlogin"
        ["/usr/local/bin/xrk"]="/xrk/body/xrk"
        ["/usr/local/bin/xrk-tmux"]="/xrk/body/modules/tmux"
    )
    for dest in "${!files[@]}"; do
        if [ -f "${files[$dest]}" ]; then
            cat "${files[$dest]}" > "$dest"
            chmod 755 "$dest"
        fi
    done
    [ -n "$xyz" ] && [ -d "$xyz" ] && cd "$xyz" && git pull
}

function 双崽linux脚本升级 {
    cat /xrk/body/Linux > /usr/local/bin/xrkk && chmod 755 /usr/local/bin/xrkk
}

# 统一走 body/modules，避免重复逻辑
function tmux配置检查 {
    [ -f /xrk/body/modules/tmux ] && bash /xrk/body/modules/tmux || echo "未找到 /xrk/body/modules/tmux"
}

function ffmpeg配置检查 {
    # 使用 run_software 统一执行（支持远程/本地）
    if type run_software &>/dev/null; then
        run_software "body/modules/ffmpeg" || run_software "project-install/software/ffmpeg"
    else
        [ -f /xrk/body/modules/ffmpeg ] && bash /xrk/body/modules/ffmpeg || [ -f /xrk/project-install/software/ffmpeg ] && bash /xrk/project-install/software/ffmpeg
    fi
}

function profile配置检查 {
    [ -f /xrk/body/modules/profile ] && bash /xrk/body/modules/profile || echo "未找到 /xrk/body/modules/profile"
}