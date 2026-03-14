# Smart Photo Diary CI/CD ガイド

## CI/CDパイプライン概要

Smart Photo DiaryのCI/CDシステムは、GitHub Actionsを基盤とした自動化パイプラインです。

## ワークフロー構成

### 1. CI Pipeline (`ci.yml`)
**トリガー**: mainブランチpush、PR作成時、手動実行

```yaml
✅ コード品質チェック（フォーマット、静的解析）
✅ 全テスト実行（100%成功率）
✅ カバレッジ生成・ステップサマリー出力（閾値55%以上）
✅ Android/iOSビルド検証（mainブランチpush時のみ、Releaseビルド）
```

### 2. Release (`release.yml`)
**トリガー**: バージョンタグ(`v*`)push

```yaml
✅ CI通過の検証
✅ iOSリリースビルド（アーティファクト生成）
✅ SHA256チェックサム生成
✅ GitHub Release作成・アップロード
```

### 3. iOS Deploy (`ios-deploy.yml`)
**トリガー**: GitHub Release公開（`release published`イベント）

```yaml
✅ CI通過の検証
✅ 本番環境でのIPAビルド（署名・エクスポート込み）
✅ fastlane経由でTestFlight自動アップロード
```

## 技術仕様

- **Flutter Version**: `.fvmrc` で管理（setup-flutter Composite Actionが自動読み取り）
- **Dart Version**: 3.11.1
- **Java Version**: 17 (Zulu distribution)
- **Platform**: Ubuntu (Android), macOS (iOS)

## Composite Actions

### `.github/actions/setup-flutter/`
Flutter SDKセットアップ、依存関係キャッシュ、コード生成を一括実行。
Flutterバージョンは `.fvmrc` から自動取得。

### `.github/actions/setup-ios/`
iOS ビルド環境セットアップ。

### `.github/actions/verify-ci/`
CI パイプラインの通過検証。`set-deploy-sha` オプションで `DEPLOY_SHA` を環境変数に設定可能。

## 必要なSecrets設定

### iOS配布用
```bash
IOS_DISTRIBUTION_CERTIFICATE    # 配布証明書（.p12ファイル、base64エンコード）
IOS_CERTIFICATE_PASSWORD        # 証明書パスワード
IOS_PROVISIONING_PROFILE        # プロビジョニングプロファイル（base64エンコード）
IOS_KEYCHAIN_PASSWORD           # 一時的なキーチェーンパスワード
IOS_TEAM_ID                     # Apple Developer Team ID
APP_STORE_CONNECT_API_KEY_ID    # App Store Connect API キーID
APP_STORE_CONNECT_ISSUER_ID     # App Store Connect Issuer ID
APP_STORE_CONNECT_API_KEY       # App Store Connect API キー（.p8内容）
GEMINI_API_KEY                  # Google Gemini API キー
```

## スクリプト (`scripts/`)

### `testflight_build.sh`
ローカル環境でTestFlight用のIPAファイルをビルド。`.env` からAPIキーを読み込み、`--dart-define-from-file` でセキュアに渡す。ビルド完了後、Transporter.app または Xcode Organizer でのアップロード手順を表示。

### `prepare_xcode.sh`
Xcode Archive用のiOSビルド準備。APIキーを設定した状態で `flutter build ios` を実行し、その後Xcodeから手動でArchive・配布を行う。

### `dev_run.sh`
開発用の実行スクリプト。`pubspec.dev.yaml` を一時的にコピーして実行し、終了時に復元する。

## 使用方法・運用

### 日常開発フロー
```bash
# 1. 機能開発・プルリクエスト
git push origin feature/new-feature
# → ci.yml が自動実行（品質チェック・テストのみ）

# 2. レビュー・マージ
git checkout main && git merge feature/new-feature
git push origin main
# → ci.yml が再度実行（品質チェック・テスト + Android/iOSビルド検証）
```

### ローカライズQAチェック
```bash
# ローカライズ変更時に必ず実施する手順
fvm flutter gen-l10n      # ARB更新内容を反映
fvm flutter analyze       # 未使用キーや型不一致の検知
fvm flutter test          # ロケール切替テストを含む全体テスト
```

> **Tip**: ロケール切替の自動テストは `test/widget/locale_switch_widget_test.dart` をベースに主要画面へ拡張してください。

### リリースフロー
```bash
# 1. バージョンタグ作成・プッシュ
git tag v1.2.0
git push origin v1.2.0

# → 自動実行される内容:
#   ✅ release.yml: CI検証 → iOSビルド → GitHub Draft Release作成
#
# 2. Draft ReleaseをGitHubで確認・Publish
# → ios-deploy.yml が自動実行:
#   ✅ IPAビルド（署名・エクスポート込み） → TestFlightアップロード
```

## よくある問題と解決

### ビルド失敗
```bash
問題: Flutter setup failure
解決:
- .fvmrc のFlutterバージョン確認
- 依存関係の確認（pub get）
- コード生成の確認（build_runner）

問題: Test failures
解決:
- ローカルでテスト実行確認
- モック設定の検証
- 環境変数の確認（.env）
```

### デプロイ失敗
```bash
問題: Android署名エラー
解決:
- ANDROID_SIGNING_KEY: base64エンコード確認
- キーストアパスワード確認

問題: iOS証明書エラー
解決:
- 配布証明書の有効性確認
- プロビジョニングプロファイル更新
```

## パフォーマンス最適化

```yaml
# ビルド時間短縮設定
- Flutter SDKキャッシュ: cache: true（setup-flutter Composite Action）
- pub-cache キャッシュ
- build_runner キャッシュ
- Android・iOS ビルドの並列実行
- PRビルドではプラットフォームビルドをスキップ

# タイムアウト設定
timeout-minutes: 30    # CI/CD
timeout-minutes: 45    # ビルド・デプロイ
timeout-minutes: 60    # iOS デプロイ
```

## セキュリティ対策

### Secrets管理
```bash
# 原則
- 本番Secretsは暗号化保存
- 開発環境での本番Secrets使用禁止
- 定期的なキー・証明書ローテーション

# 実装
- GitHub Environments分離（production環境）
- 最小権限原則
- --dart-define-from-file による APIキーの安全な受け渡し
```

## 監視・デバッグ

### ワークフロー実行状況確認
```bash
# GitHub Repository
Actions タブ → 各ワークフロー選択
- 実行履歴・ログ確認
- 失敗時のエラー詳細
- アーティファクトダウンロード
```

### デバッグ用ローカル実行
```bash
# CI/CDワークフローと同等のチェック
fvm dart format --set-exit-if-changed .
fvm flutter analyze --fatal-infos --fatal-warnings
fvm flutter test --coverage --reporter expanded

# ビルド確認
fvm flutter build apk --release
fvm flutter build appbundle --release
```

## まとめ

Smart Photo DiaryのCI/CDシステムは、以下の特徴を持つ自動化パイプラインです：

- **完全自動化**: コミットからビルドまで
- **品質保証**: 100%テスト成功率維持
- **マルチプラットフォーム**: Android・iOS同時対応
- **セキュリティ**: 暗号化Secrets・環境分離
- **Composite Actions**: セットアップ・検証ロジックの再利用
- **TestFlightデプロイ**: GitHub Release作成からTestFlightアップロードまで自動化
