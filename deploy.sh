#!/bin/bash
# stock-tick 部署脚本 — GitHub Pages
# 用法: ./deploy.sh "更新说明"

set -e
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MSG="${1:-update}"

echo "🐙 推送到 GitHub Pages ..."
cd "$PROJECT_DIR"
git add -A
git commit -m "$MSG" || echo "（无变更或已是最新）"
git push
echo ""
echo "✅ 已推送，稍等 1 分钟生效"
echo "   https://khaosnie.github.io/stock-tick/"
