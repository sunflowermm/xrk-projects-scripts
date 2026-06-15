#!/bin/bash
# 葵崽 / 葵子 三仓库（GitCode · Gitee · GitHub）克隆、记录源、拉取

[ -f "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/xrk_config.sh"

KUIZI_SOURCE_GITCODE=1
KUIZI_SOURCE_GITHUB=2
KUIZI_SOURCE_GITEE=3

# 解析当前应使用的源（与脚本仓库 XRK_SOURCE 对齐）
kuizi_resolve_source_num() {
    local key="${KUIZI_SOURCE:-${XRK_SOURCE:-}}"
    if [ -z "$key" ] && [ -f "${XRK_ROOT:-/xrk}/.repo_source" ]; then
        # shellcheck source=/dev/null
        source "${XRK_ROOT:-/xrk}/.repo_source"
        case "${SCRIPT_CLONE_URL:-}" in
            *gitcode.com*) key=1 ;;
            *github.com*)  key=2 ;;
            *gitee.com*)   key=3 ;;
        esac
    fi
    case "${key:-3}" in
        1) echo 1 ;;
        2) echo 2 ;;
        *) echo 3 ;;
    esac
}

kuizi_source_key() {
    case "$(kuizi_resolve_source_num)" in
        1) echo gitcode ;;
        2) echo github ;;
        *) echo gitee ;;
    esac
}

kuizi_source_label() {
    case "$(kuizi_source_key)" in
        gitcode) echo "GitCode" ;;
        github)  echo "GitHub" ;;
        *)       echo "Gitee" ;;
    esac
}

kuizi_clone_url() {
    local product="$1" key="${2:-$(kuizi_source_key)}"
    case "$product" in
        yunzai|yz|葵崽)
            case "$key" in
                gitcode) echo "$YZ_REPO_GITCODE" ;;
                github)  echo "$YZ_REPO_GITHUB" ;;
                *)       echo "$YZ_REPO_GITEE" ;;
            esac
            ;;
        agt|葵子)
            case "$key" in
                gitcode) echo "$AGT_REPO_GITCODE" ;;
                github)  echo "$AGT_REPO_GITHUB" ;;
                *)       echo "$AGT_REPO_GITEE" ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

kuizi_list_mirror_urls() {
    local product="$1"
    case "$product" in
        yunzai|yz|葵崽)
            echo "  GitCode: $YZ_REPO_GITCODE"
            echo "  Gitee:   $YZ_REPO_GITEE"
            echo "  GitHub:  $YZ_REPO_GITHUB"
            ;;
        agt|葵子)
            echo "  GitCode: $AGT_REPO_GITCODE"
            echo "  Gitee:   $AGT_REPO_GITEE"
            echo "  GitHub:  $AGT_REPO_GITHUB"
            ;;
    esac
}

kuizi_read_product_source() {
    local dir="$1"
    [ -f "$dir/.repo_source" ] || return 1
    KUIZI_CLONE_URL=$(grep -E '^KUIZI_CLONE_URL=' "$dir/.repo_source" 2>/dev/null \
        | head -1 | cut -d= -f2- | tr -d '"')
    KUIZI_SOURCE=$(grep -E '^KUIZI_SOURCE=' "$dir/.repo_source" 2>/dev/null \
        | head -1 | cut -d= -f2- | tr -d '"')
    [ -n "$KUIZI_CLONE_URL" ]
}

kuizi_write_product_source() {
    local dir="$1" product="$2" url="$3" num
    num=$(kuizi_resolve_source_num)
    printf 'KUIZI_PRODUCT="%s"\nKUIZI_SOURCE="%s"\nKUIZI_CLONE_URL="%s"\n' \
        "$product" "$num" "$url" > "$dir/.repo_source"
}

kuizi_git_remote_url() {
    local dir="$1"
    [ -d "$dir/.git" ] || return 1
    git -C "$dir" remote get-url origin 2>/dev/null
}

