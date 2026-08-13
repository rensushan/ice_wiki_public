#!/bin/bash
set -e

# ========== 自行修改下面变量 ==========
PROJECT_DIR="/home/ice/ice_wiki_public"
VENV_PATH="${PROJECT_DIR}/venv"
TARGET_WWW="/var/www/ice_wiki_public"
# ======================================

echo "===== $(date '+%Y-%m-%d %H:%M:%S') Start deploy ====="

# 进入项目目录
cd "${PROJECT_DIR}"

# 拉取最新代码
git pull origin main

# 激活虚拟环境并构建
source "${VENV_PATH}/bin/activate"
mkdocs build --clean

# 同步产物到Caddy网站目录
rsync -av --delete ./site/ "${TARGET_WWW}/"

deactivate
echo "===== $(date '+%Y-%m-%d %H:%M:%S') Deploy finished ====="