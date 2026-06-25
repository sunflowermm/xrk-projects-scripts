#!/bin/bash
# NapCat / OneBot / WebUI — nt、NapCat.sh 共用
# NapCat 反向 WS: Authorization: Bearer <token>, X-Self-ID, User-Agent: OneBot/11

NAPCAT_CONFIG_DIR="${NAPCAT_CONFIG_DIR:-/opt/QQ/resources/app/app_launcher/napcat/config}"
NAPCAT_LAST_ERR=""

napcat_prefs_path() {
    printf '%s' "${NAPCAT_PREFS_FILE:-${XRK_ROOT:-/xrk}/body/napcat_prefs.json}"
}

napcat_framework_candidates() {
    local candidates=(
        "${XRK_AGT_ROOT:-}" "${XRK_YUNZAI_ROOT:-}" "${XRK_FRAMEWORK_ROOT:-}"
        "$HOME/XRK-AGT" "$HOME/XRK-Yunzai" "$HOME/Yunzai"
        "/root/XRK-AGT" "/root/XRK-Yunzai" "/root/Yunzai"
    )
    local parent
    parent="$(cd "${XRK_ROOT:-/xrk}/.." 2>/dev/null && pwd || true)"
    [ -n "$parent" ] && candidates+=("$parent/XRK-AGT" "$parent/XRK-Yunzai")
    printf '%s\n' "${candidates[@]}"
}

# 根据目录名推断展示名与默认端口
napcat_framework_label() {
    local root="$1" base port
    base="$(basename "$root")"
    case "$base" in
        XRK-AGT|XRK_AGT) printf 'XRK-AGT' ;;
        XRK-Yunzai|XRK_Yunzai|Yunzai) printf 'XRK-Yunzai' ;;
        *) printf '%s' "$base" ;;
    esac
}

napcat_framework_id_from_root() {
    local root="$1"
    printf '%s' "$(basename "$root" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
}

napcat_guess_framework_port() {
    local root="$1" label port
    label="$(napcat_framework_label "$root")"
    case "$label" in
        XRK-AGT) port=8080 ;;
        XRK-Yunzai) port=2537 ;;
        *) port=2537 ;;
    esac
    if [ -d "${root}/data/server_bots" ]; then
        local first
        first="$(find "${root}/data/server_bots" -maxdepth 1 -mindepth 1 -type d 2>/dev/null \
            | sed 's#.*/##' | sort -n | head -n1)"
        [ -n "$first" ] && [[ "$first" =~ ^[0-9]+$ ]] && port="$first"
    fi
    printf '%s' "$port"
}

# 扫描磁盘上的框架，输出 JSON 数组（不写入文件）
napcat_scan_frameworks_json() {
    local seen="" root id label port frameworks='[]'
    for root in $(napcat_framework_candidates); do
        [ -z "$root" ] || [ ! -d "$root" ] && continue
        case " $seen " in *" $root "*) continue ;; esac
        seen="$seen $root"
        [ -f "${root}/package.json" ] || [ -f "${root}/src/bot.js" ] || [ -f "${root}/lib/bot.js" ] || continue
        id="$(napcat_framework_id_from_root "$root")"
        label="$(napcat_framework_label "$root")"
        port="$(napcat_guess_framework_port "$root")"
        frameworks="$(jq -n --argjson arr "$frameworks" \
            --arg id "$id" --arg label "$label" --arg root "$root" --argjson port "$port" \
            '$arr + [{id:$id,label:$label,root:$root,default_port:$port,
                      ws_host:"127.0.0.1",ws_path:"OneBotv11"}]')"
    done
    printf '%s' "$frameworks"
}

napcat_load_prefs() {
    local f defaults err
    f="$(napcat_prefs_path)"
    defaults="$(jq -n '{
        webui_host:"127.0.0.1",webui_port:6099,webui_token:"",
        login_rate:3,disable_pty:true,frameworks:[]
    }')"
    if [ -f "$f" ]; then
        if ! jq -e . "$f" >/dev/null 2>&1; then
            NAPCAT_LAST_ERR="napcat_prefs.json 损坏: $f"
            echo "$defaults" | jq --argjson fw "$(napcat_scan_frameworks_json)" '.frameworks = $fw'
            return 1
        fi
        err="$(jq -s '.[1] * .[0]' <(cat "$f") <(echo "$defaults") \
            | jq --argjson scanned "$(napcat_scan_frameworks_json)" \
                '.frameworks = (
                    (.frameworks // []) as $saved |
                    reduce $scanned[] as $item ($saved;
                        if any($saved[]; .root == $item.root) then . else . + [$item] end)
                )' 2>&1)" || {
            NAPCAT_LAST_ERR="读取 napcat_prefs 失败: ${err:-未知错误}"
            echo "$defaults" | jq --argjson fw "$(napcat_scan_frameworks_json)" '.frameworks = $fw'
            return 1
        }
        printf '%s' "$err"
        return 0
    fi
    echo "$defaults" | jq --argjson fw "$(napcat_scan_frameworks_json)" '.frameworks = $fw'
}

