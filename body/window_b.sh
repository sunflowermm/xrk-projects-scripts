#!/bin/bash
# tmux 窗格占位
[ -f /xrk/.init ] && source /xrk/.init
cd /root
source /xrk/shell_modules/init.sh
source /xrk/shell_modules/github.sh
check_changes
search_directories