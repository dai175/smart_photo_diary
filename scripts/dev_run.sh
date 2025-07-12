#!/bin/bash

# 開発用Flutter実行スクリプト
# 使用方法: ./scripts/dev_run.sh [device_id]

# デバイスIDの指定がない場合は一覧表示
if [ -z "$1" ]; then
    echo "利用可能なデバイス:"
    fvm flutter devices
    echo ""
    echo "使用方法: $0 <device_id>"
    echo "例: $0 89182054-6EE7-47B4-B640-0FD00682F5DF"
    exit 1
fi

# .envファイルの存在確認
if [ ! -f ".env" ]; then
    echo "❌ .envファイルが見つかりません"
    echo "プロジェクトルートに.envファイルを作成してください"
    exit 1
fi

# 開発用pubspec.yamlをコピー
echo "🔧 開発環境設定中..."
cp pubspec.dev.yaml pubspec.yaml

# 依存関係更新
echo "📦 依存関係更新中..."
fvm flutter pub get

# アプリ実行
echo "🚀 アプリ起動中..."
fvm flutter run -d "$1"

# 終了時に本番用pubspec.yamlに戻す
echo "🔒 本番環境設定に復元中..."
git checkout pubspec.yaml

echo "✅ 完了"