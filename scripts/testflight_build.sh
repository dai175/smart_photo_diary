#!/bin/bash

# TestFlight用ビルドスクリプト
# 使用方法: ./scripts/testflight_build.sh

echo "🚀 TestFlight用ビルド開始..."

# jqコマンドの確認
if ! command -v jq &>/dev/null; then
    echo "❌ jqがインストールされていません。brew install jq でインストールしてください"
    exit 1
fi

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

# dart_defines.jsonを生成（--dart-define-from-fileで使用）
# trapで中断時も確実に削除
trap 'rm -f dart_defines.json' EXIT
echo '{}' | jq --arg key "$GEMINI_API_KEY" '.GEMINI_API_KEY = $key' > dart_defines.json

echo "📱 iOS リリースビルド実行中..."

# リリースビルド（APIキーをファイル経由で渡す）
fvm flutter build ipa \
    --dart-define-from-file=dart_defines.json \
    --release

if [ $? -eq 0 ]; then
    echo "✅ IPAファイル生成完了"
    echo "📍 配布可能ファイル: build/ios/ipa/smart_photo_diary.ipa"
    echo ""
    echo "🚀 TestFlightアップロード手順:"
    echo ""
    echo "【方法1: Xcode Organizer（推奨）】"
    echo "1. Xcode → Window → Organizer"
    echo "2. Archives タブ → 右上の + ボタン"
    echo "3. Import → build/ios/ipa/smart_photo_diary.ipa"
    echo "4. Distribute App → App Store Connect → Upload"
    echo ""
    echo "【方法2: Transporter.app】"
    echo "1. Mac App Store から Transporter をダウンロード"
    echo "2. .ipa ファイルをドラッグ&ドロップ"
    echo "3. 配信ボタンをクリック"
    echo ""
    echo "💡 .ipaファイルが生成済みなので、手動アーカイブは不要です"
else
    echo "❌ ビルド失敗"
    exit 1
fi
