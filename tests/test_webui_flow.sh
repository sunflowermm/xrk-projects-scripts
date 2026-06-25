#!/bin/bash
# 非交互测试：WebUI prefs → webui.json 全链路
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export XRK_ROOT="$ROOT/test_fixtures/xrk"
export NAPCAT_CONFIG_DIR="$XRK_ROOT/napcat/config"
export NAPCAT_PREFS_FILE="$XRK_ROOT/body/napcat_prefs.json"

rm -rf "$XRK_ROOT"
mkdir -p "$XRK_ROOT/body" "$NAPCAT_CONFIG_DIR"

# shellcheck source=/dev/null
source "$ROOT/shell_modules/napcat_security.sh"

fail() { echo "FAIL: $*"; exit 1; }
ok() { echo "OK: $*"; }

command -v jq >/dev/null || fail "需要 jq"

# 1) 初始 prefs 不存在 → load
prefs="$(napcat_load_prefs)" || true
echo "$prefs" | jq -e '.webui_port == 6099' >/dev/null || fail "load defaults"

# 2) save prefs
new='{"webui_host":"127.0.0.1","webui_port":6099,"webui_token":"test-token-abc","login_rate":5,"disable_pty":true,"frameworks":[]}'
napcat_save_prefs "$new" || fail "save_prefs: ${NAPCAT_LAST_ERR:-?}"

# 3) apply webui
napcat_apply_webui || fail "apply_webui: ${NAPCAT_LAST_ERR:-?}"

wf="$(napcat_webui_file)"
[ -f "$wf" ] || fail "webui.json 未生成: $wf"

host=$(jq -r '.host' "$wf")
port=$(jq -r '.port' "$wf")
token=$(jq -r '.token' "$wf")
rate=$(jq -r '.loginRate' "$wf")

[ "$host" = "127.0.0.1" ] || fail "host=$host"
[ "$port" = "6099" ] || fail "port=$port"
[ "$token" = "test-token-abc" ] || fail "token=$token"
[ "$rate" = "5" ] || fail "loginRate=$rate"

# 4) 空 token 应保留现有 webui token
napcat_save_prefs "$(echo "$new" | jq '.webui_token=""')" || fail "clear token prefs"
napcat_apply_webui || fail "apply keep token: ${NAPCAT_LAST_ERR:-?}"
token2=$(jq -r '.token' "$wf")
[ "$token2" = "test-token-abc" ] || fail "token not preserved: $token2"

# 5) 模拟 nt 里 jq 合并（含 --argjson）
prefs="$(napcat_load_prefs)"
h="127.0.0.1"; p="6099"; t="newtok"; r="3"; dp=true
merged="$(echo "$prefs" | jq \
  --arg h "$h" --argjson p "$p" --arg t "$t" --argjson r "$r" \
  --argjson dp "$dp" \
  '.webui_host=$h|.webui_port=$p|.webui_token=$t|.login_rate=$r|.disable_pty=$dp')" \
  || fail "nt-style jq merge"
echo "$merged" | jq -e '.webui_token=="newtok"' >/dev/null || fail "merge token"

# 6) 合并顺序：用户值不能被 defaults 覆盖
napcat_save_prefs '{"webui_host":"10.0.0.1","webui_port":7000,"webui_token":"keep-me","login_rate":9,"disable_pty":false,"frameworks":[]}'
loaded="$(napcat_load_prefs)"
echo "$loaded" | jq -e '.webui_token=="keep-me" and .webui_port==7000 and .login_rate==9' >/dev/null \
  || fail "load_prefs 合并仍覆盖用户值: $(echo "$loaded"|jq -c '{webui_token,webui_port,login_rate}')"

ok "全部通过"
