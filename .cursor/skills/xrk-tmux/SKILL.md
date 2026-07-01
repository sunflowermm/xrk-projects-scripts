---
name: xrk-tmux
description: >-
  维护 xrk-projects-scripts 向日葵 tmux 模块（body/tmux.conf、body/tmux.sh、
  body/modules/tmux.sh）。列出会话持久化必选配置与禁止在精简时删除的逻辑。
  在修改 tmux 相关文件、用户反馈 tmux 程序消失/窗口被清空/分离后进程没了时使用。
---

# 向日葵 tmux 规范

## 必选配置（body/tmux.conf，禁止删除）

以下四行是**会话持久化核心**，精简或重构 `tmux.conf` 时**必须保留**，不得合并掉或改成默认值：

```tmux
set -g remain-on-exit failed
set -g exit-empty off
set -g exit-unattached off
setw -g detach-on-destroy off
```


| 选项                      | 作用                             | 误删后果                            |
| ----------------------- | ------------------------------ | ------------------------------- |
| `remain-on-exit failed` | 程序异常退出时保留窗格                    | 改为 `off` 时进程一退出窗格立刻消失，像「程序自己没了」 |
| `exit-empty off`        | 最后一个会话被关闭时不退出 tmux 服务端         | 服务端意外退出，重连全是空窗口                 |
| `exit-unattached off`   | 所有客户端分离后 tmux 服务端继续运行          | **分离后后台程序被杀**，重连会话全空            |
| `detach-on-destroy off` | 销毁 pane/window 时不连带 detach 客户端 | 误删窗格时行为异常                       |


> 历史教训：commit `428bed0` 加入上述保护项，commit `ae1291f` 精简时误删 `exit-unattached off` 与 `detach-on-destroy off`，导致分离后程序丢失。

## body/tmux.sh 禁止写法

精简 `body/tmux.sh` 时**禁止**重新引入以下逻辑：

```bash
# ❌ 禁止：按窗口数判定会话「不可用」并 kill
_tmux_session_usable() { ...; [ "$n" -ge 3 ]; }
tmux kill-session -t "$s"

# ❌ 禁止：每次 attach 都 source-file（干扰运行中会话）
tmux source-file "$TMUX_CONF"

# ❌ 禁止：已有会话上强制重命名窗口（attach 时不应动用户布局）
_tmux_apply_window_names()   # 仅允许在 _tmux_create_session 内设置初始名

# ❌ 禁止：在 tmux 内调用 enter 时再次 reload / apply / 刷新配置
_tmux_reload_config
```

## body/tmux.sh 正确模式

```bash
# ✅ 仅当 tmux 服务端未运行时启动，不重载配置
_tmux_ensure_server() {
    tmux info &>/dev/null && return 0
    [ -f "$TMUX_CONF" ] || return 1
    tmux -f "$TMUX_CONF" start-server 2>/dev/null
}

# ✅ 仅当会话不存在时创建默认布局，已有会话直接 attach
tmux has-session -t "$SESSION_NAME" 2>/dev/null || _tmux_create_session

# ✅ 配置重载仅由用户手动触发（前缀 Alt+Space + r，见 tmux.conf bind r）
```

## 相关文件职责


| 文件                             | 职责                                                   |
| ------------------------------ | ---------------------------------------------------- |
| `body/tmux.conf`               | 主配置模板，含上表四行必选                                        |
| `body/tmux-menus.conf`         | 键盘菜单绑定（`@XRK_MENU@` 占位）                              |
| `body/tmux-menu.sh`            | 菜单项唯一定义 + `--emit-mouse-binds`                       |
| `body/modules/tmux.sh`         | 安装包 + `--link-only` 写入 `~/.tmux.conf`                |
| `body/tmux.sh`                 | `xrk-tmux` 入口：attach 或 create，不 kill、不 reload        |
| `body/modules/tmux_profile.sh` | 无参数 `tmux` → `xrk-tmux`；禁 `XRK_TMUX_NO_WRAPPER=1` 可关 |


## 改完自检

```bash
# 1. 四行必选仍在模板里
grep -E 'remain-on-exit|exit-empty|exit-unattached|detach-on-destroy' body/tmux.conf

# 2. 无 kill-session / source-file on enter
grep -E 'kill-session|source-file.*TMUX_CONF|_tmux_session_usable|_tmux_apply_window' body/tmux.sh \
  && echo 'FAIL: 发现禁止逻辑' || echo 'OK'

# 3. 语法
bash -n body/tmux.sh body/tmux-menu.sh body/modules/tmux.sh
```

服务器应用：`xrk-tmux --setup`，已在 tmux 内则 `Alt+Space r` 重载。

## systemd 冲突（SSH 断联后 tmux 全灭）

**真凶常不是 tmux.conf，而是旧的 user systemd 单元。**

若存在 `~/.config/systemd/user/tmux.service` 且含：

```ini
ExecStop=/usr/bin/tmux kill-server
```

则 SSH/终端断联 → 最后一个 login session 结束 → `user@0.service` 停止（`Linger=no` 时）→ `tmux.service` 停止 → **ExecStop 执行 kill-server，所有会话和程序全杀**。

典型旧单元（tmux-resurrect 时代遗留）：

```ini
[Service]
Type=forking
ExecStart=/usr/bin/tmux new-session -d
ExecStop=/root/.tmux/plugins/tmux-resurrect/scripts/save.sh
ExecStop=/usr/bin/tmux kill-server
KillMode=control-group
```

与 xrk-tmux 冲突点：

- 会创建名为 `0` 的孤儿会话，与「新年快乐」并存
- resurrect 插件已被 `body/modules/tmux.sh` 删除，ExecStop 第一条会失败
- tmux 服务端挂在 `user@0.service` 下，logout 即触发 kill-server

**服务器排查：**

```bash
systemctl --user cat tmux.service 2>/dev/null
loginctl show-user $(whoami) -p Linger
grep -E 'kill-server|tmux.service' ~/.config/systemd/user/tmux.service 2>/dev/null
pgrep -a tmux; tmux ls
cat /proc/$(tmux display -p '#{pid}')/cgroup   # 若在 app.slice/tmux.service 则受 systemd 管
```

**修复（不断现有会话）：**

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
cp ~/.config/systemd/user/tmux.service{,.bak}
# 去掉 kill-server，或改为空 ExecStop
cat > ~/.config/systemd/user/tmux.service << 'EOF'
[Unit]
Description=deprecated — use xrk-tmux
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/bin/true
[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
loginctl enable-linger $(whoami)
systemctl --user disable tmux.service
```

日常只用 `**xrk-tmux**` 管理会话，不要 `systemctl --user start tmux.service`。

## 常见故障


| 现象               | 原因                                                  | 处理                                |
| ---------------- | --------------------------------------------------- | --------------------------------- |
| 终端断联一会 tmux 全没   | `tmux.service` ExecStop `kill-server` + `Linger=no` | 见上节 systemd 修复                    |
| 分离后程序没了          | `exit-unattached` 被删或改为 on                          | 恢复四行必选配置并 `--setup`               |
| 程序退出后窗格消失        | `remain-on-exit off`                                | 改为 `failed`                       |
| 重连是全新三窗口布局       | 旧版 `kill-session` 重建 或 tmux 服务端已退出                  | 确认 `body/tmux.sh` 无 kill；查 OOM/重启 |
| 窗口名被改回「来财/来福/来运」 | attach 时调用了 `_tmux_apply_window_names`              | 只在 `_tmux_create_session` 设名      |
| 多余会话 `0`         | 旧 `tmux new-session -d` systemd 单元                  | 禁用 tmux.service，用 xrk-tmux        |


