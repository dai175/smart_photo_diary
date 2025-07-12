#!/bin/bash

# TestFlightアップロードスクリプト
# 使用方法: ./scripts/upload_testflight.sh

echo "🚀 TestFlightアップロード開始..."

# IPAファイルの存在確認
IPA_FILE="build/ios/ipa/Smart Photo Diary.ipa"
if [ ! -f "$IPA_FILE" ]; then
    echo "❌ IPAファイルが見つかりません: $IPA_FILE"
    echo "先に ./scripts/testflight_build.sh を実行してください"
    exit 1
fi

echo "📱 IPAファイル確認: $IPA_FILE"

# Apple ID とパスワードの入力
echo ""
echo "🔐 Apple ID認証情報を入力してください:"
read -p "Apple ID: " APPLE_ID
read -s -p "App用パスワード: " APP_PASSWORD
echo ""
echo ""

echo "📤 TestFlightにアップロード中..."

# altoolでアップロード
xcrun altool --upload-app \
    --file "$IPA_FILE" \
    --type ios \
    --username "$APPLE_ID" \
    --password "$APP_PASSWORD"

if [ $? -eq 0 ]; then
    echo "✅ TestFlightアップロード完了"
    echo ""
    echo "🎯 次の手順:"
    echo "1. App Store Connect → TestFlight を確認"
    echo "2. 処理完了まで数分〜数十分待機"
    echo "3. テスターに配布設定"
else
    echo "❌ アップロード失敗"
    echo ""
    echo "💡 解決方法:"
    echo "1. App用パスワードが正しいか確認"
    echo "2. Apple ID が App Store Connect に登録されているか確認"
    echo "3. Transporter アプリの使用を検討"
fi