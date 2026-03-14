#!/bin/bash

# Xcode Archive用準備スクリプト
# 使用方法: ./scripts/prepare_xcode.sh

echo "🔧 Xcode Archive用準備開始..."

# .envファイルの存在確認
if [ ! -f ".env" ]; then
    echo "❌ .envファイルが見つかりません"
    exit 1
fi

# APIキーを.envファイルから読み込み
source .env

if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ GEMINI_API_KEYが設定されていません"
    exit 1
fi

# jqコマンドの確認
if ! command -v jq &>/dev/null; then
    echo "❌ jqがインストールされていません。brew install jq でインストールしてください"
    exit 1
fi

# dart_defines.jsonを安全に一時生成（--dart-define-from-fileで使用）
dart_defines_file="$(mktemp "${TMPDIR:-/tmp}/dart_defines.XXXXXX.json")"
chmod 600 "$dart_defines_file"
trap 'rm -f "$dart_defines_file"' EXIT
jq -n --arg key "$GEMINI_API_KEY" '{GEMINI_API_KEY: $key}' > "$dart_defines_file"

echo "🔧 Xcode準備中（APIキー設定のみ）..."

# APIキーをファイル経由で渡す
fvm flutter build ios \
    --dart-define-from-file="$dart_defines_file" \
    --release

if [ $? -eq 0 ]; then
    echo "✅ Xcode準備完了"
    echo ""
    echo "🎯 次の手順:"
    echo "1. Xcodeで ios/Runner.xcworkspace を開く"
    echo "2. Product → Archive を実行"
    echo "3. Distribute App → TestFlight"
    echo ""
    echo "💡 APIキーは設定済み、アーカイブをお待ちください"
else
    echo "❌ 準備失敗"
    exit 1
fi