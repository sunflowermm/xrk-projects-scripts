#!/bin/bash
# 菜单脚本公共函数：自动宽度、对齐、统一边框（完善版）
# 终端列宽约定：英文/数字/符号/空格 = 1 列，中文/CJK/emoji = 2 列
# 支持多种终端宽度计算方法（wc -L、wcwidth、回退算法）
# 依赖：SCRIPT_RAW_BASE（由 repo_source 或 .init 提供）；调用前应 source .init 或 repo_source

# 颜色与边框回退（未 source .init 时仍可正常显示）
ensure_menu_colors() {
    [ -z "$bg" ] && bg="\033[0m"
    [ -z "$caidan1" ] && caidan1="\033[1;32m"
    [ -z "$caidan2" ] && caidan2="\033[1;36m"
    [ -z "$caidan3" ] && caidan3="\033[0;33m"
    MENU_HINT_EXIT="${caidan3}输入 q 或 0 退出${bg}"
}
ensure_menu_colors

# 检测可用的终端宽度计算方法（按终端算法优先级）
_menu_width_method() {
    # 方法1：GNU wc -L（最准确，GNU coreutils支持，计算最长行的显示宽度）
    if command -v wc &>/dev/null; then
        # 测试 wc -L 是否支持（GNU特有）
        if wc -L <<< "测试" &>/dev/null 2>&1; then
            echo "wc_L"
            return 0
        fi
    fi
    # 方法2：Python wcwidth库（如果安装，符合Unicode标准）
    if command -v python3 &>/dev/null && python3 -c "import wcwidth" 2>/dev/null; then
        echo "python_wcwidth"
        return 0
    fi
    # 方法3：回退到简化算法（所有非ASCII=2列，适用于大多数终端）
    echo "simple"
}

# 计算字符串在终端中的显示列数（多方法支持，按终端算法优先级）
# ASCII/空格/符号=1列，CJK/emoji/其他非ASCII=2列
menu_display_width() {
    local str="$1" method width
    method=$(_menu_width_method)
    
    case "$method" in
        wc_L)
            # GNU wc -L：计算最长行的显示宽度（最准确，符合终端实际显示）
            width=$(printf '%s' "$str" | wc -L 2>/dev/null)
            [ -n "$width" ] && [ "$width" -gt 0 ] && echo "$width" && return 0
            ;;
        python_wcwidth)
            # Python wcwidth库（符合Unicode标准，处理emoji更准确）
            width=$(python3 -c "import wcwidth; print(sum(wcwidth.wcwidth(c) for c in '$str'))" 2>/dev/null)
            [ -n "$width" ] && [ "$width" -gt 0 ] && echo "$width" && return 0
            ;;
    esac
    # 统一回退到简化算法（所有非ASCII按2列算，适用于所有终端）
    menu_display_width_simple "$str"
}

# 简化版算法：所有非ASCII按2列算（适用于大多数终端）
menu_display_width_simple() {
    local str="$1" w=0 c
    # 按字符遍历（bash的read -n1会正确处理UTF-8字符）
    while IFS= read -r -n1 c; do
        [ -z "$c" ] && continue
        # ASCII范围（0x00-0x7F）= 1列，其他 = 2列
        if [[ "$c" =~ [^\x00-\x7F] ]]; then
            ((w+=2))
        else
            ((w+=1))
        fi
    done < <(printf '%s' "$str")
    echo "$w"
}

# 自动计算菜单宽度：根据标题和所有选项计算最小宽度（最小28，自动加宽）
# 用法：menu_calc_width "标题" "选项1" "选项2" ...
menu_calc_width() {
    local title="$1" max_w=28 w
    shift
    # 计算标题宽度
    w=$(menu_display_width "$title")
    [ "$w" -gt "$max_w" ] && max_w=$w
    # 计算所有选项宽度（选项格式：前缀"  N  " + 文案）
    local num=1
    for text in "$@"; do
        w=$(menu_display_width "  $num  $text")
        [ "$w" -gt "$max_w" ] && max_w=$w
        ((num++))
    done
    # 最小宽度28，如果超过则加2列边距（保证美观）
    [ "$max_w" -lt 28 ] && max_w=28
    # 如果内容很长，额外加2列边距（避免内容贴边）
    [ "$max_w" -gt 28 ] && max_w=$((max_w + 2))
    # 确保宽度为偶数（保证框线对称）
    [ $((max_w % 2)) -eq 1 ] && ((max_w++))
    echo "$max_w"
}

