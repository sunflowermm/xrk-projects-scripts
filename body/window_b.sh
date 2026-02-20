#!/bin/bash
# tmux 窗格占位
root="${XRK_ROOT:-/xrk}"
[ -f "$root/.init" ] && source "$root/.init"
cd /root
source "$root/shell_modules/init.sh"
source "$root/shell_modules/github.sh"
check_changes
search_directories