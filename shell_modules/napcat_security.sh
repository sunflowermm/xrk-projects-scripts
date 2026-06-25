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
        webui_host:"0.0.0.0",webui_port:4071,webui_token:"",
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
                '(.frameworks // []) as $saved |
                 .frameworks = (
                   reduce $scanned[] as $item ($saved;
                     if any(.[]; .root == $item.root) then
                       map(if .root == $item.root then $item else . end)
                     else
                       . + [$item]
                     end)
                 ) | del(.warn_public_webui)' 2>&1)" || {
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
    local id="$1" prefs fw root derived
    prefs="$(napcat_load_prefs)"
    fw="$(echo "$prefs" | jq -c --arg id "$id" '.frameworks[]? | select(.id == $id)' | head -n1)"
    [ -n "$fw" ] || return 1
    root="$(echo "$fw" | jq -r '.root // ""')"
    derived="$(napcat_framework_id_from_root "$root")"
    [ "$derived" = "$id" ] || {
        NAPCAT_LAST_ERR="napcat_prefs 框架 id=${id} 与目录 ${root} 不一致（应为 ${derived}）\n请 nt → 框架管理 → 重新扫描，再修改 QQ 绑定"
        return 1
    }
    printf '%s' "$fw"
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

napcat_onebot_file() {
    printf '%s/onebot11_%s.json' "$NAPCAT_CONFIG_DIR" "$1"
}

napcat_link_enabled() {
    echo "$1" | jq -e '
        if .enabled == false or .enabled == "false" then false
        else true end
    ' >/dev/null 2>&1
}

napcat_count_enabled_links() {
    local links_json="$1" link n=0
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        napcat_link_enabled "$link" && n=$((n + 1))
    done < <(echo "$links_json" | jq -c '.[]?')
    printf '%s' "$n"
}

napcat_ws_client_display_name() {
    case "$1" in
        ws-xrk-agt|xrk-agt) printf 'XRK-AGT' ;;
        ws-xrk-yunzai|xrk-yunzai) printf 'XRK-Yunzai' ;;
        ws-*)
            local n="${1#ws-}"
            n="$(printf '%s' "$n" | sed 's/-/ /g')"
            printf '%s' "$n"
            ;;
        *) printf '%s' "$1" ;;
    esac
}

# 由 qq links[] 解析连接端点（与 write_onebot 同一套规则）
napcat_resolve_link_endpoint() {
    local link="$1" fw="${2:-}" id label ws_host port ws_path root
    id="$(echo "$link" | jq -r '.framework_id // ""')"
    [ -n "$id" ] || return 1
    [ -z "$fw" ] && fw="$(napcat_get_framework "$id")" || true
    [ -n "$fw" ] || return 1
    root="$(echo "$fw" | jq -r '.root // ""')"
    label="$(napcat_framework_label "$root")"
    ws_host="$(echo "$link" | jq -r '.ws_host // empty')"
    [ -z "$ws_host" ] && ws_host="$(echo "$fw" | jq -r '.ws_host // "127.0.0.1"')"
    port="$(echo "$link" | jq -r '.port // empty')"
    [ -z "$port" ] && port="$(echo "$fw" | jq -r '.default_port // empty')"
    [[ "$port" =~ ^[0-9]+$ ]] || port="$(napcat_guess_framework_port "$root")"
    ws_path="$(echo "$link" | jq -r '.ws_path // empty')"
    [ -z "$ws_path" ] && ws_path="$(echo "$fw" | jq -r '.ws_path // "OneBotv11"')"
    ws_path="${ws_path#/}"
    printf '%s\tws://%s:%s/%s\n' "$label" "$ws_host" "$port" "$ws_path"
}

napcat_links_expected_urls() {
    local links_json="$1" link urls='[]' row label url
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        napcat_link_enabled "$link" || continue
        row="$(napcat_resolve_link_endpoint "$link")" || continue
        url="${row#*$'\t'}"
        url="${url//$'\n'/}"
        urls="$(jq -n --argjson arr "$urls" --arg u "$url" '$arr + [$u]')"
    done < <(echo "$links_json" | jq -c '.[]')
    echo "$urls" | jq -c 'sort'
}