napcat_save_prefs() {
    local json="$1" f dir tmp err
    f="$(napcat_prefs_path)"
    dir="$(dirname "$f")"
    mkdir -p "$dir" 2>/dev/null || { NAPCAT_LAST_ERR="无法创建目录: $dir"; return 1; }
    err="$(echo "$json" | jq -e . 2>&1)" || {
        NAPCAT_LAST_ERR="prefs 不是合法 JSON: ${err:-$json}"
        return 1
    }
    tmp="$(mktemp "${dir}/.napcat_prefs.XXXXXX")"
    printf '%s\n' "$json" > "$tmp" 2>/dev/null || {
        NAPCAT_LAST_ERR="写入临时文件失败: $tmp"
        rm -f "$tmp"
        return 1
    }
    mv "$tmp" "$f" 2>/dev/null || {
        NAPCAT_LAST_ERR="写入失败: $f（检查权限）"
        rm -f "$tmp"
        return 1
    }
}

napcat_refresh_frameworks() {
    napcat_save_prefs "$(napcat_load_prefs)"
}

napcat_get_framework() {
    local id="$1" prefs
    prefs="$(napcat_load_prefs)"
    echo "$prefs" | jq -c --arg id "$id" '.frameworks[] | select(.id == $id)' | head -n1
}

napcat_read_api_key() {
    local root="${1:-}" f
    [ -n "$root" ] || return 1
    for f in "${root}/config/server_config/api_key.json" "${root}/data/server_config/api_key.json"; do
        [ -f "$f" ] || continue
        jq -r '.key // empty' "$f" 2>/dev/null | grep -q . && jq -r '.key' "$f" && return 0
    done
    return 1
}

napcat_harden_api_key() {
    local root="$1" label="${2:-}"
    [ -z "$label" ] && label="$(napcat_framework_label "$root")"
    local f mode
    for f in "${root}/config/server_config/api_key.json" "${root}/data/server_config/api_key.json"; do
        [ -f "$f" ] || continue
        mode=$(stat -c '%a' "$f" 2>/dev/null || stat -f '%OLp' "$f" 2>/dev/null)
        case "$mode" in 600|400) return 0 ;; *)
            chmod 600 "$f" 2>/dev/null && echo "[安全] $label api_key → 600" ;;
        esac
        return 0
    done
}

# 单条连接 token：连接.token > QQ.ob_token > 指定框架 api_key
napcat_resolve_link_token() {
    local link_json="$1" global_token="${2:-}"
    local link_token root id
    link_token="$(echo "$link_json" | jq -r '.token // ""' | tr -d '\r\n')"
    [ -n "$link_token" ] && { printf '%s' "$link_token"; return 0; }
    global_token="$(printf '%s' "$global_token" | tr -d '\r\n')"
    [ -n "$global_token" ] && { printf '%s' "$global_token"; return 0; }

    id="$(echo "$link_json" | jq -r '.framework_id // ""')"
    [ -n "$id" ] && root="$(napcat_get_framework "$id" | jq -r '.root // ""')"
    [ -n "$root" ] && napcat_read_api_key "$root" && return 0
    return 1
}

napcat_qq_links_summary() {
    local qq_file="$1" parts="" link id fw label port
    [ -f "$qq_file" ] || { printf '未绑定框架'; return; }
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        id="$(echo "$link" | jq -r '.framework_id')"
        fw="$(napcat_get_framework "$id")"
        [ -z "$fw" ] && continue
        label="$(echo "$fw" | jq -r '.label')"
        port="$(echo "$link" | jq -r '.port')"
        parts="${parts:+$parts, }${label}:${port}"
    done < <(jq -c '.links[]?|select(.enabled==true)' "$qq_file")
    [ -n "$parts" ] && printf '%s' "$parts" || printf '未绑定框架'
}

# WebUI 全局唯一：napcat/config/webui.json，所有 QQ 进程共用（非 per-qq）
napcat_webui_file() {
    printf '%s/webui.json' "$NAPCAT_CONFIG_DIR"
}

napcat_read_webui() {
    local wf; wf="$(napcat_webui_file)"
    [ -f "$wf" ] && jq -c . "$wf" 2>/dev/null || jq -n '{host:"127.0.0.1",port:6099,token:"",loginRate:3}'
}

