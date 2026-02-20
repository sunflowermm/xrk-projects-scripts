#!/bin/bash
# GitHub 访问优化：
# - 中国大陆（detect_region=cn）：随机测试代理，命中一个可用就用（proxy/原URL）
# - 海外（detect_region=overseas）：默认保持原样（如需强制可手动 proxy_num）

# 检测区域（复用 bootstrap 的 detect_region；唯一依据 countryCode==CN）
_is_cn_region() {
    local region
    type detect_region &>/dev/null && region=$(detect_region 2>/dev/null) || region="overseas"
    [ "$region" = "cn" ]
}

# 代理列表：建议保留多条以便失效自动切换（此列表来自一次环境内可用性测试）
PROXIES=(
    "https://gh-proxy.com"
    "https://cf2.algin.cn"
    "https://dl.nzjk.cf"
    "https://fastgh.lainbo.com"
    "https://file.sweatent.top"
    "https://g.blfrp.cn"
    "https://g.in0.re"
    "https://gh.b52m.cn"
    "https://gh.chjina.com"
    "https://gh.idayer.com"
    "https://gh.llkk.cc"
    "https://gh.whjpd.top/gh"
    "https://ghproxy.imciel.com"
    "https://ghproxy.kokomi0728.eu.org"
    "https://git.669966.xyz"
    "https://git.linrol.cn"
    "https://git.smartapi.com.cn"
    "https://git.xkii.cc"
    "https://git.z23.cc"
    "https://gitcdn.uiisc.org"
    "https://github.aci1.com"
    "https://github.bef841ca.cn"
    "https://github.blogonly.cn"
    "https://github.codecho.cc"
    "https://github.jianrry.plus"
    "https://github.wper.club"
    "https://github.xiaoning223.top"
    "https://github.xxlab.tech"
    "https://githubacc.caiaiwan.com"
    "https://ken.canaan.io"
    "https://static.yiwangmeng.com"
)

# 轻量可用性探测：HTTP 200 才算成功
_xrk_http_ok() {
    curl -s --fail --connect-timeout 2 --max-time 4 -o /dev/null "$1" 2>/dev/null
}

# 随机挑选可用代理（不缓存）
_xrk_pick_github_proxy() {
    local test_url="https://raw.githubusercontent.com/NapNeko/NapCatQQ/main/package.json" proxy
    # 尽量随机：有 shuf 用 shuf，否则保持原顺序
    if command -v shuf &>/dev/null; then
        while IFS= read -r proxy; do
            _xrk_http_ok "${proxy}/${test_url}" && { echo "$proxy"; return 0; }
        done < <(printf "%s\n" "${PROXIES[@]}" | shuf)
    else
        for proxy in "${PROXIES[@]}"; do
            _xrk_http_ok "${proxy}/${test_url}" && { echo "$proxy"; return 0; }
        done
    fi
    echo ""
}

# GitHub URL 处理：cn 自动加速（proxy/原URL），overseas 保持原样
# 用法：
#   getgh url_var     # 变量名，函数内部原地修改（老用法，向下兼容）
#   getgh "https://github.com/..."  # 直接传 URL，stdout 返回处理后的 URL（供 git() 等使用）
getgh() {
    local arg="$1" var_name="" original_url proxy="" new_url

    # 1) 直接传入 URL：用于数组元素等场景（避免 `${!var_name}` 非法间接展开）
    case "$arg" in
        https://github.com/*|https://raw.githubusercontent.com/*)
            original_url="$arg"
            ;;
        *)
            # 2) 传入变量名：保持兼容旧接口
            var_name="$arg"
            # 非法变量名（比如 "args[$i]"）直接返回，避免 invalid indirect expansion
            case "$var_name" in
                ''|*'['*|*']'*|*' '*|*'$'*|*'*'*|*'?'*|*'!'*)
                    return 0
                    ;;
            esac
            # 间接展开获取变量值
            original_url="${!var_name}"
            case "$original_url" in
                https://github.com/*|https://raw.githubusercontent.com/*) ;;
                *) return 0 ;;
            esac
            ;;
    esac

    new_url="$original_url"

    if _is_cn_region; then
        # 手动指定 proxy_num 优先；否则随机挑一个可用的
        if [ -n "${proxy_num:-}" ] && [ "${proxy_num}" != "0" ]; then
            proxy="${PROXIES[$((proxy_num-1))]:-}"
        else
            proxy="$(_xrk_pick_github_proxy)"
        fi
        [ -n "$proxy" ] && new_url="${proxy}/${original_url}"
    else
        # overseas：不加代理；如果用户强制 proxy_num（非0），也按其指定加代理
        if [ -n "${proxy_num:-}" ] && [ "${proxy_num}" != "0" ]; then
            proxy="${PROXIES[$((proxy_num-1))]:-}"
            [ -n "$proxy" ] && new_url="${proxy}/${original_url}"
        fi
    fi

    # 按调用方式返回结果：有变量名则原地修改，否则 echo
    if [ -n "$var_name" ]; then
        printf -v "$var_name" '%s' "$new_url"
    else
        printf '%s\n' "$new_url"
    fi
}

# git 命令包装：国内时区自动换源，国外保持原样
git() {
    local args=("$@") i
    # 国内时区：自动将 GitHub URL 换为镜像
    # 国外时区：保持原样，仅在手动指定 proxy_num 时加代理
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[i]}" == https://github.com/* || "${args[i]}" == https://raw.githubusercontent.com/* ]]; then
            # 通过 URL 形式调用 getgh，避免数组元素的非法间接展开
            local __new
            __new=$(getgh "${args[i]}") || __new="${args[i]}"
            args[i]="$__new"
        fi
    done
    command git "${args[@]}"
}
