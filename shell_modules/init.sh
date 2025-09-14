#!/bin/bash

# 初始化变量
function check_changes {
    export xyz=""
    export yz=""
    search_root="$HOME"
}

# 检查指定目录中的 package.json
function check_directory {
    local dir="$1"
    local package_file="$dir/package.json"
    
    # 如果文件存在
    if [[ -f "$package_file" ]]; then
        local name=$(cat "$package_file" | jq -r '.name // empty' 2>/dev/null)
        
        if [[ ! -z "$name" && "$name" == "xrk-yunzai" ]]; then
            if [[ -z "$xyz" ]]; then
                export xyz="$dir"
                export yz="$xyz"
            fi
            return 0
        fi
    fi
    return 1
}

# 优先搜索常见目录
function search_common_paths {
    local common_paths=(
        "$HOME/XRK-Yunzai"
    )
    
    for path in "${common_paths[@]}"; do
        if check_directory "$path"; then
            return 0
        fi
    done
    return 1
}

# 扩展搜索所有目录
function search_all_directories {
    find "$search_root" -type f -name "package.json" ! -path "*/node_modules/*" -print0 | while IFS= read -r -d $'\0' package_file; do
        if check_directory "$(dirname "$package_file")"; then
            return 0
        fi
    done
}

# 主搜索函数
function search_directories {
    if ! search_common_paths; then
        search_all_directories
    fi
    
    if [[ -n "$xyz" ]]; then
        echo "找到葵崽目录: $xyz"
    else
        echo "未找到 xrk-yunzai 安装"
        return 1
    fi
}