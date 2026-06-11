#!/bin/bash
# 文件删除公共逻辑（供 deletion.sh / deletiondialog.sh 复用）

# 校验条目名：禁止路径分隔符与 . ..
_xrk_safe_entry_name() {
    local name="$1"
    [ -n "$name" ] || return 1
    [[ "$name" == *"/"* ]] && return 1
    [[ "$name" == *"\\"* ]] && return 1
    [[ "$name" == "." || "$name" == ".." ]] && return 1
    return 0
}

_xrk_safe_base_dir() {
    local base="$1"
    [ -n "$base" ] || return 1
    [[ "$base" == "/" ]] && return 1
    [ -d "$base" ] || return 1
    return 0
}

# 删除 base 下多个条目，输出 deleted/failed 计数（通过变量名返回）
xrk_delete_items() {
    local base="$1" deleted_var="${2:-_deleted}" failed_var="${3:-_failed}"
    shift 3
    local items=("$@") item deleted=0 failed=0

    _xrk_safe_base_dir "$base" || {
        printf -v "$deleted_var" '%s' "0"
        printf -v "$failed_var" '%s' "${#items[@]}"
        return 1
    }

    for item in "${items[@]}"; do
        if ! _xrk_safe_entry_name "$item"; then
            failed=$((failed + 1))
            continue
        fi
        if rm -rf "$base/$item"; then
            deleted=$((deleted + 1))
        else
            failed=$((failed + 1))
        fi
    done
    printf -v "$deleted_var" '%s' "$deleted"
    printf -v "$failed_var" '%s' "$failed"
}

# 列出目录下一级条目名（每行一个；不含 . ..）
xrk_list_dir_entries() {
    local want_path="$1" entry
    [ -d "$want_path" ] || return 1
    while IFS= read -r entry; do
        _xrk_safe_entry_name "$entry" && printf '%s\n' "$entry"
    done < <(
        find "$want_path" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null \
            || find "$want_path" -mindepth 1 -maxdepth 1 -exec basename {} \;
    )
}

删除条目() { xrk_delete_items "$@"; }
列出目录条目() { xrk_list_dir_entries "$@"; }

# 文件管理常用路径（需已 menu_init / 已探测 yz）
xrk_deletion_paths() {
    local yz_dir
    yz_dir="$(type xrk_yz_dir &>/dev/null && xrk_yz_dir || echo "${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}")"
    XRK_DEL_PLUGINS="${yz_dir}/plugins"
    XRK_DEL_JS="${yz_dir}/plugins/other"
    XRK_DEL_BOT="${yz_dir}"
}
