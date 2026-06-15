#!/bin/bash
# GitHub 访问：国内区域自动代理，海外直连（detect_region：IP → 时区回退）

_is_cn_region() {
    local region
    type detect_region &>/dev/null && region=$(detect_region 2>/dev/null) || region="overseas"
    [ "$region" = "cn" ]
}

# 代理列表：仅保留常见公共加速；探测时用 git ls-remote 验证（避免 HTTP 200 但 git 要登录的源）
PROXIES=(
    "https://gh-proxy.com"
    "https://ghfast.top"
    "https://ghp.ci"
    "https://mirror.ghproxy.com"
    "https://ghproxy.net"
    "https://ghproxy.com"
    "https://ghps.cc"
    "https://github.moeyy.xyz"
    "https://gitclone.com/github.com"
)

# 轻量 HTTP 探测（供 curl 下载等场景）
_xrk_http_ok() {
    curl -s --fail --connect-timeout 2 --max-time 4 -o /dev/null "$1" 2>/dev/null
}

# git 加速探测：必须能 ls-remote 且不弹登录（g.in0.re 等 HTTP 可用但 git 要账号的会被剔除）
_xrk_proxy_git_ok() {
    local proxy="$1" repo="${2:-https://github.com/tmux-plugins/tpm.git}"
    local proxied="${proxy}/${repo}"
    local out

    [ -z "$proxy" ] && return 1
    case "$proxy" in
        https://gitclone.com/github.com)
            proxied="${proxy}/${repo#https://github.com/}"
            ;;
    esac

    out=$(GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= git ls-remote --heads "$proxied" HEAD 2>/dev/null) || return 1
    [ -n "$out" ] || return 1
    return 0
}

# 随机挑选可用代理（git 实测，不缓存）
_xrk_pick_github_proxy() {
    local proxy
    if command -v shuf &>/dev/null; then
        while IFS= read -r proxy; do
            _xrk_proxy_git_ok "$proxy" && { echo "$proxy"; return 0; }
        done < <(printf "%s\n" "${PROXIES[@]}" | shuf)
    else
        for proxy in "${PROXIES[@]}"; do
            _xrk_proxy_git_ok "$proxy" && { echo "$proxy"; return 0; }
        done
    fi
    echo ""
}

# 剥离已有代理前缀，还原 github.com URL
_xrk_clean_github_url() {
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

# GitHub URL 处理：cn 自动加速（proxy/原URL），overseas 保持原样
# 用法：
#   getgh url_var     # 变量名，函数内部原地修改（老用法，向下兼容）
#   getgh "https://github.com/..."  # 直接传 URL，stdout 返回处理后的 URL（供 git() 等使用）
getgh() {
    local arg="$1" var_name="" original_url proxy="" new_url

    case "$arg" in
        https://github.com/*|https://raw.githubusercontent.com/*)
            original_url="$arg"
            ;;
        *)
            var_name="$arg"
            case "$var_name" in
                ''|*'['*|*']'*|*' '*|*'$'*|*'*'*|*'?'*|*'!'*)
                    return 0
                    ;;
            esac
            original_url="${!var_name}"
            case "$original_url" in
                https://github.com/*|https://raw.githubusercontent.com/*) ;;
                *) return 0 ;;
            esac
            ;;
    esac

    new_url="$original_url"

    if _is_cn_region; then
        if [ -n "${proxy_num:-}" ] && [ "${proxy_num}" != "0" ]; then
            proxy="${PROXIES[$((proxy_num-1))]:-}"
        else
            proxy="$(_xrk_pick_github_proxy)"
        fi
        if [ -n "$proxy" ]; then
            case "$proxy" in
                https://gitclone.com/github.com)
                    new_url="${proxy}/${original_url#https://github.com/}"
                    ;;
                *)
                    new_url="${proxy}/${original_url}"
                    ;;
            esac
        fi
    else
        if [ -n "${proxy_num:-}" ] && [ "${proxy_num}" != "0" ]; then
            proxy="${PROXIES[$((proxy_num-1))]:-}"
            if [ -n "$proxy" ]; then
                case "$proxy" in
                    https://gitclone.com/github.com)
                        new_url="${proxy}/${original_url#https://github.com/}"
                        ;;
                    *)
                        new_url="${proxy}/${original_url}"
                        ;;
                esac
            fi
        fi
    fi

    if [ -n "$var_name" ]; then
        printf -v "$var_name" '%s' "$new_url"
    else
        printf '%s\n' "$new_url"
    fi
}

# git 包装：国内区域 GitHub URL 自动加代理；禁止交互登录避免挂起
git() {
    local args=("$@") i
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[i]}" == https://github.com/* || "${args[i]}" == https://raw.githubusercontent.com/* ]]; then
            local __new
            __new=$(getgh "${args[i]}") || __new="${args[i]}"
            args[i]="$__new"
        fi
    done
    GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= command git "${args[@]}"
}

# 浅克隆 GitHub 仓库（国内走加速；失败则直连重试）
xrk_git_clone() {
    local url="$1" dest="$2" depth="${3:-1}"
    local direct

    [ -z "$url" ] || [ -z "$dest" ] && return 1
    command -v git &>/dev/null || return 1

    if git clone --depth="$depth" "$url" "$dest" 2>/dev/null; then
        return 0
    fi

    direct="$(_xrk_clean_github_url "$url")"
    case "$direct" in
        https://github.com/*|https://raw.githubusercontent.com/*)
            if [ "$direct" != "$url" ]; then
                echo "[git] 加速源失败，尝试直连: $direct" >&2
                GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= command git clone --depth="$depth" "$direct" "$dest" && return 0
            fi
            ;;
    esac
    return 1
}
