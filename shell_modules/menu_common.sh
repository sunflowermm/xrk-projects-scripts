#!/bin/bash
# 菜单公共：宽度/对齐/边框、menu_show、menu_init、run_software 等；依赖 SCRIPT_RAW_BASE（.init 或 repo_source）

ensure_menu_colors() {
    [ -z "$bg" ] && bg="\033[0m"
    [ -z "$caidan1" ] && caidan1="\033[1;32m"
    [ -z "$caidan2" ] && caidan2="\033[1;36m"
    [ -z "$caidan3" ] && caidan3="\033[0;33m"
    MENU_HINT_EXIT="${caidan3}输入 q 或 0 退出${bg}"
}
ensure_menu_colors

_menu_width_method() {
    if command -v wc &>/dev/null && wc -L <<< "测试" &>/dev/null 2>&1; then
        echo "wc_L"; return 0
    fi
    command -v python3 &>/dev/null && python3 -c "import wcwidth" 2>/dev/null && { echo "python_wcwidth"; return 0; }
    echo "simple"
}

menu_display_width() {
    local str="$1" method width
    method=$(_menu_width_method)
    
    case "$method" in
        wc_L)
            width=$(printf '%s' "$str" | wc -L 2>/dev/null)
            [ -n "$width" ] && [ "$width" -gt 0 ] && echo "$width" && return 0
            ;;
        python_wcwidth)
            width=$(python3 -c "import wcwidth; print(sum(wcwidth.wcwidth(c) for c in '$str'))" 2>/dev/null)
            [ -n "$width" ] && [ "$width" -gt 0 ] && echo "$width" && return 0
            ;;
    esac
    menu_display_width_simple "$str"
}

menu_display_width_simple() {
    local str="$1" w=0 c
    while IFS= read -r -n1 c; do
        [ -z "$c" ] && continue
        if [[ "$c" =~ [^\x00-\x7F] ]]; then
            ((w+=2))
        else
            ((w+=1))
        fi
    done < <(printf '%s' "$str")
    echo "$w"
}

menu_calc_width() {
    local title="$1" max_w=28 w
    shift
    w=$(menu_display_width "$title"); [ "$w" -gt "$max_w" ] && max_w=$w
    local num=1
    for text in "$@"; do
        w=$(menu_display_width "  $num  $text"); [ "$w" -gt "$max_w" ] && max_w=$w
        ((num++))
    done
    [ "$max_w" -lt 28 ] && max_w=28
    [ "$max_w" -gt 28 ] && max_w=$((max_w + 2))
    [ $((max_w % 2)) -eq 1 ] && ((max_w++))
    echo "$max_w"
}

menu_build_border() {
    local width="$1" style="${2:-top}" i
    local dashes=""
    for ((i=0; i<width; i++)); do
        dashes="${dashes}─"
    done
    case "$style" in
        top) echo "╭${dashes}╮" ;;
        mid) echo "├${dashes}┤" ;;
        bot) echo "╰${dashes}╯" ;;
        *) echo "╭${dashes}╮" ;;
    esac
}

menu_set_borders() {
    local width="${1:-28}"
    MENU_W=$width
    MENU_BORDER_TOP=$(menu_build_border "$width" top)
    MENU_BORDER_MID=$(menu_build_border "$width" mid)
    MENU_BORDER_BOT=$(menu_build_border "$width" bot)
    MENU_TOP="${caidan1}${MENU_BORDER_TOP}${bg}"
    MENU_MID="${caidan1}${MENU_BORDER_MID}${bg}"
    MENU_BOT="${caidan1}${MENU_BORDER_BOT}${bg}"
}
menu_set_borders 28

menu_center_title() {
    local str="$1" width="${2:-28}" w left right
    w=$(menu_display_width "$str")
    left=$(( (width - w) / 2 ))
    right=$(( width - w - left ))
    printf '%*s%s%*s' "$left" '' "$str" "$right" ''
}

menu_line_option() {
    local num="$1" text="$2" width="${3:-28}" prefix w tw pad
    prefix="  $num  "
    w=$(menu_display_width "$prefix")
    tw=$(menu_display_width "$text")
    pad=$((width - w - tw))
    [ "$pad" -lt 0 ] && pad=0
    printf '%s%s%*s' "$prefix" "$text" "$pad" ''
}