napcat_onebot_actual_urls() {
    local qq_num="$1" ob
    ob="$(napcat_onebot_file "$qq_num")"
    [ -f "$ob" ] || { echo '[]'; return 1; }
    jq -c '[.network.websocketClients[]?|select(.enable==true)|.url]|sort' "$ob" 2>/dev/null || echo '[]'
}

napcat_verify_onebot_config() {
    local qq_num="$1" links_json="$2" expected actual
    expected="$(napcat_links_expected_urls "$links_json")"
    actual="$(napcat_onebot_actual_urls "$qq_num")"
    [ "$actual" != "[]" ] || {
        NAPCAT_LAST_ERR="onebot 未生成或为空: $(napcat_onebot_file "$qq_num")"
        return 1
    }
    if [ "$expected" != "$actual" ]; then
        NAPCAT_LAST_ERR="onebot 与 QQ 绑定不一致\n期望: ${expected}\n实际: ${actual}\n文件: $(napcat_onebot_file "$qq_num")"
        return 1
    fi
    return 0
}

napcat_format_connection_lines() {
    local qq_file="$1" cfg links link row label url
    [ -f "$qq_file" ] || return 1
    cfg="$(jq '. + {links:(.links//[])}' "$qq_file")"
    links="$(echo "$cfg" | jq -c '.links // []')"
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        napcat_link_enabled "$link" || continue
        row="$(napcat_resolve_link_endpoint "$link")" || continue
        label="${row%%$'\t'*}"
        url="${row#*$'\t'}"
        url="${url//$'\n'/}"
        printf '%s  %s\n' "$label" "$url"
    done < <(echo "$links" | jq -c '.[]')
}

# 启动横幅：以已写入的 onebot11 为准（与 NapCat 实际加载一致）
napcat_onebot_banner_lines() {
    local qq_num="$1" f name url
    f="$(napcat_onebot_file "$qq_num")"
    [ -f "$f" ] || return 1
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        url="$(jq -r --arg n "$name" '.network.websocketClients[]?|select(.name==$n and .enable==true)|.url' "$f" 2>/dev/null)"
        [ -n "$url" ] && [ "$url" != "null" ] || continue
        printf '%s  %s\n' "$(napcat_ws_client_display_name "$name")" "$url"
    done < <(jq -r '.network.websocketClients[]?|select(.enable==true)|.name' "$f" 2>/dev/null)
}

napcat_onebot_effective_summary() {
    local qq_num="$1" ob parts="" url
    ob="$(napcat_onebot_file "$qq_num")"
    [ -f "$ob" ] || { printf '（未生成）'; return; }
    while IFS= read -r url; do
        [ -z "$url" ] && continue
        parts="${parts:+$parts, }${url#ws://}"
    done < <(jq -r '.network.websocketClients[]?|select(.enable==true)|.url' "$ob" 2>/dev/null)
    [ -n "$parts" ] && printf '%s' "$parts" || printf '（无连接）'
}

napcat_qq_onebot_mismatch() {
    local qq_file="$1" qq links expected actual
    [ -f "$qq_file" ] || return 1
    qq="$(basename "$qq_file" | sed 's/^qq_//;s/.json$//')"
    links="$(jq -c '.links // []' "$qq_file")"
    expected="$(napcat_links_expected_urls "$links")"
    actual="$(napcat_onebot_actual_urls "$qq")"
    [ "$expected" = "$actual" ] && return 1
    return 0
}

napcat_sync_qq_link_ports() {
    local fw_id="$1" new_port="$2" qq_dir="${XRK_ROOT:-/xrk}/body" qf tmp
    [[ "$new_port" =~ ^[0-9]+$ ]] || return 1
    for qf in "${qq_dir}"/qq_*.json; do
        [ -f "$qf" ] || continue
        jq -e --arg id "$fw_id" 'any(.links[]?; .framework_id==$id and ((.enabled==true) or (.enabled=="true") or (.enabled==null)))' "$qf" >/dev/null 2>&1 || continue
        tmp="$(mktemp "${qq_dir}/.qq_sync.XXXXXX")"
        jq --arg id "$fw_id" --argjson port "$new_port" \
            '.links = [.links[]|if .framework_id==$id then .port=$port else . end]' "$qf" > "$tmp" \
            && mv "$tmp" "$qf"
    done
}

