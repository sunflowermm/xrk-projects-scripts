#!/bin/bash
# GitHub 访问：国内区域自动代理，海外直连（detect_region：IP → 时区回退）

_is_cn_region() {
    case "${XRK_REGION:-}" in
        cn) return 0 ;;
        overseas) return 1 ;;
    esac
    case "${XRK_SOURCE:-}" in
        3|cn) return 0 ;;
    esac
    local region
    type detect_region &>/dev/null && region=$(detect_region 2>/dev/null) || region="overseas"
    [ "$region" = "cn" ]
}

# 直连 GitHub URL → 代理前缀 URL
_xrk_proxied_url() {
    local proxy="$1" direct="$2"
    case "$proxy" in
        https://gitclone.com/github.com)
            echo "${proxy}/${direct#https://github.com/}"
            ;;
        *)
            echo "${proxy}/${direct}"
            ;;
    esac
}

_xrk_cache_proxy_from_clone_url() {
    local url="$1" p
    for p in "${PROXIES[@]}"; do
        case "$url" in
            "${p}"/*) _XRK_GITHUB_PROXY_CACHED="$p"; return 0 ;;
        esac
    done
    return 1
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

# git 加速探测：ls-remote 能拿到 ref 即视为可用
_xrk_git_ls_remote() {
    local url="$1" git_bin out
    git_bin=$(command -v git) || return 1
    if command -v timeout &>/dev/null; then
        out=$(timeout 12 env GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= \
            "$git_bin" ls-remote -q "$url" HEAD 2>/dev/null) || return 1
    else
        out=$(GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= \
            "$git_bin" -c http.lowSpeedLimit=1000 -c http.lowSpeedTime=5 \
            ls-remote -q "$url" HEAD 2>/dev/null) || return 1
    fi
    [ -n "$out" ] || return 1
    printf '%s\n' "$out"
}

_XRK_GITHUB_PROBE_REPO="${_XRK_GITHUB_PROBE_REPO:-https://github.com/octocat/Hello-World.git}"

# HTTP 回退：部分代理 raw 可用但 ls-remote 偶发失败
_xrk_proxy_http_ok() {
    local proxy="$1"
    local path="${2:-octocat/Hello-World/master/README}"
    _xrk_http_ok "${proxy}/https://raw.githubusercontent.com/${path}"
}

_xrk_proxy_git_ok() {
    local proxy="$1" repo="${2:-$_XRK_GITHUB_PROBE_REPO}"
    local proxied="${proxy}/${repo}" out

    [ -z "$proxy" ] && return 1
    proxied="$(_xrk_proxied_url "$proxy" "$repo")"

    out=$(_xrk_git_ls_remote "$proxied") && [ -n "$out" ] && return 0
    _xrk_proxy_http_ok "$proxy" && return 0
    return 1
}

# 挑选可用代理：优先 gh-proxy.com，其余随机；失败时逐条打日志
_xrk_pick_github_proxy() {
    local proxy tried=0
    local -a order=()

    [ -n "${_XRK_GITHUB_PROXY_CACHED:-}" ] && { echo "$_XRK_GITHUB_PROXY_CACHED"; return 0; }

    echo "[git] 探测 GitHub 加速（${#PROXIES[@]} 个源）…" >&2

    order=("https://gh-proxy.com")
    if command -v shuf &>/dev/null; then
        while IFS= read -r proxy; do
            [ "$proxy" = "https://gh-proxy.com" ] && continue
            order+=("$proxy")
        done < <(printf "%s\n" "${PROXIES[@]}" | shuf)
    else
        for proxy in "${PROXIES[@]}"; do
            [ "$proxy" = "https://gh-proxy.com" ] && continue
            order+=("$proxy")
        done
    fi

    for proxy in "${order[@]}"; do
        tried=$((tried + 1))
        if _xrk_proxy_git_ok "$proxy"; then
            _XRK_GITHUB_PROXY_CACHED="$proxy"
            echo "[git] 加速可用: ${proxy#https://}（第 ${tried} 个）" >&2
            echo "$proxy"
            return 0
        fi
        echo "[git]   不可用: ${proxy#https://}" >&2
    done

    echo "[git] 探测无可用加速（已试 ${tried} 个），clone 时将依次尝试直连与各代理" >&2
    echo ""
}

# 剥离已有代理前缀，还原 github.com URL（供 git / tmux 模块等复用）
xrk_clean_github_url() {
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

# 单次 clone：带标签与失败原因（不再吞 stderr）
_xrk_git_clone_once() {
    local label="$1" url="$2" dest="$3" depth="$4"
    local errf last_line rc git_bin

    git_bin=$(command -v git) || { echo "[git] 未找到 git" >&2; return 1; }
    errf="${TMPDIR:-/tmp}/xrk_git_err_$$_${RANDOM}"
    echo "[git] → ${label}" >&2
    rm -rf "$dest" 2>/dev/null || true

    if command -v timeout &>/dev/null; then
        timeout 90 env GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= \
            "$git_bin" clone --depth="$depth" "$url" "$dest" 2>"$errf"
    else
        GIT_TERMINAL_PROMPT=0 GIT_ASKPASS= \
            "$git_bin" clone --depth="$depth" "$url" "$dest" 2>"$errf"
    fi
    rc=$?

    if [ "$rc" -eq 0 ] && [ -d "$dest/.git" ]; then
        echo "[git] ✓ ${label}" >&2
        rm -f "$errf"
        return 0
    fi

    last_line=$(tail -n 1 "$errf" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    case "$rc" in
        124) echo "[git] ✗ ${label}（超时 90s）" >&2 ;;
        *)
            if [ -n "$last_line" ]; then
                echo "[git] ✗ ${label}: ${last_line}" >&2
            else
                echo "[git] ✗ ${label}" >&2
            fi
            ;;
    esac
    rm -f "$errf"
    rm -rf "$dest" 2>/dev/null || true
    return 1
}

_xrk_git_clone_add_attempt() {
    local url="$1" label="$2" u
    local -n _urls=$3 _labels=$4
    [ -z "$url" ] && return 0
    for u in "${_urls[@]}"; do
        [ "$u" = "$url" ] && return 0
    done
    _urls+=("$url")
    _labels+=("$label")
}

# 浅克隆 GitHub 仓库：缓存代理 → 探测代理 → 直连 → 全部代理（逐步打日志）
xrk_git_clone() {
    local url="$1" dest="$2" depth="${3:-1}"
    local direct name region proxy proxied i
    local -a urls=() labels=()

    [ -z "$url" ] || [ -z "$dest" ] && return 1
    command -v git &>/dev/null || { echo "[git] 未找到 git" >&2; return 1; }

    direct="$(xrk_clean_github_url "$url")"
    name="${direct##*/}"
    region="overseas"
    type detect_region &>/dev/null && region=$(detect_region 2>/dev/null || echo overseas)

    echo "[git] 克隆 ${name} | 区域: ${region} | 目标: ${dest}" >&2

    if [ -n "${_XRK_GITHUB_PROXY_CACHED:-}" ]; then
        proxied="$(_xrk_proxied_url "$_XRK_GITHUB_PROXY_CACHED" "$direct")"
        _xrk_git_clone_add_attempt "$proxied" "缓存代理 ${_XRK_GITHUB_PROXY_CACHED#https://}" urls labels
    fi

    if _is_cn_region; then
        proxy="$(_xrk_pick_github_proxy)"
        [ -n "$proxy" ] && _xrk_git_clone_add_attempt "$(_xrk_proxied_url "$proxy" "$direct")" "探测代理 ${proxy#https://}" urls labels
    fi

    _xrk_git_clone_add_attempt "$direct" "直连 GitHub" urls labels

    for proxy in "${PROXIES[@]}"; do
        _xrk_git_clone_add_attempt "$(_xrk_proxied_url "$proxy" "$direct")" "代理 ${proxy#https://}" urls labels
    done

    for i in "${!urls[@]}"; do
        if _xrk_git_clone_once "${labels[$i]}" "${urls[$i]}" "$dest" "$depth"; then
            _xrk_cache_proxy_from_clone_url "${urls[$i]}" || true
            return 0
        fi
    done

    echo "[git] 克隆失败（已试 ${#urls[@]} 种方式）: $direct" >&2
    echo "[git] 提示: export XRK_REGION=cn 后重试，或检查防火墙/DNS" >&2
    return 1
}
