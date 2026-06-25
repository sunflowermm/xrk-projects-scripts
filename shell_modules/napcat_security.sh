#!/bin/bash
# NapCat / OneBot / WebUI — nt、NapCat.sh 共用
# NapCat 反向 WS: Authorization: Bearer <token>, X-Self-ID, User-Agent: OneBot/11

NAPCAT_CONFIG_DIR="${NAPCAT_CONFIG_DIR:-/opt/QQ/resources/app/app_launcher/napcat/config}"

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
    local f defaults
    f="$(napcat_prefs_path)"
    defaults="$(jq -n '{
        webui_host:"127.0.0.1",webui_port:6099,webui_token:"",
        login_rate:3,disable_pty:true,warn_public_webui:true,frameworks:[]
    }')"
    if [ -f "$f" ]; then
        jq -s '.[0] * .[1]' <(cat "$f") <(echo "$defaults") \
            | jq --argjson scanned "$(napcat_scan_frameworks_json)" \
                '.frameworks = (
                    (.frameworks // []) as $saved |
                    reduce $scanned[] as $item ($saved;
                        if any($saved[]; .root == $item.root) then . else . + [$item] end)
                )'
    else
        echo "$defaults" | jq --argjson fw "$(napcat_scan_frameworks_json)" '.frameworks = $fw'
    fi
}

napcat_save_prefs() {
    printf '%s\n' "$1" > "$(napcat_prefs_path)"
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
    local link_token root legacy_root
    link_token="$(echo "$link_json" | jq -r '.token // ""' | tr -d '\r\n')"
    [ -n "$link_token" ] && { printf '%s' "$link_token"; return 0; }
    global_token="$(printf '%s' "$global_token" | tr -d '\r\n')"
    [ -n "$global_token" ] && { printf '%s' "$global_token"; return 0; }

    root="$(echo "$link_json" | jq -r '.framework_root // ""')"
    [ -z "$root" ] && id="$(echo "$link_json" | jq -r '.framework_id // ""')" \
        && [ -n "$id" ] && root="$(napcat_get_framework "$id" | jq -r '.root // ""')"
    [ -n "$root" ] && napcat_read_api_key "$root" && return 0
    return 1
}

