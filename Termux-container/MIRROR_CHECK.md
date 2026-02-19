# Termux 容器镜像源检查报告

## 一、镜像源可用性

| 镜像站 | URL | 状态 | 说明 |
|--------|-----|------|------|
| 清华大学 TUNA | `mirrors.tuna.tsinghua.edu.cn/lxc-images/images` | ✅ 可用 | 同步完整，含 ubuntu/debian/alpine/archlinux/fedora/centos 等 |
| 南京大学 | `mirror.nju.edu.cn/lxc-images/images` | ✅ 可用 | 同步完整 |
| 北京外国语大学 | `mirrors.bfsu.edu.cn/lxc-images/images` | ⚠️ 待验证 | 可能可用，偶发超时 |
| 中国科学技术大学 | `mirrors.ustc.edu.cn/lxc-images/images` | ❌ 不可用 | 该路径不存在，USTC 未提供 LXC 镜像 |
| 官方 Linux Containers | `images.linuxcontainers.org/images` | ✅ 可用 | 上游源，国外访问较慢 |

**建议**：移除 USTC 或将其置于末位，避免无效重试。

---

## 二、版本时效性（截至 2026-02）

| 发行版 | 当前配置 | 官方最新 | 建议 |
|--------|----------|----------|------|
| Ubuntu | noble (24.04 LTS) | noble, plucky, questing | ✅ noble 为 LTS，保持 |
| Debian | bookworm (12) | bookworm, trixie | ✅ bookworm 稳定，保持 |
| Alpine | 3.22 | 3.20, 3.21, 3.22, 3.23, edge | ✅ 已更新为 3.22 |
| Arch Linux | current | current | ✅ 滚动发布，保持 |
| Fedora | 43 | 41, 42, 43 | ✅ 已更新为 43 |
| CentOS | 9-Stream | 9-Stream, **10-Stream** | ✅ 9 稳定，10 已发布可作备选 |

---

## 三、各发行版配置文件差异

| 项目 | Debian/Ubuntu | Alpine | Arch/Fedora/CentOS |
|------|---------------|--------|---------------------|
| **PATH** | +/usr/games:/usr/local/games (Debian) | 无 games | 标准 PATH |
| **locale** | locale-gen + update-locale | 仅 export LANG | locale-gen（部分有） |
| **bash** | 默认有 | 需 apk add bash | 默认有 |
| **profile.d 脚本** | locale-gen; bash .xrk | export LANG; bash/sh .xrk | 同 Debian |
| **locale.conf** | /etc/locale.conf | 同左 + profile.d/locale.sh | 同 Debian |

---

## 四、镜像路径格式

统一格式：`{mirror}/{DISTRO}/{RELEASE}/{ARCH}/default/{build_date}/rootfs.tar.xz`

- **ARCH**：arm64 | amd64
- **build_date**：由脚本从目录列表取最新（如 `20260218_07:42`）
- **DISTRO/RELEASE** 示例：
  - ubuntu/noble
  - debian/bookworm
  - alpine/3.20
  - archlinux/current
  - fedora/43
  - centos/9-Stream
