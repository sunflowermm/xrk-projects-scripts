#!/bin/bash
# NapCat 安装（Linux QQ + Shell 注入，不含 CLI；启动用 nt）
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://gitee.com/xrkseek/xrk-projects-scripts/raw/master}"
_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo .)"
for _bootstrap in "/xrk/shell_modules/install_script_common.sh" "${_script_dir}/../shell_modules/install_script_common.sh"; do
    if [ -f "$_bootstrap" ]; then
        # shellcheck source=/dev/null
        source "$_bootstrap"
        break
    fi
done
if ! type init_install_env &>/dev/null; then
    # shellcheck source=/dev/null
    source <(curl -sL "${SCRIPT_RAW_BASE}/shell_modules/install_script_common.sh" 2>/dev/null) || true
fi
type init_install_env &>/dev/null && init_install_env "${XRK_SOURCE:-3}" || true
type xrk_colors &>/dev/null && xrk_colors 2>/dev/null || true
CYAN="${BLUE:-\033[1;36m}"
NC="${NC:-\033[0m}"
RED="${RED:-\033[31m}"
GREEN="${GREEN:-\033[1;32m}"
YELLOW="${YELLOW:-\033[33m}"

TARGET_FOLDER="/opt/QQ/resources/app/app_launcher"

function log() {
    local time msg
    time=$(date +"%Y-%m-%d %H:%M:%S")
    msg="[${time}]: $1"
    case "$1" in
        *"失败"*|*"错误"*|*"无法连接"*|*"不存在"*) echo -e "${RED}${msg}${NC}" ;;
        *"成功"*) echo -e "${GREEN}${msg}${NC}" ;;
        *"忽略"*|*"跳过"*) echo -e "${YELLOW}${msg}${NC}" ;;
        *) echo -e "${CYAN}${msg}${NC}" ;;
    esac
}

# 执行命令并统一报错（合并原 run_cmd 逻辑）
run_cmd() { log "$2中..."; if ! eval "$1"; then log "$2失败"; exit 1; fi; log "$2成功"; }

# 架构检测：优先用 common.detect_arch，否则 fallback
function get_system_arch() {
    if type detect_arch &>/dev/null; then
        case "$(detect_arch)" in
            x64)   system_arch="amd64" ;;
            arm64) system_arch="arm64" ;;
            armv7l) system_arch="armhf" ;;
            *) log "无法识别的系统架构"; exit 1 ;;
        esac
    else
        system_arch=$(uname -m | sed 's/aarch64/arm64/;s/x86_64/amd64/')
        [ -z "$system_arch" ] || [ "$system_arch" = "none" ] && { log "无法识别的系统架构"; exit 1; }
    fi
    log "当前系统架构: ${system_arch}"
}

# 包管理器检测：委托 common.detect_apt_dnf_pm
function set_package_tool() {
    if type detect_apt_dnf_pm &>/dev/null; then
        package_manager=$(detect_apt_dnf_pm) || { log "目前仅支持 apt-get/dnf"; exit 1; }
    else
        command -v apt-get &>/dev/null && package_manager="apt-get" \
            || command -v dnf &>/dev/null && package_manager="dnf" \
            || { log "未找到 apt-get/dnf"; exit 1; }
    fi
    case "$package_manager" in
        apt-get) package_installer="dpkg" ;;
        dnf) package_installer="rpm" ;;
    esac
    log "当前包管理器: ${package_manager}"
}

function install_dependency() {
    log "开始更新依赖..."
    set_package_tool

    if type install_pkg &>/dev/null; then
        if [ "${package_manager}" = "apt-get" ]; then
            apt-get update -y -qq 2>/dev/null || true
            for p in zip unzip jq curl xvfb screen xauth procps; do install_pkg "$p" 2>/dev/null || true; done
        elif [ "${package_manager}" = "dnf" ]; then
            dnf install -y epel-release 2>/dev/null || true
            for p in zip unzip jq curl xorg-x11-server-Xvfb screen procps-ng; do install_pkg "$p" 2>/dev/null || true; done
        fi
    else
        if [ "${package_manager}" = "apt-get" ]; then
            run_cmd "apt-get update -y -qq" "更新软件包列表"
            run_cmd "apt-get install -y -qq zip unzip jq curl xvfb screen xauth procps" "安装依赖"
        elif [ "${package_manager}" = "dnf" ]; then
            run_cmd "dnf install -y epel-release" "安装 epel"
            run_cmd "dnf install --allowerasing -y zip unzip jq curl xorg-x11-server-Xvfb screen procps-ng" "安装依赖"
        fi
    fi
    log "更新依赖成功"
}

