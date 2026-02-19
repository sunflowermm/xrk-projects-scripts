#!/bin/bash
# 统一 LTS/最新版本号，供 Node/yq/pnpm/Python/ffmpeg 等安装脚本复用
# 安装脚本应 source 本文件后使用：NODE_LTS_VERSION, YQ_VERSION, PNPM_VERSION, PYTHON_LTS_VERSION, FFMPEG_VERSION

# Node.js 最新 LTS（优先动态获取，失败回退 v24.13.1）
NODE_LTS_VERSION="${NODE_LTS_VERSION:-}"
if [ -z "$NODE_LTS_VERSION" ]; then
    if command -v jq &>/dev/null; then
        NODE_LTS_VERSION=$(curl -sL https://nodejs.org/dist/index.json 2>/dev/null | jq -r '.[] | select(.lts != false) | .version' 2>/dev/null | head -1)
    elif command -v python3 &>/dev/null; then
        NODE_LTS_VERSION=$(curl -sL https://nodejs.org/dist/index.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((v['version'] for v in d if v.get('lts')), 'v24.13.1'))" 2>/dev/null)
    fi
fi
NODE_LTS_VERSION="${NODE_LTS_VERSION:-v24.13.1}"

# yq 最新稳定版
YQ_VERSION="${YQ_VERSION:-v4.52.4}"

# pnpm 最新稳定版
PNPM_VERSION="${PNPM_VERSION:-v10.29.3}"

# Python 稳定版（uv 安装用）
PYTHON_LTS_VERSION="${PYTHON_LTS_VERSION:-3.12}"

# ffmpeg BtbN 构建：使用 latest 标签
FFMPEG_VERSION="${FFMPEG_VERSION:-latest}"

export NODE_LTS_VERSION YQ_VERSION PNPM_VERSION PYTHON_LTS_VERSION FFMPEG_VERSION
