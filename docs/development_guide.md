# 開発ガイド

## 環境構築

### 必要なツール
- Flutter SDK（最新安定版）
- Dart SDK（Flutterに同梱）
- Android Studio または Xcode（エミュレータ/実機デバッグ用）

### セットアップ手順

```bash
# リポジトリをクローン
git clone https://github.com/your-username/smart_photo_diary.git
cd smart_photo_diary

# FVMを利用している場合（推奨）
fvm flutter pub get

# アプリを起動
fvm flutter run
```


## コーディング規約
- クラス名・ウィジェット名: PascalCase（例: `PhotoPicker`）
- 変数・関数: camelCase
- 定数: UPPER_SNAKE_CASE
- ファイル名: snake_case（例: `photo_picker.dart`）
- ドキュメントコメント（///）を積極的に記述
- 型安全なDartコードを推奨

## テストの実行

```bash
# すべてのテストを実行
fvm flutter test

# 特定のテストファイルを実行
fvm flutter test test/features/photo_picker/photo_picker_test.dart

# カバレッジレポートを生成
fvm flutter test --coverage
# coverageパッケージを利用する場合（必要に応じて）
fvm flutter pub run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.packages --report-on=lib

# 統合テスト (エミュレータ/実機が必要)
fvm flutter test integration_test/app_test.dart
```

## コード生成

```bash
# モデルクラスを生成 (freezed)
fvm flutter pub run build_runner build

# 変更を監視して自動生成
fvm flutter pub run build_runner watch

# 競合するファイルを削除して再生成
fvm flutter pub run build_runner build --delete-conflicting-outputs
```

## コミットメッセージ

フォーマット: `type(scope): メッセージ`

例:
- `feat(photo_picker): 複数選択機能を追加`
- `fix(diary): 生成テキストの改行を修正`
- `refactor: ウィジェットをリファクタリング`
- `test(photo_picker): 選択ロジックのテストを追加`
- `docs: READMEを更新`

## プルリクエストの手順

1. 機能ブランチを作成 (`git checkout -b feature/xxx`)
2. 変更をコミット (上記のフォーマットで)
3. リモートリポジトリにプッシュ (`git push origin feature/xxx`)
4. GitHubでプルリクエストを作成
5. CIが通ることを確認
6. コードレビューを受ける
7. マージ

## リリース手順

```bash
# ビルド番号を更新 (pubspec.yaml)
# 変更履歴を更新 (CHANGELOG.md)
# バージョンタグを付与
git tag v1.0.0
git push origin v1.0.0

# ビルド
fvm flutter build apk --release  # Android
fvm flutter build ipa            # iOS (Macのみ)
```
