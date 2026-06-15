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

# 统一 dialog 主题（供 jsdialog / 插件等触屏菜单复用）
XRK_DIALOG_BACKTITLE="${XRK_DIALOG_BACKTITLE:-向日葵脚本助手}"
XRK_DIALOG_HEIGHT="${XRK_DIALOG_HEIGHT:-20}"
XRK_DIALOG_WIDTH="${XRK_DIALOG_WIDTH:-60}"

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

# [统一交互 API] 各菜单脚本复用，减少重复 read/echo

menu_normalize_choice() {
    echo "$1" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]'
}

menu_should_exit() {
    local choice="$1" mode="${2:-back}"
    [ -z "$choice" ] && return 1
    [ "$choice" = "0" ] || [ "$choice" = "q" ] && return 0
    [ "$mode" = "back" ] && [ "$choice" = "${MENU_OPT_COUNT}" ] && return 0
    return 1
}

menu_is_exit_choice() {
    menu_should_exit "$1" "${2:-back}"
}

menu_read_choice() {
    local prompt="${1:-请选择 [1-${MENU_OPT_COUNT}]: }"
    local raw
    if ! read -rp "$prompt" raw; then
        echo ""
        return 1
    fi
    menu_normalize_choice "$raw"
}

menu_msg_err()  { echo -e "${red}${1:-无效选择}${bg}"; }
menu_msg_ok()   { echo -e "${green}${1:-完成}${bg}"; }
menu_msg_warn() { echo -e "${yellow}${1}${bg}"; }

menu_read_text() {
    local prompt="$1" val
    IFS= read -rp "$prompt" val || return 1
    printf '%s' "$val"
}

menu_confirm() {
    local prompt="$1" pattern="${2:-^[Yy]$}" answer
    read -rp "$prompt " answer
    [[ "$answer" =~ $pattern ]]
}

menu_pause() {
    read -rp "${1:-按回车继续...}" _ </dev/tty 2>/dev/null || read -rp "${1:-按回车继续...}" _
}

# 标准文字菜单循环：menu_run_loop "标题" opt1 opt2 ... -- handler
# handler 接收选项编号 1..N；返回非 0 时结束循环
menu_run_loop() {
    local title="$1" choice
    shift
    local -a _mrun_opts=()
    local _mrun_handler=""
    while [ $# -gt 0 ] && [ "$1" != "--" ]; do
        _mrun_opts+=("$1")
        shift
    done
    if [ "${1:-}" = "--" ]; then
        shift
        _mrun_handler="${1:-}"
    elif [ "${#_mrun_opts[@]}" -gt 0 ]; then
        local _last=$(( ${#_mrun_opts[@]} - 1 ))
        _mrun_handler="${_mrun_opts[$_last]}"
        unset "_mrun_opts[$_last]"
    fi
    if [ "${#_mrun_opts[@]}" -gt 0 ] && [[ "${_mrun_opts[0]}" =~ ^[[:space:]]+$ ]] && [ ${#_mrun_opts[0]} -le 4 ]; then
        _mrun_opts=("${_mrun_opts[@]:1}")
    fi
    if [ -z "$_mrun_handler" ]; then
        menu_msg_err "menu_run_loop: 缺少 handler"
        return 1
    fi
    if ! type "$_mrun_handler" &>/dev/null; then
        menu_msg_err "menu_run_loop: 未找到函数 $_mrun_handler"
        return 1
    fi
    while true; do
        menu_show "$title" "${_mrun_opts[@]}"
        choice=$(menu_read_choice "请选择 [1-${MENU_OPT_COUNT}]，0/q 返回: ") || exit 0
        menu_should_exit "$choice" back && return 0
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$MENU_OPT_COUNT" ]; then
            "$_mrun_handler" "$choice" || return $?
        else
            menu_msg_err
        fi
        echo
    done
}

# dialog 统一主题（jsdialog / 插件触屏菜单）
xrk_dialog() {
    dialog --backtitle "${XRK_DIALOG_BACKTITLE}" "$@"
}

xrk_dialog_msgbox() {
    xrk_dialog --msgbox "$1" "${2:-6}" "${3:-44}"
}

xrk_dialog_infobox() {
    xrk_dialog --infobox "$1" "${2:-3}" "${3:-44}"
}

# 葵崽根目录（仅返回已探测到的路径，未安装时为空）
xrk_yz_dir() {
    echo "${yz:-${xyz:-}}"
}

# 葵子根目录（仅返回已探测到的路径，未安装时为空）
xrk_agt_dir() {
    echo "${agt:-}"
}

葵崽路径() { xrk_yz_dir; }
葵子路径() { xrk_agt_dir; }

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
    if [ "$need_common" = "1" ] && ! type detect_os &>/dev/null; then
        if [ -f "$root/shell_modules/xrk_base.sh" ]; then
            # shellcheck source=/dev/null
            source "$root/shell_modules/xrk_base.sh"
            xrk_加载底层 common
        elif [ -f "$root/shell_modules/common.sh" ]; then
            # shellcheck source=/dev/null
            source "$root/shell_modules/common.sh"
        fi
    fi
    if [ -z "${caidan1:-}" ] && [ -f "$root/.init" ]; then
        # shellcheck source=/dev/null
        source "$root/.init"
    elif [ -z "${color_red:-}" ] && [ -f "$root/shell_modules/color.sh" ]; then
        # shellcheck source=/dev/null
        source "$root/shell_modules/color.sh"
        [ -f "$root/.color" ] && source "$root/.color" 2>/dev/null || true
    fi
    ensure_menu_colors
    if [ "$need_check" = "1" ]; then
        type check_changes &>/dev/null && check_changes
        if [ -z "${yz:-}" ] || [ -z "${agt:-}" ]; then
            type search_directories &>/dev/null && search_directories
        fi
    fi
    red="${color_red:-\033[31m}"
    green="${bold_green:-\033[1;32m}"
    yellow="${color_yellow:-\033[33m}"
    bg="${bg:-\033[0m}"
    RED="${RED:-$red}"
    GREEN="${GREEN:-$green}"
    YELLOW="${YELLOW:-$yellow}"
    NC="${NC:-$bg}"
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
    [ -d "$1" ] || { menu_msg_err "${2:-目录 $1 不存在}"; return 1; }
}

menu_require_repo() {
    local msg="${1:-请先 xm→2 安装本仓库到 ${XRK_ROOT:-/xrk}}"
    if type xrk_is_script_repo &>/dev/null && xrk_is_script_repo; then
        return 0
    fi
    menu_msg_err "$msg"
    return 1
}

menu_check_file() {
    [ -f "$1" ] || { menu_msg_err "${2:-文件 $1 不存在}"; return 1; }
}

menu_validate_input() {
    [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ] \
        || { menu_msg_err "${4:-无效的输入}"; return 1; }
}

run_software() {
    if ! type xrk_run_script &>/dev/null; then
        if type _xrk_ensure_common &>/dev/null; then
            _xrk_ensure_common
        elif type xrk_source_common &>/dev/null; then
            xrk_source_common
        else
            # shellcheck source=/dev/null
            [ -f "${XRK_ROOT:-/xrk}/shell_modules/common.sh" ] && source "${XRK_ROOT:-/xrk}/shell_modules/common.sh" \
                || source <(curl -sL "${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}/shell_modules/common.sh")
        fi
    fi
    xrk_run_script "$@"
}
执行软件安装() { run_software "$@"; }
