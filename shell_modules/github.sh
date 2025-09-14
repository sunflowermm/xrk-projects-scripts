#!/bin/bash

RED='\033[0;1;31;91m'
GREEN='\033[0;1;32;92m'
YELLOW='\033[0;1;33;93m'
NC='\033[0m'

PROXIES=(
    "http://124.156.150.245:10086"
    "http://140.83.60.48:8081"
    "https://gh-proxy.com"
    "http://43.154.105.8:8888"
    "http://8.210.153.246:9000"
    "http://gh.smiek.top:8080"
    "https://cf2.algin.cn"
    "https://dl.fastconnect.cc"
    "https://dl.nzjk.cf"
    "https://fast.zhaishis.cn"
    "https://fastgh.lainbo.com"
    "https://file.sweatent.top"
    "https://firewall.lxstd.org"
    "https://g.blfrp.cn"
    "https://g.in0.re"
    "https://get.2sb.org"
    "https://gh-proxy.llyke.com"
    "https://gh.222322.xyz"
    "https://gh.b52m.cn"
    "https://gh.chjina.com"
    "https://gh.gpuminer.org"
    "https://gh.hoa.moe"
    "https://gh.idayer.com"
    "https://gh.llkk.cc"
    "https://gh.meiqiu.net.cn"
    "https://gh.pylogmon.com"
    "https://gh.tangyuewei.com"
    "https://gh.tlhub.cn"
    "https://gh.tryxd.cn"
    "https://gh.whjpd.top/gh"
    "https://ghjs.us.kg"
    "https://ghp.aaaaaaaaaaaaaa.top"
    "https://ghp.ci"
    "https://ghp.miaostay.com"
    "https://ghpr.cc"
    "https://ghproxy.homeboyc.cn"
    "https://ghproxy.imciel.com"
    "https://ghproxy.kokomi0728.eu.org"
    "https://ghproxy.lyln.us.kg"
    "https://git.669966.xyz"
    "https://git.886.be"
    "https://git.ikxiuxin.com"
    "https://git.linrol.cn"
    "https://git.smartapi.com.cn"
    "https://git.snoweven.com"
    "https://git.speed-ssr.tech"
    "https://git.xiandan.uk"
    "https://git.xkii.cc"
    "https://git.z23.cc"
    "https://gitcdn.uiisc.org"
    "https://github.aci1.com"
    "https://github.bachang.org"
    "https://github.bef841ca.cn"
    "https://github.blogonly.cn"
    "https://github.codecho.cc"
    "https://github.cutemic.cn"
    "https://github.ffffffff0x.com"
    "https://github.jianrry.plus"
    "https://github.moeyy.xyz"
    "https://github.ur1.fun"
    "https://github.wper.club"
    "https://github.wuzhij.com"
    "https://github.xiaoning223.top"
    "https://github.xxlab.tech"
    "https://githubacc.caiaiwan.com"
    "https://githubapi.jjchizha.com"
    "https://jisuan.xyz"
    "https://ken.canaan.io"
    "https://mirror.ghproxy.com"
    "https://moeyy.cn/gh-proxy"
    "https://static.yiwangmeng.com"
    "https://www.ghproxy.cn"
    ""
)

# 打乱代理列表（仅在脚本初始化时执行一次）
shuffled_proxies=($(printf "%s\n" "${PROXIES[@]}" | shuf))

# 缓存快速代理
fast_proxy=""

function getgh() {
    local var_name="$1"
    local original_url="${!var_name}"
    local check_path="NapNeko/NapCatQQ/main/package.json"
    local speed_threshold=2
    local curl_timeout=3

    # 如果已经有快速代理，直接使用缓存
    if [ -n "$fast_proxy" ]; then
        local proxied_url="${fast_proxy}/${original_url}"
        eval "$var_name=\"$proxied_url\""
        echo -e "${GREEN}✅ 使用缓存的快速代理: ${proxied_url}${NC}"
        return 0
    fi

    # 并行测试代理
    local temp_file=$(mktemp)
    for proxy in "${shuffled_proxies[@]}"; do
        if [ -z "$proxy" ]; then
            continue
        fi
        local proxied_check_url="${proxy}/https://raw.githubusercontent.com/${check_path}"
        (curl --silent --fail --max-time $curl_timeout -w "%{http_code} %{time_total} ${proxy}\n" -o /dev/null "$proxied_check_url" >> "$temp_file") &
    done
    wait

    # 读取测试结果并选择最优代理
    while read -r line; do
        local http_code=$(echo "$line" | awk '{print $1}')
        local time_total=$(echo "$line" | awk '{print $2}')
        local proxy=$(echo "$line" | awk '{print $3}')
        if [ "$http_code" = "200" ] && awk "BEGIN{exit($time_total<$speed_threshold?0:1)}"; then
            fast_proxy="$proxy"
            local proxied_url="${fast_proxy}/${original_url}"
            eval "$var_name=\"$proxied_url\""
            echo -e "${GREEN}✅ 使用代理: ${proxied_url}, 响应时间: ${time_total}s${NC}"
            rm "$temp_file"
            return 0
        fi
    done < "$temp_file"

    rm "$temp_file"
    echo -e "${RED}❌ 没有找到满意的代理，使用原始 URL: ${original_url}${NC}"
}

function git() {
    local args=("$@")
    local proxied=false
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[i]}" == https://github.com/* || "${args[i]}" == https://raw.githubusercontent.com/* ]]; then
            getgh "args[$i]"
            proxied=true
        fi
    done
    if [ "$proxied" = true ]; then
        command git "${args[@]}"
    else
        command git "$@"
    fi
}
