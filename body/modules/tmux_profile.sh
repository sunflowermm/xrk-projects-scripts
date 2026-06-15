# xrk: 无参数 tmux 时进入向日葵桌面（由 profile 加载）
# 禁用：export XRK_TMUX_NO_WRAPPER=1
if [ -z "${XRK_TMUX_NO_WRAPPER:-}" ] && command -v tmux &>/dev/null; then
    tmux() {
        if [ -n "$TMUX" ] || [ $# -gt 0 ]; then
            command tmux "$@"
            return $?
        fi
        if [ -x "${XRK_BIN:-/usr/local/bin}/xrk-tmux" ]; then
            "${XRK_BIN:-/usr/local/bin}/xrk-tmux"
            return $?
        fi
        [ -f "${XRK_ROOT:-/xrk}/body/tmux.sh" ] && bash "${XRK_ROOT:-/xrk}/body/tmux.sh"
    }
fi
