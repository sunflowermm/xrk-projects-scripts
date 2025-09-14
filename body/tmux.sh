#!/bin/bash

# 配置变量
SESSION_NAME="新年快乐"
TMUX_CONF="/xrk/body/.tmux.conf"

# 创建桌面端布局
create_desktop_layout() {
    tmux new-session -d -s "$SESSION_NAME" -n "来财" "bash /xrk/body/window_a.sh; exec bash"
    tmux split-window -v -t "$SESSION_NAME:来财" "bash /xrk/body/window_a1.sh; exec bash"
    tmux new-window -t "$SESSION_NAME" -n "来福" "bash /xrk/body/window_b.sh; exec bash"
    tmux split-window -h -t "$SESSION_NAME:来福" "bash /xrk/body/window_b.sh; exec bash"
    tmux new-window -t "$SESSION_NAME" -n "来运" "bash /xrk/body/window_c.sh; exec bash"
    tmux split-window -h -t "$SESSION_NAME:来运" "bash /xrk/body/window_c.sh; exec bash"
    tmux select-pane -t 0
    tmux split-window -v "exec bash"
    tmux select-window -t "$SESSION_NAME:来财"
}

# 错误处理函数
handle_error() {
    echo "错误: $1" >&2
    exit 1
}

# 检查依赖
check_dependencies() {
    command -v tmux >/dev/null 2>&1 || handle_error "未安装 tmux"
    [ -f "$TMUX_CONF" ] || handle_error "配置文件不存在: $TMUX_CONF"
    [ -f "/xrk/body/window_a.sh" ] || handle_error "window_a.sh 不存在"
    [ -f "/xrk/body/window_b.sh" ] || handle_error "window_b.sh 不存在"
    [ -f "/xrk/body/window_c.sh" ] || handle_error "window_c.sh 不存在"
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    if [ -n "$TMUX" ]; then
        tmux source-file "$TMUX_CONF"
        return
    fi
    
    # 检查会话是否存在
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux attach-session -t "$SESSION_NAME"
    else
        # 如果会话不存在，创建新会话
        create_desktop_layout
        tmux source-file "$TMUX_CONF"
        tmux attach-session -t "$SESSION_NAME"
    fi
}

main