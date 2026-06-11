# xrk: 无参数 tmux 时优先 attach 已有会话（由 profile 加载）
# 禁用：export XRK_TMUX_NO_WRAPPER=1
if [ -z "${XRK_TMUX_NO_WRAPPER:-}" ] && command -v tmux &>/dev/null; then
    tmux() {
        if [ -n "$TMUX" ]; then
            command tmux "$@"
            return $?
        fi
        if [ $# -eq 0 ]; then
            if [ -x "${XRK_BIN:-/usr/local/bin}/xrk-tmux" ]; then
                "${XRK_BIN:-/usr/local/bin}/xrk-tmux"
                return $?
            fi
            if [ -f "${XRK_ROOT:-/xrk}/body/tmux.sh" ]; then
                bash "${XRK_ROOT:-/xrk}/body/tmux.sh"
                return $?
            fi
            local _s
            _s=$(command tmux list-sessions -F '#{session_activity} #{session_name}' 2>/dev/null \
                | sort -rn | head -1 | cut -d' ' -f2-)
            if [ -n "$_s" ]; then
                command tmux attach-session -t "$_s"
                return $?
            fi
        fi
        command tmux "$@"
    }
fi
