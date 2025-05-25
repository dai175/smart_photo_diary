# Smart Photo Diary

写真を選ぶだけでAIが自動的に日記を生成してくれる次世代の写真日記アプリです。

## ✨ 特徴

- 📸 写真から自動で日記を生成
- 🎨 直感的で美しいUI/UX
- 🔒 完全プライベート - データはすべて端末内に保存（クラウド送信なし）
- 📊 統計機能で日記の振り返りをサポート
- 🌐 オフライン対応

## 🚀 技術スタック

- **フレームワーク**: Flutter 3.x（FVM推奨）
- **ローカルDB**: Hive, hive_flutter
- **AI処理**: tflite_flutter（オンデバイス推論）
- **画像処理**: image_picker
- **パス管理**: path_provider
- **位置情報**: geolocator
- **テスト**: flutter_test, mocktail

※ 状態管理やimage_cropper等は現時点で未導入です。必要に応じて今後追加予定。

## 🛠 開発環境構築

### 前提条件

- Flutter SDK (最新安定版)
- Dart SDK (Flutterに同梱)
- Android Studio / Xcode (エミュレータ/実機デバッグ用)

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/your-username/smart_photo_diary.git
cd smart_photo_diary

# FVMを利用している場合（推奨）
fvm flutter pub get

# アプリを起動
fvm flutter run
```

## 🧪 テストの実行

```bash
# ユニットテストとウィジェットテスト
fvm flutter test

# カバレッジレポートの生成
fvm flutter test --coverage
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