# 加载 QQ 配置并迁移旧版单框架字段
napcat_load_qq_config() {
    local qq_file="$1" raw
    if [ ! -f "$qq_file" ]; then
        jq -n '{qq:"",ob_token:"",console_log:true,file_log:false,links:[]}'
        return
    fi
    raw="$(cat "$qq_file")"
    if echo "$raw" | jq -e '.links | type == "array"' >/dev/null 2>&1; then
        echo "$raw" | jq '. + {
            ob_token:(.ob_token//""),console_log:(.console_log//true),file_log:(.file_log//false)
        }'
        return
    fi
    # 旧版 port / framework_root → 单条 link
    echo "$raw" | jq '{
        qq:(.qq//""),
        ob_token:(.ob_token//""),
        console_log:(.console_log//true),
        file_log:(.file_log//false),
        links:[{
            framework_id:"legacy",
            enabled:true,
            port:(.port//2537),
            ws_host:(.ws_host//"127.0.0.1"),
            ws_path:(.ws_path//"OneBotv11"),
            token:(.ob_token//""),
            framework_root:(.framework_root//"")
        }]
    }'
}

napcat_read_webui_file() {
    local wf="${NAPCAT_CONFIG_DIR}/webui.json"
    [ -f "$wf" ] && cat "$wf" || jq -n '{host:"127.0.0.1",port:6099,token:"",loginRate:3}'
}

napcat_apply_webui() {
    local prefs host port rate token disable_pty webui_file existing
    prefs="$(napcat_load_prefs)"
    existing="$(napcat_read_webui_file)"
    host=$(echo "$prefs" | jq -r '.webui_host')
    port=$(echo "$prefs" | jq -r '.webui_port')
    rate=$(echo "$prefs" | jq -r '.login_rate')
    disable_pty=$(echo "$prefs" | jq -r '.disable_pty')
    token=$(echo "$prefs" | jq -r '.webui_token // ""')
    [ -z "$token" ] && token="$(echo "$existing" | jq -r '.token // ""')"

    webui_file="${NAPCAT_CONFIG_DIR}/webui.json"
    mkdir -p "$NAPCAT_CONFIG_DIR"
    jq -n --arg host "$host" --argjson port "$port" --arg token "$token" --argjson rate "$rate" \
        '{host:$host,port:$port,token:$token,loginRate:$rate}' > "$webui_file"

    [ "$disable_pty" = "true" ] && [ -d "${NAPCAT_CONFIG_DIR%/config}/pty" ] \
        && rm -rf "${NAPCAT_CONFIG_DIR%/config}/pty"
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
        if [ -n "$fw" ]; then
            label="$(echo "$fw" | jq -r '.label')"
            ws_host="$(echo "$link" | jq -r '.ws_host // empty')"
            [ -z "$ws_host" ] && ws_host="$(echo "$fw" | jq -r '.ws_host')"
            port="$(echo "$link" | jq -r '.port // empty')"
            [ -z "$port" ] && port="$(echo "$fw" | jq -r '.default_port')"
            ws_path="$(echo "$link" | jq -r '.ws_path // empty')"
            [ -z "$ws_path" ] && ws_path="$(echo "$fw" | jq -r '.ws_path')"
            root="$(echo "$fw" | jq -r '.root')"
            napcat_harden_api_key "$root" "$label" 2>/dev/null || true
        else
            label="$id"
            ws_host="$(echo "$link" | jq -r '.ws_host // "127.0.0.1"')"
            port="$(echo "$link" | jq -r '.port // 2537')"
            ws_path="$(echo "$link" | jq -r '.ws_path // "OneBotv11"')"
            root="$(echo "$link" | jq -r '.framework_root // ""')"
            [ -n "$root" ] && napcat_harden_api_key "$root" "$label" 2>/dev/null || true
        fi
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
    local qq_num="$1" qq_file="$2" cfg prefs links global_token n=0
    cfg="$(napcat_load_qq_config "$qq_file")"
    prefs="$(napcat_load_prefs)"
    links="$(echo "$cfg" | jq -c '.links // []')"
    global_token="$(echo "$cfg" | jq -r '.ob_token // ""')"

    napcat_apply_webui
    napcat_write_onebot_config "$qq_num" "$links" "$global_token"
    napcat_write_napcat_config "$qq_num" "$cfg"

    n="$(echo "$links" | jq '[.[]|select(.enabled==true)]|length')"
    if [ "$n" -eq 0 ]; then
        echo "[安全] 未启用任何框架连接，请在 nt 中为该 QQ 勾选框架"
    fi

    while IFS= read -r link; do
        [ -z "$link" ] && continue
        [ "$(echo "$link" | jq -r '.enabled')" != "true" ] && continue
        local id label token fw
        id="$(echo "$link" | jq -r '.framework_id')"
        fw="$(napcat_get_framework "$id")"
        label="$( [ -n "$fw" ] && echo "$fw" | jq -r '.label' || echo "$id")"
        token="$(napcat_resolve_link_token "$link" "$global_token" 2>/dev/null || true)"
        if [ -z "$token" ]; then
            echo "[安全] $label: token 空（先启动该框架或填写 token）"
        else
            echo "[安全] $label: 已用 api_key / 手动 token"
        fi
    done < <(echo "$links" | jq -c '.[]')

    if [ "$(echo "$prefs" | jq -r '.warn_public_webui')" = "true" ] \
        && [ "$(echo "$prefs" | jq -r '.webui_host')" = "0.0.0.0" ]; then
        echo "[安全] WebUI 监听 0.0.0.0，请确保强 token + 防火墙"
    fi
}

napcat_security_audit() {
    local issues=0 warns=0 ok=0 prefs
    _f() { echo "  [FAIL] $*"; issues=$((issues+1)); }
    _w() { echo "  [WARN] $*"; warns=$((issues+1)); }
    _o() { echo "  [ OK ] $*"; ok=$((ok+1)); }

    napcat_refresh_frameworks >/dev/null
    prefs="$(napcat_load_prefs)"
    echo "========== NapCat 安全审计 =========="
    echo ""

    echo "[ 已注册框架 ]"
    local fw_count
    fw_count="$(echo "$prefs" | jq '.frameworks|length')"
    [ "$fw_count" -eq 0 ] && _w "无框架，请 nt → 框架管理 → 扫描"
    while IFS= read -r fw; do
        local label root mode key_file
        label="$(echo "$fw" | jq -r '.label')"
        root="$(echo "$fw" | jq -r '.root')"
        echo "  · $label ($root) 默认端口 $(echo "$fw" | jq -r '.default_port')"
        key_file="${root}/config/server_config/api_key.json"
        [ ! -f "$key_file" ] && key_file="${root}/data/server_config/api_key.json"
        if [ ! -f "$key_file" ]; then _w "$label 无 api_key.json"; else
            mode=$(stat -c '%a' "$key_file" 2>/dev/null || stat -f '%OLp' "$key_file" 2>/dev/null)
            case "$mode" in 600|400) _o "$label api_key 权限 $mode" ;; *) _w "$label api_key 权限 $mode" ;; esac
        fi
    done < <(echo "$prefs" | jq -c '.frameworks[]?')
    echo ""

    echo "[ QQ 连接 ]"
    local qq_dir="${XRK_ROOT:-/xrk}/body"
    shopt -s nullglob
    local qf
    for qf in "${qq_dir}"/qq_*.json; do
        local qq links
        qq="$(basename "$qf" | sed 's/^qq_//;s/.json$//')"
        links="$(napcat_load_qq_config "$qf" | jq -c '.links[]?|select(.enabled==true)')"
        [ -z "$links" ] && _w "QQ $qq 无启用连接" && continue
        while IFS= read -r link; do
            local id lbl
            id="$(echo "$link" | jq -r '.framework_id')"
            lbl="$(napcat_get_framework "$id" | jq -r '.label // .id // empty')"
            [ -z "$lbl" ] && lbl="$id"
            _o "QQ $qq → $lbl :$(echo "$link" | jq -r '.port // empty')"
        done <<< "$links"
    done
    echo ""

    echo "[ WebUI ]"
    local wf="${NAPCAT_CONFIG_DIR}/webui.json"
    if [ ! -f "$wf" ]; then _w "webui.json 未生成"; else
        case "$(jq -r '.host' "$wf")" in 0.0.0.0|::) _f "WebUI 公网监听" ;; *) _o "WebUI host=$(jq -r '.host' "$wf") port=$(jq -r '.port' "$wf")" ;; esac
        case "$(jq -r '.token' "$wf")" in ""|napcat) _w "WebUI token 弱或空" ;; *) _o "WebUI token 已设" ;; esac
    fi
    [ -d "${NAPCAT_CONFIG_DIR%/config}/pty" ] && _w "pty/ 存在"
    echo ""
    echo "汇总: $issues 失败, $warns 警告, $ok 通过"
    [ "$issues" -gt 0 ] && return 1
    return 0
}

# 供 dialog 展示：id label port root
napcat_framework_menu_lines() {
    napcat_load_prefs | jq -r '.frameworks[] | "\(.id)|\(.label)|\(.default_port)|\(.root)"'
}