function create_tmp_folder() {
    if [ -d "./NapCat" ] && [ "$(ls -A ./NapCat)" ]; then
        log "文件夹已存在且不为空(./NapCat)，请重命名后重新执行脚本以防误删"
        exit 1
    fi
    mkdir -p ./NapCat
}

function clean() {
    rm -rf ./NapCat ./NapCat.Shell.zip
    [ -f "/etc/init.d/napcat" ] && rm -f /etc/init.d/napcat
    [ -d "${TARGET_FOLDER}/napcat.packet" ] && rm -rf "${TARGET_FOLDER}/napcat.packet"
}

function download_napcat() {
    create_tmp_folder
    default_file="NapCat.Shell.zip"
    if [ -f "${default_file}" ]; then
        # 默认使用原始 GitHub 地址，并尽量通过 github.sh 自动加代理
        log "检测到已下载NapCat安装包,跳过下载..."
    else
        log "开始下载NapCat安装包,请稍等..."
        napcat_download_url="https://github.com/NapNeko/NapCatQQ/releases/latest/download/NapCat.Shell.zip"
        xrk_download "${napcat_download_url}" "${default_file}" 3 || { log "文件下载失败"; clean; exit 1; }
        log "${default_file} 成功下载"
    fi

    log "正在验证 ${default_file}..."
    unzip -t "${default_file}" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        log "文件验证失败, 请检查错误。"
        clean
        exit 1
    fi

    log "正在解压 ${default_file}..."
    unzip -q -o -d ./NapCat NapCat.Shell.zip
    if [ $? -ne 0 ]; then
        log "文件解压失败, 请检查错误。"
        clean
        exit 1
    fi
}

function get_qq_target_version() {
    linuxqq_target_version=$(jq -r '.linuxVersion' ./NapCat/qqnt.json)
    linuxqq_target_verhash=$(jq -r '.linuxVerHash' ./NapCat/qqnt.json)
}

