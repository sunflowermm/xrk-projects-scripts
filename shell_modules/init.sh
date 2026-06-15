#!/bin/bash
# 葵崽(XRK-Yunzai) / 葵子(XRK-AGT) 路径检测（供 .init / xrk / 菜单 使用）
# 约定：先检查默认目录与缓存路径，再按 package.json name 深度搜索

KUIZI_PKG_YUNZAI="${KUIZI_PKG_YUNZAI:-xrk-yunzai}"
KUIZI_PKG_AGT="${KUIZI_PKG_AGT:-xrk-agt}"

_read_pkg_name() {
    local dir="$1" name
    [ -f "$dir/package.json" ] || return 1
    name=$(jq -r '.name // empty' "$dir/package.json" 2>/dev/null)
    if [ -z "$name" ]; then
        name=$(grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' "$dir/package.json" 2>/dev/null \
            | head -1 | sed -n 's/.*"\([^"]*\)"$/\1/p')
    fi
    [ -n "$name" ] && echo "$name"
}

_bind_product_dir() {
    local dir="$1" pkg="$2"
    case "$pkg" in
        "$KUIZI_PKG_YUNZAI")
            [ -n "${yz:-}" ] && return 0
            export yz="$dir" xyz="$dir"
            ;;
        "$KUIZI_PKG_AGT")
            [ -n "${agt:-}" ] && return 0
            export agt="$dir"
            ;;
    esac
}

_try_register_dir() {
    local dir="$1" name
    name=$(_read_pkg_name "$dir") || return 1
    case "$name" in
        "$KUIZI_PKG_YUNZAI") _bind_product_dir "$dir" "$KUIZI_PKG_YUNZAI" ;;
        "$KUIZI_PKG_AGT")    _bind_product_dir "$dir" "$KUIZI_PKG_AGT" ;;
        *) return 1 ;;
    esac
}

_check_cached_path() {
    local dir="$1" pkg="$2" name
    [ -n "$dir" ] || return 1
    [ -d "$dir" ] || return 1
    name=$(_read_pkg_name "$dir") || return 1
    [ "$name" = "$pkg" ]
}

check_changes() {
    local ok_yz=0 ok_agt=0

    if [ -n "${xyz:-}" ] && _check_cached_path "$xyz" "$KUIZI_PKG_YUNZAI"; then
        export yz="$xyz"
        ok_yz=1
    else
        unset yz xyz
    fi

    if [ -n "${agt:-}" ] && _check_cached_path "$agt" "$KUIZI_PKG_AGT"; then
        ok_agt=1
    else
        unset agt
    fi

    [ "$ok_yz" = "1" ] || [ "$ok_agt" = "1" ]
}

search_common_paths() {
    _try_register_dir "${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}"
    _try_register_dir "${AGT_DEFAULT_DIR:-$HOME/XRK-AGT}"
}

search_all_directories() {
    local dir
    while IFS= read -r -d '' dir; do
        _try_register_dir "$dir"
        [ -n "${yz:-}" ] && [ -n "${agt:-}" ] && return 0
    done < <(find "${search_root:-$HOME}" -maxdepth 5 -type d -print0 2>/dev/null)
    return 1
}

search_directories() {
    search_common_paths
    [ -n "${yz:-}" ] && [ -n "${agt:-}" ] && return 0
    search_all_directories
}

检测葵崽路径() { search_directories; }
刷新葵崽路径() { check_changes; search_directories; }

# 兼容旧名
check_directory() { _try_register_dir "$1"; }
