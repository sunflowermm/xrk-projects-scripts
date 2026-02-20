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

getgh() {
    local var_name="$1"
    local original_url="${!var_name}"
    local check_path="NapNeko/NapCatQQ/main/package.json"
    local speed_threshold=2
    local curl_timeout=3

    # 手动代理选择：proxy_num 全局变量
    # 0 = 不使用代理；1-N = 使用对应序号的内置代理
    if [ -n "${proxy_num}" ]; then
        if [ "${proxy_num}" = "0" ]; then
            # 强制直连
            echo -e "${YELLOW}已关闭代理，直接使用原始地址: ${original_url}${NC}"
            return 0
        fi
        if [[ "${proxy_num}" =~ ^[0-9]+$ ]] && [ "${proxy_num}" -ge 1 ] && [ "${proxy_num}" -le ${#PROXIES[@]} ]; then
            local manual_proxy="${PROXIES[$((proxy_num-1))]}"
            if [ -n "${manual_proxy}" ]; then
                local proxied_url="${manual_proxy}/${original_url}"
                eval "$var_name=\"$proxied_url\""
                echo -e "${GREEN}使用手动指定的代理: ${manual_proxy}${NC}"
                return 0
            fi
        fi
    fi

    # 打乱代理列表（每次调用时随机顺序）
    local shuffled_proxies=($(printf "%s\n" "${PROXIES[@]}" | shuf))
    local temp_file
    temp_file=$(mktemp)

    # 并行测试代理
    for proxy in "${shuffled_proxies[@]}"; do
        if [ -z "$proxy" ]; then
            continue
        fi
        local proxied_check_url="${proxy}/https://raw.githubusercontent.com/${check_path}"
        (curl --silent --fail --max-time $curl_timeout -w "%{http_code} %{time_total} ${proxy}\n" -o /dev/null "$proxied_check_url" >> "$temp_file") &
    done
    wait

    # 读取测试结果并选择最优代理
    local best_proxy=""
    local best_time=""

    while read -r line; do
        local http_code=$(echo "$line" | awk '{print $1}')
        local time_total=$(echo "$line" | awk '{print $2}')
        local proxy=$(echo "$line" | awk '{print $3}')
        if [ "$http_code" = "200" ]; then
            # 只接受在阈值内的结果
            if awk "BEGIN{exit($time_total<$speed_threshold?0:1)}"; then
                if [ -z "$best_time" ] || awk "BEGIN{exit($time_total<$best_time?0:1)}"; then
                    best_time="$time_total"
                    best_proxy="$proxy"
                fi
            fi
        fi
    done < "$temp_file"

    rm "$temp_file"

    if [ -n "$best_proxy" ]; then
        local proxied_url="${best_proxy}/${original_url}"
        eval "$var_name=\"$proxied_url\""
        echo -e "${GREEN}已选择代理: ${best_proxy}，响应时间约 ${best_time}s${NC}"
        return 0
    fi

    echo -e "${YELLOW}未找到合适的代理，继续使用原始地址: ${original_url}${NC}"
}

git() {
    local args=("$@") proxied=false i
    for ((i=0; i<${#args[@]}; i++)); do
        if [[ "${args[i]}" == https://github.com/* || "${args[i]}" == https://raw.githubusercontent.com/* ]]; then
            getgh "args[$i]"
            proxied=true
        fi
    done
    command git "${args[@]}"
}
