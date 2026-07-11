#!/bin/bash
# stock-tick 部署脚本
# 用法: ./deploy.sh "更新说明"

set -e
cd "$(dirname "$0")"

MSG="${1:-update}"

git add -A
git commit -m "$MSG" || { echo "（无变更或已是最新）"; exit 0; }
git push origin main

echo ""
echo "✅ 已推送，30秒 ~ 1分钟生效"
echo "   https://stock-tick-b6k.pages.dev"
