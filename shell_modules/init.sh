#!/bin/bash
# 葵崽(XRK-Yunzai)路径检测：check_changes、search_directories（供 .init / xrk / 菜单 使用）
# 约定：search_root 默认 $HOME，最多检测 5 级目录；先检查标志目录(plugins/XRK、plugins/other)，
#       再读 package.json 确认 name=xrk-yunzai，避免扫描 node_modules 等影响性能

XRK_MARKER_DIRS="plugins/XRK plugins/other"

check_changes() {
    export xyz=""
    export yz=""
    search_root="${search_root:-$HOME}"
}

check_directory() {
    local dir="$1" name
    [ ! -f "$dir/package.json" ] && return 1
    name=$(jq -r '.name // empty' "$dir/package.json" 2>/dev/null)
    [ -z "$name" ] || [ "$name" != "xrk-yunzai" ] && return 1
    [ -z "${xyz:-}" ] && export xyz="$dir" yz="$dir"
    return 0
}

# 若目录下存在 XRK 专属子目录则认为是候选，再读 package.json 确认
has_xrk_marker() {
    local dir="$1" sub
    for sub in $XRK_MARKER_DIRS; do
        [ -d "$dir/$sub" ] && return 0
    done
    return 1
}

search_common_paths() {
    check_directory "${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
}

# 最多 5 级目录；先按专属目录筛选再读 package.json
search_all_directories() {
    local dir
    while IFS= read -r -d $'\0' dir; do
        has_xrk_marker "$dir" && check_directory "$dir" && return 0
    done < <(find "$search_root" -maxdepth 5 -type d -print0 2>/dev/null)
    return 1
}

search_directories() {
    search_common_paths || search_all_directories
}