napcat_qq_links_summary() {
    local qq_file="$1" parts="" link id fw label port
    [ -f "$qq_file" ] || { printf '未绑定框架'; return; }
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        napcat_link_enabled "$link" || continue
        id="$(echo "$link" | jq -r '.framework_id')"
        fw="$(napcat_get_framework "$id")"
        [ -z "$fw" ] && continue
        label="$(echo "$fw" | jq -r '.label')"
        port="$(echo "$link" | jq -r '.port')"
        parts="${parts:+$parts, }${label}:${port}"
    done < <(jq -c '.links[]?' "$qq_file")
    [ -n "$parts" ] && printf '%s' "$parts" || printf '未绑定框架'
}

# WebUI 全局唯一：napcat/config/webui.json，所有 QQ 进程共用（非 per-qq）
napcat_webui_file() {
    printf '%s/webui.json' "$NAPCAT_CONFIG_DIR"
}

napcat_read_webui() {
    local wf; wf="$(napcat_webui_file)"
    [ -f "$wf" ] && jq -c . "$wf" 2>/dev/null || jq -n '{host:"0.0.0.0",port:4071,token:"",loginRate:3}'
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
            host: ($w.host // $p.webui_host // "0.0.0.0"),
            port: ($w.port // $p.webui_port // 4071),
            token: ($w.token // $p.webui_token // ""),
            loginRate: ($w.loginRate // $p.login_rate // 3)
        }'
}

napcat_webui_url() {
    local eff host port
    eff="$(napcat_webui_effective)"
    host="$(echo "$eff" | jq -r '.host')"
    port="$(echo "$eff" | jq -r '.port')"
    [ "$port" = "0" ] && return 1
    printf 'http://%s:%s/webui' "$host" "$port"
}

napcat_apply_webui() {
    local prefs host port rate token disable_pty wf tmp err base has_token
    prefs="$(napcat_load_prefs)" || true
    [ -z "$prefs" ] && { NAPCAT_LAST_ERR="无法加载 napcat_prefs"; return 1; }

    host="$(echo "$prefs" | jq -r '.webui_host // "0.0.0.0"')"
    port="$(echo "$prefs" | jq -r '.webui_port // 4071')"
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
    local clients='[]' link token url name id fw label root row ob tmp err n=0
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        napcat_link_enabled "$link" || continue
        id="$(echo "$link" | jq -r '.framework_id // ""')"
        [ -n "$id" ] || {
            NAPCAT_LAST_ERR="QQ 绑定缺少 framework_id"
            return 1
        }
        fw="$(napcat_get_framework "$id")" || {
            [ -n "${NAPCAT_LAST_ERR:-}" ] || NAPCAT_LAST_ERR="未注册框架: ${id}（nt → 框架管理 → 扫描）"
            return 1
        }
        label="$(echo "$fw" | jq -r '.label')"
        root="$(echo "$fw" | jq -r '.root')"
        row="$(napcat_resolve_link_endpoint "$link" "$fw")" || {
            NAPCAT_LAST_ERR="无法解析框架 ${id} 的连接"
            return 1
        }
        url="${row#*$'\t'}"
        url="${url//$'\n'/}"
        napcat_harden_api_key "$root" "$label" 2>/dev/null || true
        token="$(napcat_resolve_link_token "$link" "$global_token" 2>/dev/null || true)"
        name="$(echo "$label" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
        clients="$(jq -n --argjson arr "$clients" --arg name "$name" --arg url "$url" --arg token "$token" \
            '$arr + [{
                name: ("ws-" + $name), enable: true, url: $url,
                messagePostFormat: "array", reportSelfMessage: false,
                reconnectInterval: 5000, token: $token, debug: false, heartInterval: 30000
            }]')"
        n=$((n + 1))
    done < <(echo "$links_json" | jq -c '.[]')

    [ "$n" -gt 0 ] || {
        NAPCAT_LAST_ERR="无有效 QQ 框架绑定（检查 framework_id / enabled）"
        return 1
    }

    ob="$(napcat_onebot_file "$qq_num")"
    mkdir -p "$NAPCAT_CONFIG_DIR" 2>/dev/null || {
        NAPCAT_LAST_ERR="无法创建目录: $NAPCAT_CONFIG_DIR"
        return 1
    }
    tmp="$(mktemp "${TMPDIR:-/tmp}/onebot11.XXXXXX")"
    if ! jq -n --argjson clients "$clients" \
        '{network:{httpServers:[],httpClients:[],websocketServers:[],websocketClients:$clients},
          musicSignUrl:"",enableLocalFile2Url:false}' > "$tmp" 2>"${tmp}.err"; then
        NAPCAT_LAST_ERR="生成 onebot 配置失败: $(tr -d '\n' < "${tmp}.err" 2>/dev/null)"
        rm -f "$tmp" "${tmp}.err"
        return 1
    fi
    rm -f "${tmp}.err"
    if ! err="$(mv "$tmp" "$ob" 2>&1)"; then
        NAPCAT_LAST_ERR="写入 $ob 失败: ${err:-权限不足}"
        rm -f "$tmp"
        return 1
    fi
    return 0
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
    local qq_num="$1" qq_file="$2" cfg links global_token n webui_warn=0
    napcat_refresh_frameworks >/dev/null
    cfg="$(jq '. + {ob_token:(.ob_token//""),links:(.links//[])}' "$qq_file")"
    links="$(echo "$cfg" | jq -c '.links // []')"
    global_token="$(echo "$cfg" | jq -r '.ob_token // ""')"

    n="$(napcat_count_enabled_links "$links")"
    [ "$n" -eq 0 ] && {
        NAPCAT_LAST_ERR="未启用框架连接，请在 nt 中勾选框架"
        return 1
    }

    napcat_apply_webui || webui_warn=1

    napcat_write_onebot_config "$qq_num" "$links" "$global_token" || return 1
    napcat_write_napcat_config "$qq_num" "$cfg" || {
        NAPCAT_LAST_ERR="写入 napcat_${qq_num}.json 失败"
        return 1
    }
    napcat_verify_onebot_config "$qq_num" "$links" "$global_token" || return 1

    [ "$webui_warn" -eq 1 ] && echo "[nt] WebUI 未写入（OneBot 已按 QQ 绑定同步）"
    return 0
}