# 动态生成边框（根据宽度）
# 用法：menu_build_border width [style]，style: top/mid/bot，默认top
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

# 设置动态边框（根据宽度生成边框变量，供旧代码兼容）
# 用法：menu_set_borders width
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
# 默认28列（向后兼容）
menu_set_borders 28

# 在指定列宽内居中显示
menu_center_title() {
    local str="$1" width="${2:-28}" w left right
    w=$(menu_display_width "$str")
    left=$(( (width - w) / 2 ))
    right=$(( width - w - left ))
    printf '%*s%s%*s' "$left" '' "$str" "$right" ''
}

# 生成菜单选项行：前缀 "  N  " + 文案，右侧空格补齐至指定宽度
menu_line_option() {
    local num="$1" text="$2" width="${3:-28}" prefix w tw pad
    prefix="  $num  "
    w=$(menu_display_width "$prefix")
    tw=$(menu_display_width "$text")
    pad=$((width - w - tw))
    [ "$pad" -lt 0 ] && pad=0
    printf '%s%s%*s' "$prefix" "$text" "$pad" ''
}

# 统一菜单显示函数（自动宽度、自动对齐）- 合并所有冗余代码
# 用法：menu_show "标题" "选项1" "选项2" ... [hint]
# 或：menu_show "标题" "prefix" "选项1" "选项2" ... （prefix用于xm/env的"  "前缀）
# 返回：设置的 MENU_W（供后续使用）
menu_show() {
    local title="$1" hint width opts=() prefix=""
    shift
    
    # 检查第一个参数是否是prefix（纯空格字符串，用于xm/env）
    if [ $# -gt 0 ] && [[ "$1" =~ ^[[:space:]]+$ ]] && [ ${#1} -le 4 ]; then
        prefix="$1"
        shift
    fi
    
    # 分离选项和提示语（如果最后一个参数是提示语）
    if [ $# -gt 0 ] && [[ "${@: -1}" =~ ^(输入|按|选择|请|q|Q|退出) ]]; then
        opts=("${@:1:$(($#-1))}")
        hint="${@: -1}"
    else
        opts=("$@")
        hint="$MENU_HINT_EXIT"
    fi
    
    # 自动计算宽度
    width=$(menu_calc_width "$title" "${opts[@]}")
    menu_set_borders "$width"
    
    # 显示菜单（统一格式，支持prefix）
    echo -e "$hint"
    echo -e "${prefix}$MENU_TOP"
    echo -e "${prefix}│${caidan2}$(menu_center_title "$title" "$width")${caidan1}│${bg}"
    echo -e "${prefix}$MENU_MID"
    local num=1
    for opt in "${opts[@]}"; do
        echo -e "${prefix}│${caidan2}$(menu_line_option "$num" "$opt" "$width")${caidan1}│${bg}"
        ((num++))
    done
    echo -e "${prefix}$MENU_BOT"
}

# 双色边框菜单显示函数（用于errorbg等特殊样式）
# 用法：menu_show_double "标题" "选项1" "选项2" ... [hint]
menu_show_double() {
    local title="$1" hint width opts=()
    shift
    
    # 分离选项和提示语
    if [ $# -gt 0 ] && [[ "${@: -1}" =~ ^(输入|按|选择|请|q|Q|退出) ]]; then
        opts=("${@:1:$(($#-1))}")
        hint="${@: -1}"
    else
        opts=("$@")
        hint="$MENU_HINT_EXIT"
    fi
    
    # 自动计算宽度
    width=$(menu_calc_width "$title" "${opts[@]}")
    local border_top=$(menu_build_border "$width" top)
    local border_mid=$(menu_build_border "$width" mid)
    local border_bot=$(menu_build_border "$width" bot)
    
    # 显示菜单（双色边框）
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
    echo -e "${caidan3}${border_bot}${bg}"
    echo
}


# 上移清除 n 行（使用全局 forin，与 xrk/errorbg 等一致）
clear_menu() {
    local n=${forin:-0}
    for ((i=0; i<n; i++)); do
        printf "\e[1A\e[K"
    done
}

# 统一菜单脚本初始化（合并所有冗余的初始化逻辑）
# 用法：menu_init [需要common] [需要check_changes]
# 参数：需要common=1 时加载 common.sh，需要check_changes=1 时执行 check_changes/search_directories
# 注意：此函数在 menu_common.sh 中定义，调用前需先 source menu_common.sh
menu_init() {
    local need_common="${1:-0}"
    local need_check="${2:-0}"
    
    # 统一初始化：.init（提供颜色、路径等）
    # 检查是否已加载 .init（通过检查 color.sh 是否已加载，避免重复加载）
    # 如果 bg 或 color_red 已设置，说明 .init 或 color.sh 已加载，跳过
    if [ -z "${bg:-}" ] && [ -z "${color_red:-}" ]; then
        [ -f /xrk/.init ] && source /xrk/.init
    fi
    
    # 按需加载 common.sh（提供 install_pkg、detect_os 等）
    [ "$need_common" = "1" ] && [ -f /xrk/shell_modules/common.sh ] && source /xrk/shell_modules/common.sh
    
    # 按需执行路径检测（check_changes + search_directories）
    # 如果已加载 .init，它已经执行了 check_changes 和 search_directories，跳过重复执行
    # 检查方法：如果 xyz 或 yz 已设置，说明已执行过路径检测
    if [ "$need_check" = "1" ] && [ -z "${xyz:-}" ] && [ -z "${yz:-}" ]; then
        type check_changes &>/dev/null && check_changes
        type search_directories &>/dev/null && search_directories
    fi
    
    # 统一路径默认值（所有菜单脚本通用）
    yz="${yz:-$HOME/XRK-Yunzai}"
    xyz="${xyz:-$yz}"
    
    # 统一颜色变量（如果未设置则使用回退值）
    red="${color_red:-\033[31m}"
    green="${bold_green:-\033[1;32m}"
    yellow="${color_yellow:-\033[33m}"
    bg="${bg:-\033[0m}"  # 重置颜色代码（如果未设置则使用回退值）
}

# 统一依赖检查函数（合并所有冗余的依赖检查逻辑）
# 用法：menu_check_deps "dep1" "dep2" ... [exit_on_fail]
# exit_on_fail=1 时，依赖缺失则退出；否则尝试安装
menu_check_deps() {
    local exit_on_fail="${@: -1}"
    local deps=("${@:1:$(($#-1))}")
    
    # 如果最后一个参数不是数字，说明没有 exit_on_fail，所有参数都是依赖
    if [[ ! "$exit_on_fail" =~ ^[01]$ ]]; then
        deps=("$@")
        exit_on_fail=0
    fi
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            if type install_pkg &>/dev/null; then
                install_pkg "$dep" || {
                    [ "$exit_on_fail" = "1" ] && { echo "依赖 $dep 安装失败"; exit 1; }
                }
            else
                [ "$exit_on_fail" = "1" ] && { echo "缺少依赖 $dep，请安装"; exit 1; }
            fi
        fi
    done
}

# 统一目录检查函数（合并所有冗余的目录检查逻辑）
# 用法：menu_check_dir "路径" [错误消息]
# 返回：0=存在，1=不存在（会显示错误消息）
menu_check_dir() {
    local dir="$1" msg="${2:-目录 $1 不存在}"
    if [ ! -d "$dir" ]; then
        echo -e "${red}错误: $msg${bg}"
        return 1
    fi
    return 0
}

# 统一文件检查函数（合并所有冗余的文件检查逻辑）
# 用法：menu_check_file "文件路径" [错误消息]
# 返回：0=存在，1=不存在（会显示错误消息）
menu_check_file() {
    local file="$1" msg="${2:-文件 $1 不存在}"
    if [ ! -f "$file" ]; then
        echo -e "${red}错误: $msg${bg}"
        return 1
    fi
    return 0
}

# 统一输入验证函数（合并所有冗余的输入验证逻辑）
# 用法：menu_validate_input "输入" "最小值" "最大值" [错误消息]
# 返回：0=有效，1=无效（会显示错误消息）
menu_validate_input() {
    local input="$1" min="$2" max="$3" msg="${4:-无效的输入}"
    if [[ ! "$input" =~ ^[0-9]+$ ]] || [ "$input" -lt "$min" ] || [ "$input" -gt "$max" ]; then
        echo -e "${red}错误: $msg${bg}"
        return 1
    fi
    return 0
}

# 统一执行安装脚本：优先本地，否则远程（支持复杂场景：代理、网络重试、错误处理）
# 用法：run_software "project-install/software/chromium" [参数...]
run_software() {
    local path="$1"
    shift
    local args=("$@")
    local base="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
    local retry=0 max_retries=3
    
    # 优先本地执行
    if [ -f "/xrk/$path" ]; then
        bash "/xrk/$path" "${args[@]}"
        return $?
    fi
    
    # 远程执行（带重试机制）
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