kuizi_product_source_display() {
    local dir="$1" product="$2" url label
    if kuizi_read_product_source "$dir"; then
        label=$(kuizi_source_label_from_num "${KUIZI_SOURCE:-3}")
        echo "${label} (${KUIZI_CLONE_URL})"
        return 0
    fi
    url=$(kuizi_git_remote_url "$dir") || { echo "未知"; return 1; }
    echo "$(kuizi_source_label_from_url "$url") ($url)"
}

kuizi_source_label_from_num() {
    case "$1" in
        1) echo "GitCode" ;;
        2) echo "GitHub" ;;
        *) echo "Gitee" ;;
    esac
}

kuizi_source_label_from_url() {
    case "$1" in
        *gitcode.com*) echo "GitCode" ;;
        *github.com*)  echo "GitHub" ;;
        *gitee.com*)   echo "Gitee" ;;
        *) echo "其他" ;;
    esac
}

kuizi_git_clone_dir() {
    local url="$1" dest="$2" label="$3"
    echo "[$label] git clone $url"
    git clone --depth=1 "$url" "$dest"
}

kuizi_clone_nested_repo() {
    local base="$1" rel="$2" url="$3" dest="$base/$rel"
    if [ -d "$dest/.git" ]; then
        echo "[子仓库] 已存在: $rel"
        return 0
    fi
    mkdir -p "$(dirname "$dest")"
    if type xrk_git_clone &>/dev/null; then
        xrk_git_clone "$url" "$dest"
    else
        kuizi_git_clone_dir "$url" "$dest" "$rel"
    fi
}

kuizi_install_yunzai_extras() {
    local yz_dir="$1"
    local miao_path miao_url genshin_path genshin_url
    miao_path="${YZ_EXTRA_MIAO%%|*}"
    miao_url="${YZ_EXTRA_MIAO#*|}"
    genshin_path="${YZ_EXTRA_GENSHIN%%|*}"
    genshin_url="${YZ_EXTRA_GENSHIN#*|}"
    [ -f "${XRK_ROOT:-/xrk}/shell_modules/github.sh" ] && \
        # shellcheck source=/dev/null
        source "${XRK_ROOT}/shell_modules/github.sh"
    kuizi_clone_nested_repo "$yz_dir" "$miao_path" "$miao_url"
    kuizi_clone_nested_repo "$yz_dir" "$genshin_path" "$genshin_url"
    export PUPPETEER_SKIP_DOWNLOAD='true'
    echo "[葵崽] 更新 puppeteer…"
    (cd "$yz_dir" && pnpm update puppeteer@19.8.3 -w)
}

kuizi_clone_product() {
    local product="$1" dest="$2" name="$3" url key
    key=$(kuizi_source_key)
    url=$(kuizi_clone_url "$product" "$key") || return 1
    kuizi_git_clone_dir "$url" "$dest" "$name" || return 1
    kuizi_write_product_source "$dest" "$product" "$url"
}

kuizi_pull_git_dir() {
    local dir="$1" label="$2"
    [ -d "$dir/.git" ] || { echo "[$label] 非 git 目录，跳过: $dir"; return 1; }
    echo "[$label] git pull …"
    (cd "$dir" && git pull --no-rebase)
}

kuizi_pull_yunzai_tree() {
    local root="$1"
    [ -d "$root" ] || return 1
    kuizi_pull_git_dir "$root" "葵崽主仓库"
    kuizi_pull_git_dir "$root/plugins/miao-plugin" "葵崽/miao-plugin"
    kuizi_pull_git_dir "$root/plugins/genshin" "葵崽/genshin"
}

kuizi_pull_agt_tree() {
    local root="$1"
    [ -d "$root" ] || return 1
    kuizi_pull_git_dir "$root" "葵子主仓库"
}

kuizi_upgrade_products() {
    local _yz _agt
    type check_changes &>/dev/null && check_changes
    type search_directories &>/dev/null && search_directories
    _yz="${yz:-${xyz:-}}"
    _agt="${agt:-}"
    [ -n "$_yz" ] && [ -d "$_yz" ] && kuizi_pull_yunzai_tree "$_yz"
    [ -n "$_agt" ] && [ -d "$_agt" ] && kuizi_pull_agt_tree "$_agt"
}