function compare_linuxqq_versions() {
    local ver1="${1}" #当前版本
    local ver2="${2}" #目标版本

    IFS='.-' read -r -a ver1_parts <<< "${ver1}"
    IFS='.-' read -r -a ver2_parts <<< "${ver2}"

    local length=${#ver1_parts[@]}
    if [ ${#ver2_parts[@]} -lt $length ]; then
        length=${#ver2_parts[@]}
    fi

    for ((i=0; i<length; i++)); do
        if ((ver1_parts[i] > ver2_parts[i])); then
            force="n"
            return
        elif ((ver1_parts[i] < ver2_parts[i])); then
            force="y"
            return
        fi
    done

    if [ ${#ver1_parts[@]} -gt ${#ver2_parts[@]} ]; then
        force="n"
    elif [ ${#ver1_parts[@]} -lt ${#ver2_parts[@]} ]; then
        force="y"
    else
        force="n"
    fi
}

function check_linuxqq(){
    get_qq_target_version
    linuxqq_package_name="linuxqq"
    
    if [[ -z "${linuxqq_target_version}" || "${linuxqq_target_version}" == "null" ]] || [[ -z "${linuxqq_target_verhash}" || "${linuxqq_target_verhash}" == "null" ]]; then
        log "无法获取目标QQ版本, 请检查错误。"
        exit 1
    fi

    linuxqq_target_build=${linuxqq_target_version##*-}

    log "最低linuxQQ版本: ${linuxqq_target_version}, 构建: ${linuxqq_target_build}"
    
    # 添加自动强制重装选项
    if [ "${auto_force}" = "y" ]; then
        force="y"
    fi
    
    if [ "${force}" = "y" ]; then
        log "强制重装模式..."
        install_linuxqq
    else
        if [ "${package_installer}" = "rpm" ]; then
            if rpm -q ${linuxqq_package_name} &> /dev/null; then
                linuxqq_installed_version=$(rpm -q --queryformat '%{VERSION}' ${linuxqq_package_name})
                linuxqq_installed_build=${linuxqq_installed_version##*-}
                log "${linuxqq_package_name} 已安装, 版本: ${linuxqq_installed_version}, 构建: ${linuxqq_installed_build}"

                compare_linuxqq_versions "${linuxqq_installed_version}" "${linuxqq_target_version}"
                if [ "${force}" = "y" ]; then
                    log "版本未满足要求, 自动启用强制重装模式..."
                    install_linuxqq
                else
                    log "版本已满足要求, 无需更新。"
                    update_linuxqq_config "${linuxqq_installed_version}" "${linuxqq_installed_build}"
                fi
            else
                install_linuxqq
            fi
        elif [ "${package_installer}" = "dpkg" ]; then
            if dpkg -l | grep ${linuxqq_package_name} &> /dev/null; then
                linuxqq_installed_version=$(dpkg -l | grep "^ii" | grep "linuxqq" | awk '{print $3}')
                linuxqq_installed_build=${linuxqq_installed_version##*-}
                log "${linuxqq_package_name} 已安装, 版本: ${linuxqq_installed_version}, 构建: ${linuxqq_installed_build}"

                compare_linuxqq_versions "${linuxqq_installed_version}" "${linuxqq_target_version}"
                if [ "${force}" = "y" ]; then
                    log "版本未满足要求, 自动启用强制重装模式..."
                    install_linuxqq
                else
                    log "版本已满足要求, 无需更新。"
                    update_linuxqq_config "${linuxqq_installed_version}" "${linuxqq_installed_build}"
                fi
            else
                install_linuxqq
            fi
        fi
    fi
}

function install_linuxqq() {
    # 先卸载旧版本QQ
    log "卸载旧版本LinuxQQ..."
    if [ "${package_installer}" = "rpm" ]; then
        rpm -e linuxqq 2>/dev/null || true
    elif [ "${package_installer}" = "dpkg" ]; then
        apt-get remove -y -qq linuxqq 2>/dev/null || true
    fi
    
    base_url="https://dldir1.qq.com/qqfile/qq/QQNT/${linuxqq_target_verhash}/linuxqq_${linuxqq_target_version}"
    get_system_arch
    log "安装LinuxQQ..."
    
    if [ "${system_arch}" = "amd64" ]; then
        if [ "${package_installer}" = "rpm" ]; then
            qq_download_url="${base_url}_x86_64.rpm"
        elif [ "${package_installer}" = "dpkg" ]; then
            qq_download_url="${base_url}_amd64.deb"
        fi
    elif [ "${system_arch}" = "arm64" ]; then
        if [ "${package_installer}" = "rpm" ]; then
            qq_download_url="${base_url}_aarch64.rpm"
        elif [ "${package_installer}" = "dpkg" ]; then
            qq_download_url="${base_url}_arm64.deb"
        fi
    fi

    if ! [[ -f "QQ.deb" || -f "QQ.rpm" ]]; then
        if [ "${qq_download_url}" = "" ]; then
            log "获取QQ下载链接失败, 请检查错误, 或者手动下载QQ安装包并重命名为QQ.deb或QQ.rpm(注意自己的系统架构)放到脚本同目录下。"
            exit 1
        fi
        log "QQ下载链接: ${qq_download_url}"
        log "如果无法下载请手动下载QQ安装包并重命名为QQ.deb或QQ.rpm(注意自己的系统架构)放到脚本同目录下"
    fi

    if [ "${package_manager}" = "dnf" ]; then
        if ! [ -f "QQ.rpm" ]; then
            xrk_download "${qq_download_url}" "QQ.rpm" 3 || { log "文件下载失败, 请检查错误。"; exit 1; }
            log "文件下载成功"
        else
            log "检测到当前目录下存在QQ安装包, 将使用本地安装包进行安装。"
        fi

        run_cmd "dnf localinstall -y ./QQ.rpm" "安装QQ"
        rm -f QQ.rpm
    elif [ "${package_manager}" = "apt-get" ]; then
        if ! [ -f "QQ.deb" ]; then
            xrk_download "${qq_download_url}" "QQ.deb" 3 || { log "文件下载失败, 请检查错误。"; exit 1; }
            log "文件下载成功"
        else
            log "检测到当前目录下存在QQ安装包, 将使用本地安装包进行安装。"
        fi

        run_cmd "apt-get install -f -y -qq ./QQ.deb" "安装QQ"
        run_cmd "apt-get install -y -qq libnss3" "安装libnss3"
        run_cmd "apt-get install -y -qq libgbm1" "安装libgbm1"
        log "安装libasound2中..."
        apt-get install -y -qq libasound2
        if [ $? -eq 0 ]; then
            log "安装libasound2 成功"
        else
            log "安装libasound2 失败"
            log "尝试安装libasound2t64中..."
            apt-get install -y -qq libasound2t64
            if [ $? -eq 0 ]; then
                log "安装libasound2t64 成功"
            else
                log "安装libasound2t64 失败"
                exit 1
            fi
        fi
        rm -f QQ.deb
    fi
    update_linuxqq_config "${linuxqq_target_version}" "${linuxqq_target_build}"
}

function update_linuxqq_config() {
    log "正在更新用户QQ配置..."

    confs=$(find /home -name "config.json" -path "*/.config/QQ/versions/*" 2>/dev/null)
    if [ -f "/root/.config/QQ/versions/config.json" ]; then
        confs="/root/.config/QQ/versions/config.json ${confs}"
    fi

    for conf in ${confs}; do
        log "正在修改 ${conf}..."
        jq --arg targetVer "${1}" --arg buildId "${2}" \
        '.baseVersion = $targetVer | .curVersion = $targetVer | .buildId = $buildId' "${conf}" > "${conf}.tmp" && \
        mv "${conf}.tmp" "${conf}" || { log "QQ配置更新失败! "; exit 1; }
    done
    log "更新用户QQ配置成功..."
}

function check_napcat() {
    napcat_target_version=$(jq -r '.version' "./NapCat/package.json")
    if [[ -z "${napcat_target_version}" || "${napcat_target_version}" == "null" ]]; then
        log "无法获取NapCatQQ版本, 请检查错误。"
        exit 1
    else
        log "最新NapCatQQ版本: v${napcat_target_version}"
    fi

    if [ "$force" = "y" ]; then
        log "强制重装模式..."
        install_napcat
    else
        if [ -d "${TARGET_FOLDER}/napcat" ]; then
            napcat_installed_version=$(jq -r '.version' "${TARGET_FOLDER}/napcat/package.json")
            IFS='.' read -r i1 i2 i3 <<< "${napcat_installed_version}"
            IFS='.' read -r t1 t2 t3 <<< "${napcat_target_version}"
            if (( i1 < t1 || (i1 == t1 && i2 < t2) || (i1 == t1 && i2 == t2 && i3 < t3) )); then
                install_napcat
            else
                log "已安装最新版本, 无需更新。"
            fi
        else
            install_napcat
        fi
    fi
}

function install_napcat() {
    # 确保目标文件夹存在
    log "检查目标文件夹..."
    if [ ! -d "/opt/QQ" ]; then
        log "QQ未正确安装，目录/opt/QQ不存在，请先安装QQ"
        exit 1
    fi
    
    if [ ! -d "/opt/QQ/resources" ]; then
        log "QQ安装不完整，缺少resources目录"
        exit 1
    fi
    
    if [ ! -d "/opt/QQ/resources/app" ]; then
        log "QQ安装不完整，缺少app目录"
        exit 1
    fi
    
    # 创建app_launcher目录（如果不存在）
    if [ ! -d "${TARGET_FOLDER}" ]; then
        log "创建目标文件夹 ${TARGET_FOLDER}..."
        mkdir -p "${TARGET_FOLDER}"
        if [ $? -ne 0 ]; then
            log "创建目标文件夹失败，请检查权限"
            exit 1
        fi
    fi
    
    # 创建napcat目录
    if [ ! -d "${TARGET_FOLDER}/napcat" ]; then
        log "创建NapCat文件夹..."
        mkdir -p "${TARGET_FOLDER}/napcat/"
        if [ $? -ne 0 ]; then
            log "创建NapCat文件夹失败"
            exit 1
        fi
    fi

    log "正在移动文件..."
    cp -r -f ./NapCat/* "${TARGET_FOLDER}/napcat/"
    if [ $? -ne 0 -a $? -ne 1 ]; then
        log "文件移动失败, 请检查错误。"
        clean
        exit 1
    else
        log "移动文件成功"
    fi

    chmod -R +x "${TARGET_FOLDER}/napcat/"
    _napcat_mod="${_script_dir}/../shell_modules/napcat_security.sh"
    if [ -f "$_napcat_mod" ]; then
        # shellcheck source=/dev/null
        source "$_napcat_mod"
        NAPCAT_CONFIG_DIR="${TARGET_FOLDER}/napcat/config"
        napcat_refresh_frameworks >/dev/null
        napcat_apply_webui
        log "已扫描框架写入 napcat_prefs.json，用 nt → 框架管理 查看"
    fi

    log "正在修补文件..."
    echo "(async () => {await import('file:///${TARGET_FOLDER}/napcat/napcat.mjs');})();" > /opt/QQ/resources/app/loadNapCat.js
    if [ $? -ne 0 ]; then
        log "loadNapCat.js文件写入失败, 请检查错误。"
        clean
        exit 1
    else
        log "修补文件成功"
    fi
    
    modify_qq_config
    clean
}

function modify_qq_config() {
    log "正在修改QQ启动配置..."

    if [ ! -f "/opt/QQ/resources/app/package.json" ]; then
        log "找不到QQ配置文件 /opt/QQ/resources/app/package.json"
        exit 1
    fi

    if jq '.main = "./loadNapCat.js"' /opt/QQ/resources/app/package.json > ./package.json.tmp; then
        mv ./package.json.tmp /opt/QQ/resources/app/package.json
        log "修改QQ启动配置成功..."
    else
        log "修改QQ启动配置失败..."
        exit 1
    fi
}

function show_main_info() {
    log "\n================== NapCat安装完成 =================="
    log "WebUI: http://127.0.0.1:6099/webui （Token 见启动日志或 ${TARGET_FOLDER}/napcat/config/webui.json）"
    log "启动: nt [QQ号] [框架端口]  例: nt 123456789 2537"
    log "安全: WebUI 已限本机；OneBot 服务端若启用请务必配置 token"
    log "===================================================="
}

function shell_help() {
    cat <<'EOF'
================== 命令选项 ==================
  --force           强制重装 LinuxQQ 与 NapCat
  --auto-force      版本不匹配时自动强制重装（默认开启）
  --no-auto-force   关闭自动强制重装
  -h, --help        显示本帮助

示例:
  bash NapCat.sh
  bash NapCat.sh --force
  bash NapCat.sh --no-auto-force
==============================================
EOF
}

function main() {
    # 默认启用自动强制重装
    auto_force="y"
    
    while [[ $# -ge 1 ]]; do
        case $1 in
            --force)
                force="y"
                shift
                ;;
            --auto-force)
                auto_force="y"
                shift
                ;;
            --no-auto-force)
                auto_force="n"
                shift
                ;;
            --help|-h)
                shell_help
                exit 0
                ;;
            *)
                shell_help
                exit 1
                ;;
        esac
    done

    clear
    log "================== NapCat 安装脚本 =================="
    log "开始执行安装流程..."
    log "===================================================="
    
    install_dependency
    download_napcat
    check_linuxqq
    check_napcat
    show_main_info
    clean
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    log "请以root权限运行此脚本"
    exit 1
fi

main "$@"