_menu_parse_opts_hint() {
    [ $# -gt 0 ] && [[ "${@: -1}" =~ ^(输入|按|选择|请).+ ]] && { _MENU_OPTS=("${@:1:$(($#-1))}"); _MENU_HINT="${@: -1}"; } || { _MENU_OPTS=("$@"); _MENU_HINT="$MENU_HINT_EXIT"; }
}

menu_show() {
    local title="$1" hint width opts=() prefix=""
    shift
    [ $# -gt 0 ] && [[ "$1" =~ ^[[:space:]]+$ ]] && [ ${#1} -le 4 ] && { prefix="$1"; shift; }
    _menu_parse_opts_hint "$@"
    opts=("${_MENU_OPTS[@]}") hint="$_MENU_HINT"
    width=$(menu_calc_width "$title" "${opts[@]}")
    menu_set_borders "$width"
    echo -e "$hint"
    echo -e "${prefix}$MENU_TOP"
    echo -e "${prefix}${caidan1}│${caidan2}$(menu_center_title "$title" "$width")${caidan1}│${bg}"
    echo -e "${prefix}$MENU_MID"
    local num=1
    for opt in "${opts[@]}"; do
        echo -e "${prefix}${caidan1}│${caidan2}$(menu_line_option "$num" "$opt" "$width")${caidan1}│${bg}"
        ((num++))
    done
    echo -e "${prefix}$MENU_BOT"
    MENU_OPT_COUNT=${#opts[@]}
}

menu_is_exit_choice() {
    local ch="$1"
    [ "$ch" = "0" ] || [ "$ch" = "q" ] || [ "$ch" = "${MENU_OPT_COUNT}" ]
}

menu_show_double() {
    local title="$1" hint width opts=()
    shift
    _menu_parse_opts_hint "$@"
    opts=("${_MENU_OPTS[@]}") hint="$_MENU_HINT"
    width=$(menu_calc_width "$title" "${opts[@]}")
    local border_top=$(menu_build_border "$width" top)
    local border_mid=$(menu_build_border "$width" mid)
    local border_bot=$(menu_build_border "$width" bot)
    echo -e "$hint"
    echo -e "${caidan3}${border_top}${bg}"
    echo -e "${caidan2}$(menu_center_title "$title" "$width")${bg}"
    echo -e "${caidan1}${border_mid}${bg}"
    local num=1
    for opt in "${opts[@]}"; do
        echo -e "${caidan2}$(menu_line_option "$num" "$opt" "$width")${bg}"
        ((num++))
    done
    echo -e "${caidan1}${border_bot}${bg}"
    echo
    MENU_OPT_COUNT=${#opts[@]}
}

clear_menu() {
    local n="$1"
    # 更智能的策略：
    # - 如显式传入行数，则只回收指定行（兼容特殊需求）
    # - 否则直接整屏清理，避免因额外 echo / 注释性输出导致的行数误差
    if [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -gt 0 ]; then
        local i
        for ((i=0; i<n; i++)); do
            printf "\e[1A\e[K"
        done
    else
        command -v clear &>/dev/null && clear || printf "\033[2J\033[H"
    fi
}

menu_init() {
    local need_common="${1:-0}" need_check="${2:-0}" root="${XRK_ROOT:-/xrk}"
    [ -z "${bg:-}" ] && [ -z "${color_red:-}" ] && [ -f "$root/.init" ] && source "$root/.init"
    [ "$need_common" = "1" ] && [ -f "$root/shell_modules/common.sh" ] && source "$root/shell_modules/common.sh"
    if [ "$need_check" = "1" ] && [ -z "${xyz:-}" ] && [ -z "${yz:-}" ]; then
        type check_changes &>/dev/null && check_changes
        type search_directories &>/dev/null && search_directories
    fi
    yz="${yz:-${YZ_DEFAULT_DIR:-$HOME/XRK-Yunzai}}"
    xyz="${xyz:-$yz}"
    red="${color_red:-\033[31m}"
    green="${bold_green:-\033[1;32m}"
    yellow="${color_yellow:-\033[33m}"
    bg="${bg:-\033[0m}"
}

menu_check_deps() {
    local exit_on_fail="${@: -1}" deps=("${@:1:$(($#-1))}")
    [[ ! "$exit_on_fail" =~ ^[01]$ ]] && { deps=("$@"); exit_on_fail=0; }
    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null && continue
        if type install_pkg &>/dev/null; then
            install_pkg "$dep" || { [ "$exit_on_fail" = "1" ] && { echo "依赖 $dep 安装失败"; exit 1; }; }
        else
            [ "$exit_on_fail" = "1" ] && { echo "缺少依赖 $dep，请安装"; exit 1; }
        fi
    done
}

menu_check_dir() {
    [ -d "$1" ] || { echo -e "${red}错误: ${2:-目录 $1 不存在}${bg}"; return 1; }
}

menu_check_file() {
    [ -f "$1" ] || { echo -e "${red}错误: ${2:-文件 $1 不存在}${bg}"; return 1; }
}

menu_validate_input() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ] || { echo -e "${red}错误: ${4:-无效的输入}${bg}"; return 1; }
}

run_software() {
    local path="$1"; shift; local args=("$@") root="${XRK_ROOT:-/xrk}" base="${SCRIPT_RAW_BASE:-${_XRK_DEFAULT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}}" retry=0 max_retries=3
    [ -f "$root/$path" ] && { bash "$root/$path" "${args[@]}"; return $?; }
    while [ $retry -lt $max_retries ]; do
        if bash <(curl -sL --connect-timeout 10 --max-time 60 "$base/$path" 2>/dev/null) "${args[@]}"; then
            return 0
        fi
        retry=$((retry + 1))
        [ $retry -lt $max_retries ] && sleep 2
    done
    echo -e "\033[31m[错误] 远程执行失败: $base/$path\033[0m" >&2
    return 1
}
