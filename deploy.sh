#!/bin/bash
# stock-tick 部署脚本
# 用法: ./deploy.sh [cos|netlify|both]

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEX="$PROJECT_DIR/index.html"
COSCLI="/tmp/coscli"
COS_BUCKET="stock-tick-1422784620"
COS_ENDPOINT="cos.ap-shanghai.myqcloud.com"
COS_ID="${COS_SECRET_ID}"
COS_KEY="${COS_SECRET_KEY}"

PLATFORM="${1:-}"

if [ -z "$PLATFORM" ]; then
  echo "部署到哪个平台？"
  echo "  cos     → 腾讯云 COS"
  echo "  netlify → Netlify（需浏览器）"
  echo "  both    → 两个都部署"
  read -p "请选择 [cos/netlify/both]: " PLATFORM
fi

deploy_cos() {
  echo "☁️  部署到腾讯云 COS ..."
  if [ ! -f "$COSCLI" ]; then
    curl -fsSL https://cosbrowser.cloud.tencent.com/software/coscli/coscli-mac -o "$COSCLI" && chmod +x "$COSCLI"
  fi
  "$COSCLI" cp "$INDEX" "cos://$COS_BUCKET/index.html" --meta "Content-Type:text/html"
  echo "✅ COS 部署完成"
  echo "   https://stock-tick-1422784620.cos-website.ap-shanghai.myqcloud.com"
}

deploy_netlify() {
  echo "🌐 部署到 Netlify ..."
  cd "$PROJECT_DIR"
  zip -r /tmp/stock-tick-deploy.zip . -x ".DS_Store" > /dev/null
  echo "📦 请在浏览器中打开 https://app.netlify.com/projects/stock-tick/overview"
  echo "   拖拽 /tmp/stock-tick-deploy.zip 到页面上传区域"
}

case "$PLATFORM" in
  cos)
    deploy_cos
    ;;
  netlify)
    deploy_netlify
    ;;
  both)
    deploy_cos
    deploy_netlify
    ;;
  *)
    echo "❌ 无效选项: $PLATFORM"
    exit 1
    ;;
esac
