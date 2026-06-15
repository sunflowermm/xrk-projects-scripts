#!/bin/bash
# 插件 GitHub 代理：探测、筛选、应用（供 proxy.sh / diaproxy.sh 复用）
# 依赖：github.sh 已加载 PROXIES[]

XRK_PLUGIN_FILTER_DIRS=('example' 'other' 'system' 'adapter')
XRK_PROXY_CHECK_PATH="${XRK_PROXY_CHECK_PATH:-NapNeko/NapCatQQ/main/package.json}"
XRK_PROXY_SPEED_THRESHOLD="${XRK_PROXY_SPEED_THRESHOLD:-2}"
XRK_PROXY_CURL_TIMEOUT="${XRK_PROXY_CURL_TIMEOUT:-3}"
XRK_PROXY_GIT_CHECK_REPO="${XRK_PROXY_GIT_CHECK_REPO:-https://github.com/tmux-plugins/tpm.git}"

# 剥离已有代理前缀，还原为 github.com URL
xrk_clean_github_url() {
    type _xrk_clean_github_url &>/dev/null && _xrk_clean_github_url "$@" && return 0
    local url="$1"
    url=$(echo "$url" | sed -E '
        s|^https?://[^/]+/https://github\.com|https://github.com|;
        s|^https?://[^/]+/github\.com|https://github.com|;
        s|^https?://gitclone\.com/github\.com/|https://github.com/|;
        s|^https?://gh(proxy)?[.][^/]+/|https://|;
        s|/$||
    ')
    echo "$url"
}

# 测试单个代理：0=快速可用 1=慢 2=不可用（HTTP raw + git ls-remote 双重校验）
xrk_test_github_proxy() {
    local proxy="$1"
    local proxied_check_url="${proxy}/https://raw.githubusercontent.com/${XRK_PROXY_CHECK_PATH}"
    local result http_code time_total

    [ -z "$proxy" ] && return 2
    type _xrk_proxy_git_ok &>/dev/null || return 2
    _xrk_proxy_git_ok "$proxy" "$XRK_PROXY_GIT_CHECK_REPO" || return 2

    result=$(curl --silent --fail --max-time "$XRK_PROXY_CURL_TIMEOUT" -w "%{http_code} %{time_total}" -o /dev/null "$proxied_check_url" 2>/dev/null) || return 2
    http_code=$(echo "$result" | awk '{print $1}')
    time_total=$(echo "$result" | awk '{print $2}')
    [ "$http_code" = "200" ] || return 2
    awk "BEGIN{exit($time_total<$XRK_PROXY_SPEED_THRESHOLD?0:1)}" && return 0
    return 1
}

# 随机测试代理，输出最快的前 N 个（每行一个 URL）
xrk_pick_fast_proxies() {
    local max="${1:-5}" proxy
    local -a fast=()
    local -a shuffled=()

    if command -v shuf &>/dev/null; then
        mapfile -t shuffled < <(printf "%s\n" "${PROXIES[@]}" | shuf)
    else
        shuffled=("${PROXIES[@]}")
    fi

    for proxy in "${shuffled[@]}"; do
        xrk_test_github_proxy "$proxy" || continue
        fast+=("$proxy")
        [ "${#fast[@]}" -ge "$max" ] && break
    done
    printf '%s\n' "${fast[@]}"
}

# 返回第一个可用代理（stdout），失败返回非 0
xrk_pick_best_proxy() {
    xrk_pick_fast_proxies 1 | head -n1
}

# 列出可管理插件目录（过滤系统目录），每行一个绝对路径
xrk_list_plugin_dirs() {
    local plugins_path="$1" dir base_name filter should_filter

    [ -d "$plugins_path" ] || return 1
    while IFS= read -r -d '' dir; do
        base_name=$(basename "$dir")
        should_filter=false
        for filter in "${XRK_PLUGIN_FILTER_DIRS[@]}"; do
            [ "$base_name" = "$filter" ] && { should_filter=true; break; }
        done
        [ "$should_filter" = false ] && echo "$dir"
    done < <(find "$plugins_path" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
}

# 将 GitHub 远程 URL 加上代理并尝试 git pull
xrk_apply_github_proxy() {
    local target_dir="$1" proxy="$2"
    local current_url clean new_url

    [ -d "$target_dir/.git" ] || return 1
    current_url=$(cd "$target_dir" && git config --get remote.origin.url)
    [ -z "$current_url" ] && return 1
    clean=$(xrk_clean_github_url "$current_url")
    [[ "$clean" == https://github.com/* ]] || return 2

    case "$proxy" in
        https://gitclone.com/github.com)
            new_url="${proxy}/${clean#https://github.com/}"
            ;;
        *)
            new_url="${proxy}/${clean}"
            ;;
    esac
    (cd "$target_dir" && git config remote.origin.url "$new_url" && git pull)
}

清理GitHub地址() { xrk_clean_github_url "$@"; }
测试GitHub代理() { xrk_test_github_proxy "$@"; }
挑选最快代理() { xrk_pick_fast_proxies "$@"; }
应用GitHub代理() { xrk_apply_github_proxy "$@"; }
列出插件目录() { xrk_list_plugin_dirs "$@"; }