# 表单/状态展示：以 webui.json 为准（NapCat 运行后会写回完整 schema）
napcat_webui_effective() {
    local w prefs
    w="$(napcat_read_webui)"
    prefs="$(napcat_load_prefs 2>/dev/null || true)"
    [ -z "$prefs" ] && prefs='{}'
    jq -n \
        --argjson w "$w" \
        --argjson p "$prefs" \
        '{
            host: ($w.host // $p.webui_host // "127.0.0.1"),
            port: ($w.port // $p.webui_port // 6099),
            token: ($w.token // $p.webui_token // ""),
            loginRate: ($w.loginRate // $p.login_rate // 3)
        }'
}

napcat_webui_url() {
    local w host port
    w="$(napcat_read_webui)"
    host="$(echo "$w" | jq -r '.host')"
    port="$(echo "$w" | jq -r '.port')"
    [ "$port" = "0" ] && return 1
    printf 'http://%s:%s/webui' "$host" "$port"
}

napcat_apply_webui() {
    local prefs host port rate token disable_pty wf tmp err base has_token
    prefs="$(napcat_load_prefs)" || true
    [ -z "$prefs" ] && { NAPCAT_LAST_ERR="无法加载 napcat_prefs"; return 1; }

    host="$(echo "$prefs" | jq -r '.webui_host // "127.0.0.1"')"
    port="$(echo "$prefs" | jq -r '.webui_port // 6099')"
    rate="$(echo "$prefs" | jq -r '.login_rate // 3')"
    disable_pty="$(echo "$prefs" | jq -r '.disable_pty // true')"
    token="$(echo "$prefs" | jq -r '.webui_token // ""' | tr -d '\r\n')"
    has_token=false
    [ -n "$token" ] && has_token=true
    [ "$has_token" = false ] && token="$(napcat_read_webui 2>/dev/null | jq -r '.token // ""' | tr -d '\r\n')"

    [[ "$port" =~ ^[0-9]+$ ]] || { NAPCAT_LAST_ERR="无效端口: $port"; return 1; }
    [[ "$rate" =~ ^[0-9]+$ ]] || { NAPCAT_LAST_ERR="无效限速: $rate"; return 1; }
    [ -n "$host" ] || { NAPCAT_LAST_ERR="监听地址不能为空"; return 1; }

    wf="$(napcat_webui_file)"
    mkdir -p "$NAPCAT_CONFIG_DIR" 2>/dev/null || {
        NAPCAT_LAST_ERR="无法创建目录: $NAPCAT_CONFIG_DIR"
        return 1
    }

    if [ -f "$wf" ] && jq -e . "$wf" >/dev/null 2>&1; then
        base="$(cat "$wf")"
    else
        base='{}'
    fi

    tmp="$(mktemp "${TMPDIR:-/tmp}/napcat_webui.XXXXXX")"
    if ! jq \
        --arg host "$host" \
        --argjson port "$port" \
        --arg token "$token" \
        --argjson rate "$rate" \
        --argjson set_token "$has_token" \
        '.host=$host
         | .port=$port
         | .loginRate=$rate
         | .disableWebUI=($port==0)
         | if $set_token then .token=$token else . end' \
        <<< "$base" > "$tmp" 2>"${tmp}.err"; then
        NAPCAT_LAST_ERR="合并 webui.json 失败: $(tr -d '\n' < "${tmp}.err" 2>/dev/null)"
        rm -f "$tmp" "${tmp}.err"
        return 1
    fi
    rm -f "${tmp}.err"

    if ! err="$(mv "$tmp" "$wf" 2>&1)"; then
        NAPCAT_LAST_ERR="写入 $wf 失败: ${err:-需要 root 权限}\n请用 root 运行 nt"
        rm -f "$tmp"
        return 1
    fi

    # 写后校验（防止 NapCat 进程或其它进程立刻改回）
    if ! jq -e --arg h "$host" --argjson p "$port" --argjson r "$rate" \
        '.host==$h and .port==$p and .loginRate==$r' "$wf" >/dev/null 2>&1; then
        NAPCAT_LAST_ERR="写入后校验失败（文件已被改写）\n请先停止 NapCat/QQ 再改 WebUI\n当前: $(jq -c '{host,port,loginRate,token}' "$wf" 2>/dev/null)"
        return 1
    fi

    [ "$disable_pty" = "true" ] && [ -d "${NAPCAT_CONFIG_DIR%/config}/pty" ] \
        && rm -rf "${NAPCAT_CONFIG_DIR%/config}/pty"
    return 0
}

# 由 links[] 生成 onebot11（支持多框架多连接）
napcat_write_onebot_config() {
    local qq_num="$1" links_json="$2" global_token="$3"
    local clients='[]' link token url name id fw ws_host port ws_path label
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        [ "$(echo "$link" | jq -r '.enabled')" != "true" ] && continue
        id="$(echo "$link" | jq -r '.framework_id')"
        fw="$(napcat_get_framework "$id")"
        [ -z "$fw" ] && continue
        label="$(echo "$fw" | jq -r '.label')"
        ws_host="$(echo "$link" | jq -r '.ws_host // empty')"
        [ -z "$ws_host" ] && ws_host="$(echo "$fw" | jq -r '.ws_host')"
        port="$(echo "$link" | jq -r '.port // empty')"
        [ -z "$port" ] && port="$(echo "$fw" | jq -r '.default_port')"
        ws_path="$(echo "$link" | jq -r '.ws_path // empty')"
        [ -z "$ws_path" ] && ws_path="$(echo "$fw" | jq -r '.ws_path')"
        root="$(echo "$fw" | jq -r '.root')"
        napcat_harden_api_key "$root" "$label" 2>/dev/null || true
        ws_path="${ws_path#/}"
        url="ws://${ws_host}:${port}/${ws_path}"
        token="$(napcat_resolve_link_token "$link" "$global_token" 2>/dev/null || true)"
        name="$(echo "$label" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
        clients="$(jq -n --argjson arr "$clients" --arg name "$name" --arg url "$url" --arg token "$token" \
            '$arr + [{
                name: ("ws-" + $name), enable: true, url: $url,
                messagePostFormat: "array", reportSelfMessage: false,
                reconnectInterval: 5000, token: $token, debug: false, heartInterval: 30000
            }]')"
    done < <(echo "$links_json" | jq -c '.[]')

    jq -n --argjson clients "$clients" \
        '{network:{httpServers:[],httpClients:[],websocketServers:[],websocketClients:$clients},
          musicSignUrl:"",enableLocalFile2Url:false}' \
        > "${NAPCAT_CONFIG_DIR}/onebot11_${qq_num}.json"
}

