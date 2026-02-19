#!/data/data/com.termux/files/usr/bin/bash

TERMUX_DIR="$PREFIX"
SCRIPT_RAW_BASE="${SCRIPT_RAW_BASE:-https://raw.gitcode.com/Xrkseek/xrk-projects-scripts/raw/master}"
source <(curl -sL "$SCRIPT_RAW_BASE/shell_modules/Termux.sh")

换源魔法
yes | pkg update -y
字体键盘魔法

if ! command -v sshpass &> /dev/null; then
    pkg install -y sshpass
fi
if ! command -v ssh &> /dev/null; then
    pkg install -y openssh
fi


read_non_empty() {
    local prompt="$1"
    local default_value="$2"
    local input
    if [ -n "$default_value" ]; then
        read -p "$prompt (默认为 $default_value): " input
        if [ -z "$input" ]; then
            echo "$default_value"
        else
            echo "$input"
        fi
    else
        while true; do
            read -p "$prompt" input
            if [ -n "$input" ]; then
                echo "$input"
                break
            else
                echo "输入不能为空，请重新输入。"
            fi
        done
    fi
}

ip_address=$(read_non_empty "请输入目标主机的IP地址：")
port=$(read_non_empty "请输入目标主机的SSH端口", "22")
ssh_password=$(read_non_empty "请输入目标主机的SSH密码：")
self_start=$(read_non_empty "请输入自定义启动命令：")
user_id=$(read_non_empty "请输入用户名", "root")


SSHPASS_PATH=$(command -v sshpass)
SSH_PATH=$(command -v ssh)

cat > "$TERMUX_DIR/bin/${self_start}" <<EOF
#!/usr/bin/env bash
echo "正在连接 ${user_id}@${ip_address}:${port} ..."
"${SSHPASS_PATH}" -p '${ssh_password}' "${SSH_PATH}" -o StrictHostKeyChecking=no -p ${port} "${user_id}@${ip_address}"
EOF
chmod 777 "$TERMUX_DIR/bin/${self_start}"

if ! grep -Fxq "echo 连接 ssh@${ip_address}:${port} 请输入${self_start}" "$HOME/.bashrc"; then
    echo "echo 连接 ssh@${ip_address}:${port} 请输入${self_start}" >> "$HOME/.bashrc"
fi
source ~/.bashrc