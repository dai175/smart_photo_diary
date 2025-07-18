# Smart Photo Diary CI/CD ガイド

## CI/CDパイプライン概要

Smart Photo DiaryのCI/CDシステムは、GitHub Actionsを基盤とした包括的な自動化パイプラインです。コード品質保証から本番デプロイまで、開発プロセス全体をカバーしています。

## ワークフロー構成

### 1. CI/CD Pipeline (`ci.yml`)
**目的**: 継続的インテグレーション・基本品質保証  
**トリガー**: main/developブランチpush、PR作成時、手動実行

```yaml
# 実行内容
✅ コード品質チェック（フォーマット、静的解析）
✅ 全テスト実行（100%成功率）
✅ カバレッジ生成・Codecovアップロード
✅ Android/iOSビルド検証
✅ アーティファクト保存（30日間）
✅ デプロイ準備状況確認
```

### 2. Android Deploy (`android-deploy.yml`)
**目的**: Google Play Store自動デプロイ  
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
# 実行内容
✅ 品質チェック・テスト実行
✅ 本番環境でのAABビルド
✅ Android署名・配布準備
✅ Google Play Console自動アップロード
✅ リリーストラック選択（internal/alpha/beta/production）
```

### 3. iOS Deploy (`ios-deploy.yml`)
**目的**: App Store/TestFlight自動デプロイ  
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
# 実行内容
✅ 品質チェック・テスト実行
✅ 本番環境でのIPAビルド
✅ iOS署名・配布準備
✅ TestFlight/App Store自動アップロード
✅ 環境選択（testflight/appstore）
```

### 4. Release (`release.yml`)
**目的**: GitHubリリース作成・アーティファクト配布  
**トリガー**: バージョンタグ(`v*`)push、手動実行

```yaml
# 実行内容
✅ 全プラットフォームビルド
✅ バージョン付きアーティファクト生成
✅ SHA256チェックサム生成
✅ 自動リリースノート作成
✅ GitHub Release作成・アップロード
```

## 技術仕様

### Flutter環境
```yaml
Flutter Version: 3.32.0
Dart Version: 3.8.0
Channel: stable
Java Version: 17 (Zulu distribution)
```

### プラットフォーム対応
```yaml
Ubuntu Latest: Android ビルド・デプロイ
macOS Latest: iOS ビルド・デプロイ
Multi-platform: Windows、Linux、Web（将来対応）
```

### 品質ゲート
```yaml
必須チェック項目:
- Flutter analyze: 0 issues
- テスト成功率: 100%
- コードフォーマット: dart format準拠
- ビルド成功: 全プラットフォーム
- セキュリティ: 環境変数・Secrets適切設定
```

## セットアップ・設定

### Phase 1: 基本CI/CD（設定不要）
現在利用可能な機能：

```bash
# 自動実行される内容
✅ PR作成時: 品質チェック・テスト
✅ mainブランチpush時: 完全ビルド検証
✅ アーティファクト生成: APK・AAB・iOS
✅ カバレッジレポート: Codecov統合
```

### Phase 2: ストアデプロイ設定
Google Play Store・App Store配布用の設定：

#### Android設定
```bash
# 必要なSecrets（GitHub Repository Settings）
ANDROID_SIGNING_KEY          # キーストアファイル（base64エンコード）
ANDROID_KEY_ALIAS           # キーエイリアス
ANDROID_KEYSTORE_PASSWORD   # キーストアパスワード
ANDROID_KEY_PASSWORD        # キーパスワード
GOOGLE_PLAY_SERVICE_ACCOUNT # サービスアカウントJSON
GEMINI_API_KEY              # Google Gemini API キー
```

#### iOS設定
```bash
# 必要なSecrets（GitHub Repository Settings）
IOS_DISTRIBUTION_CERTIFICATE # 配布証明書（.p12ファイル、base64エンコード）
IOS_CERTIFICATE_PASSWORD    # 証明書パスワード
IOS_PROVISIONING_PROFILE    # プロビジョニングプロファイル（base64エンコード）
IOS_KEYCHAIN_PASSWORD       # 一時的なキーチェーンパスワード
IOS_TEAM_ID                 # Apple Developer Team ID
APPLE_ID                    # Apple Developer アカウントメール
APPLE_APP_PASSWORD          # App専用パスワード
GEMINI_API_KEY              # Google Gemini API キー
```

### GitHub Environments設定（推奨）
```bash
# Repository Settings → Environments → Create "production"
- Required reviewers: 有効（デプロイ承認フロー）
- Deployment branches: mainブランチのみ許可
- Environment secrets: 本番用Secrets設定
```