napcat_write_napcat_config() {
    local qq_num="$1" cfg="$2"
    jq -n \
        --argjson fl "$(echo "$cfg" | jq '.file_log // false')" \
        --argjson cl "$(echo "$cfg" | jq '.console_log // true')" \
        '{fileLog:$fl,consoleLog:$cl,fileLogLevel:"debug",consoleLogLevel:"info",
          packetBackend:"auto",packetServer:""}' \
        > "${NAPCAT_CONFIG_DIR}/napcat_${qq_num}.json"
}

napcat_prepare_runtime() {
    local qq_num="$1" qq_file="$2" cfg links global_token n host
    cfg="$(jq '. + {ob_token:(.ob_token//""),links:(.links//[])}' "$qq_file")"
    links="$(echo "$cfg" | jq -c '.links // []')"
    global_token="$(echo "$cfg" | jq -r '.ob_token // ""')"

    napcat_apply_webui
    napcat_write_onebot_config "$qq_num" "$links" "$global_token"
    napcat_write_napcat_config "$qq_num" "$cfg"

    n="$(echo "$links" | jq '[.[]|select(.enabled==true)]|length')"
    [ "$n" -eq 0 ] && echo "[nt] 未启用框架连接，请在 nt 中勾选框架"

    host="$(napcat_read_webui | jq -r '.host')"
    case "$host" in 0.0.0.0|::) echo "[nt] WebUI 公网监听，请设强 token 并限制防火墙" ;; esac
}

# 供 nt 状态页展示
napcat_status_text() {
    local qq_dir="${XRK_ROOT:-/xrk}/body" prefs text w qq qf
    prefs="$(napcat_load_prefs)"
    w="$(napcat_read_webui)"
    text="══ NapCat 状态 ═=\n\n[ WebUI · 全局共用 ]\n"
    text+="  $(echo "$w" | jq -r '.host'):$(echo "$w" | jq -r '.port')"
    text+="$(echo "$w" | jq -r 'if .token!="" then " token=已设" else " token=自动" end')\n"
    text+="  $(napcat_webui_file)\n"
    text+="\n[ 已注册框架 $(echo "$prefs" | jq '.frameworks|length') 个 ]\n"
    while IFS= read -r fw; do
        text+="  · $(echo "$fw" | jq -r '.label') :$(echo "$fw" | jq -r '.default_port')\n"
        text+="    $(echo "$fw" | jq -r '.root')\n"
    done < <(echo "$prefs" | jq -c '.frameworks[]?')
    text+="\n[ QQ 绑定 ]\n"
    shopt -s nullglob
    local found=0
    for qf in "${qq_dir}"/qq_*.json; do
        found=1
        qq="$(basename "$qf" | sed 's/^qq_//;s/.json$//')"
        text+="  $qq → $(napcat_qq_links_summary "$qf")\n"
    done
    shopt -u nullglob
    [ "$found" -eq 0 ] && text+="  （无）\n"
    printf '%b' "$text"
}
