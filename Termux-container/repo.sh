#!/data/data/com.termux/files/usr/bin/bash

# --------------------- 可选的颜色定义 ---------------------
RED='\033[0;1;31m'
GREEN='\033[0;1;32m'
YELLOW='\033[0;1;33m'
BLUE='\033[0;1;34m'
CYAN='\033[0;1;36m'
NC='\033[0m'

# 特征文件路径
FLAG_FILE="$HOME/.termux_mirror_configured"

# 检查是否已经配置过
if [ -f "$FLAG_FILE" ]; then
    echo -e "${YELLOW}检测到已经配置过镜像源！${NC}"
    echo -e "${CYAN}当前使用的镜像源信息：${NC}"
    cat "$FLAG_FILE"
    echo -e "\n${YELLOW}如果需要重新配置，请先删除标记文件：${NC}"
    echo -e "${BLUE}rm $FLAG_FILE${NC}"
    exit 0
fi

# --------------------- 需要用到的数组 ---------------------
mirror_names=(
    "清华大学 TUNA"
    "中国科学技术大学 USTC"
    "北京外国语大学 BFSU"
    "阿里云 Aliyun"
    "南京大学 NJU"
    "北京大学 PKU"
    "重庆邮电大学 CQUPT"
    "山东大学 SDU"
)

mirror_urls=(
    "https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main"
    "https://mirrors.ustc.edu.cn/termux/termux-main"
    "https://mirrors.bfsu.edu.cn/termux/apt/termux-main"
    "https://mirrors.aliyun.com/termux/termux-main"
    "https://mirrors.nju.edu.cn/termux/termux-main"
    "https://mirrors.pku.edu.cn/termux/termux-main"
    "https://mirrors.cqupt.edu.cn/termux/termux-main"
    "https://mirrors.sdu.edu.cn/termux/termux-main"
)

available_mirrors=()
available_names=()

# 临时文件存储可用镜像源信息
temp_file=$(mktemp)

# 确保临时文件被删除
trap "rm -f $temp_file" EXIT

# --------------------- 检测可用源函数 ---------------------
function show_mirrors() {
    echo -e "${BLUE}正在检测可用的 Termux 镜像源...${NC}"
    echo ""

    # 并发限制（例如 5 个并发）
    max_jobs=5
    current_jobs=0

    for i in "${!mirror_urls[@]}"; do
        {
            mirror_url="${mirror_urls[i]}"
            mirror_name="${mirror_names[i]}"
            
            # 使用 GET 请求检测镜像源是否可用
            if curl --silent --fail --max-time 5 "${mirror_url}/dists/stable/Release" >/dev/null; then
                echo -e "${GREEN}[✔] 可用源: ${mirror_name}${NC}"
                echo "$mirror_url|$mirror_name" >> "$temp_file"
            else
                echo -e "${RED}[✘] 不可用源: ${mirror_name}${NC}"
            fi
        } &
        
        current_jobs=$((current_jobs + 1))
        if [[ "$current_jobs" -ge "$max_jobs" ]]; then
            wait -n
            current_jobs=$((current_jobs - 1))
        fi
    done

    # 等待所有后台任务完成
    wait

    echo ""

    # 读取临时文件中的可用镜像源信息
    while IFS='|' read -r url name; do
        available_mirrors+=("$url")
        available_names+=("$name")
    done < "$temp_file"

    if [ ${#available_mirrors[@]} -eq 0 ]; then
        echo -e "${RED}❌ 没有可用的镜像源，请检查网络连接！${NC}"
        exit 1
    fi
}

# --------------------- 使用原生终端实现交互选择 ---------------------
function select_mirror() {
    echo -e "${CYAN}请选择一个可用的镜像源:${NC}"
    echo ""

    for i in "${!available_names[@]}"; do
        echo -e "${YELLOW}[$((i+1))] ${available_names[i]}${NC}"
    done

    echo ""
    while true; do
        read -p "请输入选择的镜像源编号（例如 1）： " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_mirrors[@]}" ]; then
            selected_mirror_url="${available_mirrors[$((choice-1))]}"
            selected_mirror_name="${available_names[$((choice-1))]}"
            echo -e "${GREEN}已选择: ${selected_mirror_name}${NC}"
            break
        else
            echo -e "${RED}输入无效，请输入一个有效的编号！${NC}"
        fi
    done
}

# --------------------- 备份源函数 ---------------------
function backup_sources() {
    echo -e "${YELLOW}备份当前源列表...${NC}"

    backup_dir="$HOME/.termux_backup_sources"
    mkdir -p "$backup_dir"

    cp $PREFIX/etc/apt/sources.list "$backup_dir/sources.list.bak" 2>/dev/null
    cp $PREFIX/etc/apt/sources.list.d/* "$backup_dir/" 2>/dev/null
    echo -e "${GREEN}✅ 备份完成！备份文件位于 $backup_dir/ ${NC}"
}

# --------------------- 更换源函数 ---------------------
function change_sources() {
    echo -e "${BLUE}正在更换源...${NC}"
    echo "" > $PREFIX/etc/apt/sources.list
    echo "deb $selected_mirror_url stable main" >> $PREFIX/etc/apt/sources.list
    if yes n | apt update -y; then
        echo "配置时间: $(date)" > "$FLAG_FILE"
        echo "使用镜像源: $selected_mirror_name" >> "$FLAG_FILE"
        echo "镜像地址: $selected_mirror_url" >> "$FLAG_FILE"
        echo -e "${GREEN}✅ 源更换成功！当前使用的镜像源为: ${selected_mirror_name}${NC}"
    else
        echo -e "${RED}❌ 源更换失败，请检查镜像源 URL 或网络连接！${NC}"
        exit 1
    fi
}

# --------------------- 主函数 ---------------------
function main() {
    show_mirrors
    select_mirror
    backup_sources
    change_sources
    echo -e "${GREEN}✅ 所有操作完成！Termux 镜像源已成功更换并更新！${NC}"
}

# 执行主函数
main