## 使用方法・運用

### 日常開発フロー
```bash
# 1. 機能開発
git checkout -b feature/new-feature
# 開発・テスト作成...
git push origin feature/new-feature

# 2. プルリクエスト作成
# → ci.yml が自動実行
#   ✅ 品質チェック
#   ✅ テスト実行
#   ✅ ビルド検証

# 3. レビュー・マージ
git checkout main
git merge feature/new-feature
git push origin main

# → ci.yml が再度実行（mainブランチ用）
#   ✅ 完全ビルド検証
#   ✅ デプロイ準備確認
```

### リリースフロー
```bash
# 1. バージョン準備
# pubspec.yaml の version を更新
version: 1.2.0+3

# 2. バージョンタグ作成・プッシュ
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
```bash
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

### 各段階の目的
```yaml
Internal/TestFlight:
  目的: 開発チーム内での基本動作確認
  期間: 1-2日
  対象: 開発者・QAチーム

Alpha/Closed Testing:
  目的: 限定ユーザーでの機能検証
  期間: 3-5日
  対象: ベータテスター・パワーユーザー

Beta/Open Testing:
  目的: 広範囲での互換性・パフォーマンス確認
  期間: 1週間
  対象: 一般ベータテスター

Production/App Store:
  目的: 一般ユーザー向けリリース
  承認: Google（数時間）、Apple（1-2日）
  対象: 全ユーザー
```

## 監視・トラブルシューティング

### ワークフロー実行状況確認
```bash
# GitHub Repository
Actions タブ → 各ワークフロー選択
- 実行履歴・ログ確認
- 失敗時のエラー詳細
- アーティファクトダウンロード
```

### ステータスバッジ（README.md用）
```markdown
![CI/CD](https://github.com/dai175/smart_photo_diary/workflows/CI%2FCD%20Pipeline/badge.svg)
![Android](https://github.com/dai175/smart_photo_diary/workflows/Android%20Deploy/badge.svg)
![iOS](https://github.com/dai175/smart_photo_diary/workflows/iOS%20Deploy/badge.svg)
```

### よくある問題と解決

#### 1. ビルド失敗
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

#### 2. デプロイ失敗
```bash
問題: Android署名エラー
解決:
- ANDROID_SIGNING_KEY: base64エンコード確認
- キーストアパスワード確認
- 有効期限チェック

問題: iOS証明書エラー
解決:
- 配布証明書の有効性確認
- プロビジョニングプロファイル更新
- Team ID・Bundle ID確認
```

#### 3. 権限・アクセスエラー
```bash
問題: Google Play API access denied
解決:
- サービスアカウント権限確認
- Play Console設定確認
- API有効化確認

問題: App Store Connect access denied
解決:
- API Key権限確認
- App Store Connect設定確認
- Issuer ID・Key ID確認
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

# 環境変数テスト
echo "GEMINI_API_KEY=test_key" > .env
fvm flutter test
```

## パフォーマンス最適化

### ビルド時間短縮
```yaml
# Flutter キャッシュ活用
- uses: subosito/flutter-action@v2
  with:
    cache: true

# 並列実行の活用
- Android・iOS ビルドの並列実行
- テストカテゴリの並列実行
- 依存関係キャッシュの効率化
```

### リソース使用量最適化
```yaml
# タイムアウト設定
timeout-minutes: 30    # CI/CD
timeout-minutes: 45    # ビルド・デプロイ
timeout-minutes: 60    # iOS デプロイ

# アーティファクト管理
retention-days: 30     # 通常アーティファクト
retention-days: 90     # リリースアーティファクト
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

### コード署名
```bash
# Android
- Upload key と App signing key の分離
- Google Play App Signing 使用

# iOS
- Distribution Certificate 使用
- Automatic Provisioning 回避
- Manual Code Signing 設定
```

## 今後の拡張・改善

### 近期改善予定
```bash
- [ ] 通知システム統合（Slack・Discord）
- [ ] パフォーマンステスト自動化
- [ ] セキュリティスキャン統合
- [ ] E2Eテスト自動化
```

### 中長期拡張
```bash
- [ ] マルチプラットフォーム対応（Web・Desktop）
- [ ] 国際化対応（多言語ビルド）
- [ ] A/Bテスト基盤
- [ ] メトリクス収集・分析
```

## まとめ

Smart Photo DiaryのCI/CDシステムは、以下の特徴を持つ世界水準のパイプラインです：

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

このCI/CDシステムにより、高品質なモバイルアプリの継続的デリバリーが実現され、開発効率とリリース品質の両立が可能になります。