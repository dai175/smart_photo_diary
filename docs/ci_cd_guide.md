# Smart Photo Diary CI/CD ガイド

## CI/CDパイプライン概要

Smart Photo DiaryのCI/CDシステムは、GitHub Actionsを基盤とした自動化パイプラインです。

## ワークフロー構成

### 1. CI Pipeline (`ci.yml`)
**トリガー**: main/developブランチpush、PR作成時、手動実行

```yaml
✅ コード品質チェック（フォーマット、静的解析）
✅ 全テスト実行（100%成功率）
✅ カバレッジ生成・Codecovアップロード
✅ Android/iOSビルド検証
✅ アーティファクト保存（30日間）
```

### 2. Release (`release.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
✅ 全プラットフォームビルド
✅ バージョン付きアーティファクト生成
✅ SHA256チェックサム生成
✅ GitHub Release作成・アップロード
```

### 3. Android Deploy (`android-deploy.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
✅ 品質チェック・テスト実行
✅ 本番環境でのAABビルド
✅ Google Play Console自動アップロード
✅ リリーストラック選択（internal/alpha/beta/production）
```

### 4. iOS Deploy (`ios-deploy.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
✅ 品質チェック・テスト実行
✅ 本番環境でのIPAビルド
✅ TestFlight/App Store自動アップロード
✅ 環境選択（testflight/appstore）
```

## 技術仕様

- **Flutter Version**: 3.32.0
- **Dart Version**: 3.8.0
- **Java Version**: 17 (Zulu distribution)
- **Platform**: Ubuntu (Android), macOS (iOS)

## 必要なSecrets設定

### Android配布用
```bash
ANDROID_SIGNING_KEY          # キーストアファイル（base64エンコード）
ANDROID_KEY_ALIAS           # キーエイリアス
ANDROID_KEYSTORE_PASSWORD   # キーストアパスワード
ANDROID_KEY_PASSWORD        # キーパスワード
GOOGLE_PLAY_SERVICE_ACCOUNT # サービスアカウントJSON
GEMINI_API_KEY              # Google Gemini API キー
```

### iOS配布用
```bash
IOS_DISTRIBUTION_CERTIFICATE # 配布証明書（.p12ファイル、base64エンコード）
IOS_CERTIFICATE_PASSWORD    # 証明書パスワード
IOS_PROVISIONING_PROFILE    # プロビジョニングプロファイル（base64エンコード）
IOS_KEYCHAIN_PASSWORD       # 一時的なキーチェーンパスワード
IOS_TEAM_ID                 # Apple Developer Team ID
APPLE_ID                    # Apple Developer アカウントメール
APPLE_APP_PASSWORD          # App専用パスワード
GEMINI_API_KEY              # Google Gemini API キー
```

## 使用方法・運用

### 日常開発フロー
```bash
# 1. 機能開発・プルリクエスト
git push origin feature/new-feature
# → ci.yml が自動実行（品質チェック・テスト・ビルド検証）

# 2. レビュー・マージ
git checkout main && git merge feature/new-feature
git push origin main
# → ci.yml が再度実行（mainブランチ用完全ビルド検証）
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
#   ✅ release.yml: GitHub Release作成
#   ✅ android-deploy.yml: Play Store（手動実行可）
#   ✅ ios-deploy.yml: App Store（手動実行可）
```

### 手動デプロイ実行
```bash
# GitHub Actions画面での手動実行
1. Actions タブ → Android Deploy 選択
2. "Run workflow" → リリーストラック選択
   - internal: 内部テスト
   - alpha: クローズドテスト
   - beta: オープンテスト
   - production: 本番リリース

3. Actions タブ → iOS Deploy 選択
4. "Run workflow" → 環境選択
   - testflight: TestFlight配布
   - appstore: App Store提出
```

## 段階的デプロイ戦略

### 推奨リリースフロー
```
1. 開発・テスト
   ↓
2. GitHub Release（v1.2.0タグ）
   ↓
3. 内部テスト（Android: internal、iOS: TestFlight）
   ↓
4. クローズドテスト（Android: alpha）
   ↓
5. オープンテスト（Android: beta）
   ↓
6. 本番リリース（Android: production、iOS: App Store）
```

## よくある問題と解決

### ビルド失敗
```bash
問題: Flutter setup failure
解決: 
- Flutterバージョン確認（3.32.0）
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
- Flutter キャッシュ活用: cache: true
- Android・iOS ビルドの並列実行
- 依存関係キャッシュの効率化

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
- GitHub Environments分離
- 最小権限原則
- アクセスログ監視
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

### ✅ 現在利用可能
- **完全自動化**: コミットからビルドまで
- **品質保証**: 100%テスト成功率維持
- **マルチプラットフォーム**: Android・iOS同時対応
- **セキュリティ**: 暗号化Secrets・環境分離

### 🚀 ストア準備後利用可能
- **自動デプロイ**: Google Play・App Store
- **段階的リリース**: 内部→α→β→本番
- **ワンクリック配布**: 手動トリガー対応
- **監視・通知**: 失敗時の自動通知

---

**更新**: 2024年12月現在  
**対象バージョン**: Smart Photo Diary v1.0以降