# 供 nt 状态页展示
napcat_status_text() {
    local qq_dir="${XRK_ROOT:-/xrk}/body" prefs text eff qq qf
    prefs="$(napcat_load_prefs)"
    eff="$(napcat_webui_effective)"
    text="══ NapCat 状态 ═=\n\n[ WebUI · 全局共用 ]\n"
    text+="  $(echo "$eff" | jq -r '.host'):$(echo "$eff" | jq -r '.port')"
    text+="$(echo "$eff" | jq -r 'if .token!="" then " token=已设" else " token=自动" end')\n"
    text+="  loginRate=$(echo "$eff" | jq -r '.loginRate')\n"
    text+="  $(napcat_webui_file)\n"
    text+="\n[ 已注册框架 $(echo "$prefs" | jq '.frameworks|length') 个 ]\n"
    while IFS= read -r fw; do
        text+="  · $(echo "$fw" | jq -r '.label') :$(echo "$fw" | jq -r '.default_port')\n"
        text+="    $(echo "$fw" | jq -r '.root')\n"
    done < <(echo "$prefs" | jq -c '.frameworks[]?')
    text+="\n[ QQ 绑定 · nt 配置 ]\n"
    shopt -s nullglob
    local found=0
    for qf in "${qq_dir}"/qq_*.json; do
        found=1
        qq="$(basename "$qf" | sed 's/^qq_//;s/.json$//')"
        text+="  $qq → $(napcat_qq_links_summary "$qf")\n"
    done
    shopt -u nullglob
    [ "$found" -eq 0 ] && text+="  （无）\n"
    text+="\n[ QQ 实际连接 · onebot11 ]\n"
    found=0
    shopt -s nullglob
    for qf in "${qq_dir}"/qq_*.json; do
        found=1
        qq="$(basename "$qf" | sed 's/^qq_//;s/.json$//')"
        text+="  $qq → $(napcat_onebot_effective_summary "$qq")\n"
        if napcat_qq_onebot_mismatch "$qf"; then
            text+="    ⚠ 与绑定不一致，请重新启动该 QQ\n"
        fi
    done
    shopt -u nullglob
    [ "$found" -eq 0 ] && text+="  （无）\n"
    text+="\n  框架 default_port 仅作默认值；生效以 QQ 绑定 + onebot11 为准\n"
    printf '%b' "$text"
}
