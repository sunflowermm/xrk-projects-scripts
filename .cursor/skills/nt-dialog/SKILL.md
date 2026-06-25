---
name: nt-dialog
description: >-
  编写/调试 xrk-projects-scripts 中 nt 与 jsdialog 的 dialog TUI。
  覆盖 menu/form/inputbox/checklist 返回值捕获、表单解析、WebUI 合并写入。
  在修改 body/writeto/nt、body/menu/jsdialog.sh 或用户反馈 dialog 改值不生效时使用。
---

# nt / dialog TUI 规范

## 捕获返回值（必须）

dialog 把**结果写在 stderr**，UI 画在 stdout。禁止在函数里用 `exec 3>&1` + `$()` + `2>&1 1>&3` 捕获 **form**（会丢字段，保存后永远落回默认值）。

**唯一推荐写法**（`nt_dialog_capture`）：

```bash
tmp="$(mktemp "${TMPDIR:-/tmp}/nt_dialog.XXXXXX")"
dialog --backtitle "$BACK" "$@" 2>"$tmp" >/dev/tty || st=$?
out="$(cat "$tmp")"
rm -f "$tmp"
```

| 控件 | 捕获 | 禁止 |
|------|------|------|
| `--menu` / `--yesno` | `nt_dialog_capture` | `exec 3>&1` 包在 `$()` 里 |
| `--form` | `nt_dialog_capture` + `nt_parse_form` | `sed -n1p` + `tr -d '[:space:]'` 解析 host |
| `--inputbox` / `--checklist` | `nt_dialog_capture` | 与 menu 混用不同捕获方式 |

## 解析 `--form`

- 每个可编辑字段占 **一行**，顺序与 `--form` 声明一致
- 用 `nt_parse_form "$values" N name1 name2 ...` 拆字段
- **host 只用 `nt_field_trim`**（去首尾空白），禁止 `tr -d '[:space:]'`（会把 `::` 等地址破坏或丢字段）
- 端口/限速可 trim 后校验数字

## WebUI 写入（napcat_security.sh）

1. **合并**写入 `webui.json`，只改 `host/port/token/loginRate`，保留 `theme` 等 NapCat 字段
2. `napcat_load_prefs` 合并顺序：`.[1] * .[0]`（文件覆盖 defaults）
3. 改 WebUI 前 **`killall qq`**，否则 NapCat 运行中会把内存配置写回磁盘
4. Token 留空 → 保留 webui.json 现有 token；保存后回写 `napcat_prefs.webui_token`

## 自测清单

改完 nt 后在本地跑（`tests/` 已 gitignore）：

```bash
bash tests/nt_dialog_selftest.sh   # 解析快测
bash tests/nt_dialog_all.sh        # 全模式（30 项，含真实 dialog --input-fd）
```

**已验证项（`nt_dialog_all.sh`）**

| 模式 | 写法 | 结果 |
|------|------|------|
| `nt_field_trim` | IPv6 `::` / `fe80::1` / 首尾空格 | 通过 |
| `--form` | `nt_parse_form` 2 字段 / 5 字段 | 通过 |
| `--form` 校验 | 字段不足拒绝 | 通过 |
| `nt_yes` | yes/no/1/0/是/否 | 通过 |
| `nt_form_default` | 去换行、引号→单引号 | 通过 |
| `--menu` | `2>"$tmp" >/dev/null` + `--input-fd` + `--default-item` | 通过 |
| `--yesno` | 默认确认 stderr 空 | 通过 |
| `--inputbox` | 默认值回读 | 通过 |
| `--form` 实机 | host=`::` port=6099 | 通过 |
| `napcat_apply_webui` | host=`::` 合并且保留 `theme` | 通过 |

服务器（需先停 QQ）：

```bash
killall qq
cp /path/to/nt /usr/local/bin/nt && chmod +x /usr/local/bin/nt
nt --webui-apply
jq '{host,port,token,loginRate,hasTheme:(.theme!=null)}' \
  /opt/QQ/resources/app/app_launcher/napcat/config/webui.json
tail -5 /tmp/nt.log
# WebUI 菜单：监听地址填 :: 或 0.0.0.0 后保存，不应再报「监听地址为空」
```

## 常见故障

| 现象 | 原因 | 处理 |
|------|------|------|
| 改任何值保存后仍是 127.0.0.1/6099/3 | form 返回值丢失 + 代码填默认 | 用 `nt_dialog_capture` |
| 监听地址改为 `::` 报「为空」 | form 首行在 `$()`+`exec 3>&1` 捕获时丢失 | `nt_dialog_capture` + `nt_parse_form` + `nt_field_trim`（勿对 host 用 `tr -d`） |
| webui.json 变回 `host:"::"` 大文件 | NapCat 运行中覆盖 | 先停 qq 再改 |
| 无报错回菜单 | dialog 失败被 `\|\| return` 吞掉 | `nt_err` + `/tmp/nt.log` |

## jsdialog.sh 注意

主菜单 `while` 里 `exec 3>&1; selection=$(... 2>&1 1>&3)` 在**主脚本**可用；**不要**抄到 nt 的函数里给 form 用。inputbox/checklist 应统一改为 `2>"$tmp" >/dev/tty` 或与 nt 相同的 capture  helper。
