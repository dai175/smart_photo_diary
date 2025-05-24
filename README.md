# Smart Photo Diary

写真を選ぶだけでAIが自動的に日記を生成してくれる次世代の写真日記アプリです。

## ✨ 特徴

- 📸 写真から自動で日記を生成
- 🎨 直感的で美しいUI/UX
- 🔒 完全プライベート - データはすべて端末内に保存
- 📊 統計機能で日記の振り返りをサポート
- 🌐 オフライン対応

## 🚀 技術スタック

- **フレームワーク**: Flutter 3.x
- **状態管理**: Riverpod + StateNotifier
- **データベース**: Hive
- **AI処理**: TFLite Flutter Plugin
- **画像処理**: image_picker, image_cropper
- **テスト**: flutter_test, mocktail, integration_test

## 🛠 開発環境構築

### 前提条件

- Flutter SDK (最新安定版)
- Dart SDK (Flutterに同梱)
- Android Studio / Xcode (エミュレータ/実機デバッグ用)

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/your-username/smart-photo-diary.git
cd smart-photo-diary

# 依存関係をインストール
flutter pub get

# コード生成の実行
flutter pub run build_runner build --delete-conflicting-outputs

# アプリを起動
flutter run
```

## 🧪 テストの実行

```bash
# ユニットテストとウィジェットテスト
flutter test

# カバレッジレポートの生成
flutter test --coverage

# 統合テスト
flutter test integration_test/app_test.dart
```

## 📦 リリースビルド

### Android
```bash
flutter build apk --release
# または
flutter build appbundle
```

### iOS (Macのみ)
```bash
flutter build ipa
```

## 🤝 コントリビューション

プルリクエストは歓迎しています。大きな変更の場合は、最初にIssueを開いて議論してください。

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。
