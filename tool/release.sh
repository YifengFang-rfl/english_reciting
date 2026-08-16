#!/usr/bin/env bash
#
# 一键构建并发布安装包到 GitHub Release
# 用法:
#   tool/release.sh            # 构建 APK + DMG，并发布到 GitHub Release（版本取 pubspec.yaml）
#   tool/release.sh --skip-build   # 跳过构建，直接用 releases/ 目录下已有的安装包发布
#
# 依赖: flutter, hdiutil (macOS), gh 或 git 凭据中的 GitHub token
set -euo pipefail

cd "$(dirname "$0")/.."   # 切到项目根目录

# ---------- 解析参数 ----------
SKIP_BUILD=0
if [[ "${1:-}" == "--skip-build" ]]; then
  SKIP_BUILD=1
fi

# ---------- 读取版本号 ----------
VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
if [[ -z "$VERSION" ]]; then
  echo "❌ 无法从 pubspec.yaml 读取版本号"
  exit 1
fi
echo "📦 版本: $VERSION"

APK="releases/english_reciting-${VERSION}.apk"
DMG="releases/english_reciting-${VERSION}.dmg"
APP_BUNDLE="build/macos/Build/Products/Release/english_reciting.app"

# ---------- 构建 ----------
if [[ "$SKIP_BUILD" -eq 0 ]]; then
  echo "🔨 构建 Android APK (release)..."
  flutter build apk --release

  echo "🔨 构建 macOS (release)..."
  flutter build macos --release

  # ---------- 打包 DMG ----------
  if [[ ! -d "$APP_BUNDLE" ]]; then
    echo "❌ 找不到 $APP_BUNDLE"
    exit 1
  fi

  echo "💿 打包 DMG..."
  STAGING=$(mktemp -d)
  trap 'rm -rf "$STAGING"' EXIT
  cp -R "$APP_BUNDLE" "$STAGING/"
  ln -s /Applications "$STAGING/Applications"
  hdiutil create \
    -volname "english_reciting" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG"
  echo "✅ DMG 已生成: $DMG"
fi

# ---------- 复制产物到 releases/ ----------
mkdir -p releases
if [[ "$SKIP_BUILD" -eq 0 ]]; then
  cp "build/app/outputs/flutter-apk/app-release.apk" "$APK"
fi

if [[ ! -f "$APK" || ! -f "$DMG" ]]; then
  echo "❌ 缺少安装包文件:"
  [[ -f "$APK" ]] || echo "   - $APK"
  [[ -f "$DMG" ]] || echo "   - $DMG"
  exit 1
fi

ls -lh "$APK" "$DMG"

# ---------- GitHub 凭据 ----------
# 优先使用 gh 登录态；否则回退到 git 凭据里的 token
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  GH_CMD="gh"
else
  TOKEN=$(printf "protocol=https\nhost=github.com\n" | git credential fill 2>/dev/null | sed -n 's/^password=//p')
  if [[ -z "$TOKEN" ]]; then
    echo "❌ 未找到 GitHub 凭据。请先运行: gh auth login"
    exit 1
  fi
  export GH_TOKEN="$TOKEN"
  GH_CMD="gh"
fi

REPO=$(git remote get-url origin | sed -E 's#.*github.com[:/]##; s#\.git$##')
TAG="v${VERSION}"
TITLE="v${VERSION} - 英语背诵"
NOTES="英语背诵 App v${VERSION} 安装包

- Android APK
- macOS DMG

> 安装包超过 25MB，以 GitHub Release 附件形式发布。仓库内 releases/ 目录由 Git LFS 管理。"

echo "🚀 发布到 GitHub Release: $REPO ($TAG)"

# 若 tag 已存在则删除（覆盖重发）
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1; then
  echo "⚠️  本地已存在 tag $TAG，删除后重新创建"
  git tag -d "$TAG"
fi

gh release create "$TAG" "$APK" "$DMG" \
  --repo "$REPO" \
  --title "$TITLE" \
  --notes "$NOTES"

echo ""
echo "✅ 发布完成: https://github.com/$REPO/releases/tag/$TAG"
