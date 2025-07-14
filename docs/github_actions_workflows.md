# GitHub Actions Workflows Guide

Smart Photo Diaryプロジェクト用のCI/CDワークフロー群の詳細ガイドです。

## 📋 ワークフロー一覧

### 1. CI/CD Pipeline (`ci.yml`)
**トリガー**: `main`, `develop`ブランチへのpush、PR作成
**目的**: コード品質チェック、テスト実行、ビルド検証

#### 実行内容
- ✅ コードフォーマットチェック
- ✅ 静的解析（flutter analyze）
- ✅ 全テスト実行（600+テスト）
- ✅ テストカバレッジ生成
- ✅ Android APK・AABビルド
- ✅ iOS ビルド（コード署名なし）
- ✅ ビルドアーティファクト保存（30日間）

### 2. Android Deploy (`android-deploy.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行
**目的**: Google Play Storeへの自動デプロイ

#### 実行内容
- ✅ テスト実行
- ✅ 本番環境でのAABビルド
- ✅ Android署名・配布
- ✅ Google Play Console アップロード
- ✅ リリーストラック選択（internal/alpha/beta/production）

#### 必要なSecrets
```
ANDROID_SIGNING_KEY          # キーストアファイル（base64）
ANDROID_KEY_ALIAS           # キーエイリアス
ANDROID_KEYSTORE_PASSWORD   # キーストアパスワード
ANDROID_KEY_PASSWORD        # キーパスワード
GOOGLE_PLAY_SERVICE_ACCOUNT # サービスアカウントJSON
GEMINI_API_KEY              # Google Gemini API キー
```

### 3. iOS Deploy (`ios-deploy.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行
**目的**: App Store/TestFlightへの自動デプロイ

#### 実行内容
- ✅ テスト実行
- ✅ 本番環境でのIPAビルド
- ✅ iOS署名・配布
- ✅ TestFlight/App Store アップロード
- ✅ 環境選択（testflight/appstore）

#### 必要なSecrets
```
IOS_DISTRIBUTION_CERTIFICATE # 配布証明書（.p12、base64）
IOS_CERTIFICATE_PASSWORD    # 証明書パスワード
IOS_PROVISIONING_PROFILE    # プロビジョニングプロファイル（base64）
IOS_KEYCHAIN_PASSWORD       # 一時的なキーチェーンパスワード
IOS_TEAM_ID                 # Apple Developer Team ID
APPLE_ID                    # Apple Developer アカウントメール
APPLE_APP_PASSWORD          # App専用パスワード
GEMINI_API_KEY              # Google Gemini API キー
```

### 4. Release (`release.yml`)
**トリガー**: バージョンタグ(`v*`)push、手動実行
**目的**: GitHubリリース作成とアーティファクト配布

#### 実行内容
- ✅ 全プラットフォームでのテスト実行
- ✅ リリースビルド（Android APK・AAB、iOS）
- ✅ バージョン付きアーティファクト生成
- ✅ SHA256チェックサム生成
- ✅ GitHubリリース作成
- ✅ アーティファクト自動アップロード

## 🚀 使用方法

### 1. 基本開発フロー
```bash
# 開発中は自動でci.ymlが実行される
git push origin feature/new-feature

# PRマージ時もci.ymlが実行される
git checkout main
git merge feature/new-feature
git push origin main
```

### 2. リリース作成
```bash
# バージョンタグをプッシュ
git tag v1.0.0
git push origin v1.0.0

# → 自動でrelease.ymlが実行される
# → GitHubリリースとアーティファクトが作成される
```

### 3. ストアデプロイ
```bash
# Androidデプロイ（手動実行）
# GitHub Actions画面でandroid-deploy.ymlを手動実行
# リリーストラックを選択: internal/alpha/beta/production

# iOSデプロイ（手動実行）
# GitHub Actions画面でios-deploy.ymlを手動実行
# 環境を選択: testflight/appstore
```

## ⚙️ セットアップ手順

### Phase 1: 基本CI/CD（今すぐ利用可能）
1. ✅ リポジトリにワークフローファイルをコミット
2. ✅ `ci.yml`が自動実行される（追加設定不要）

### Phase 2: ストアデプロイ準備
1. Google Play Console でアプリ登録
2. Apple Developer Program でアプリ登録
3. 必要なSecretsをGitHub リポジトリに設定
4. `android-deploy.yml`, `ios-deploy.yml`の利用開始

### Phase 3: 本格運用
1. GitHub Environments設定で承認フロー追加
2. Slack/Discord通知連携
3. 自動テスト拡張
4. パフォーマンス監視追加

## 🔐 セキュリティ設定

### GitHub Secrets設定場所
```
Repository Settings → Secrets and variables → Actions
```

### Environment設定（推奨）
```
Repository Settings → Environments → Create environment "production"
- Required reviewers: 有効
- Deployment branches: mainブランチのみ許可
```

## 📊 ワークフロー実行状況

### ステータスバッジ
```markdown
![CI/CD](https://github.com/dai175/smart_photo_diary/workflows/CI%2FCD%20Pipeline/badge.svg)
![Android Deploy](https://github.com/dai175/smart_photo_diary/workflows/Android%20Deploy/badge.svg)
![iOS Deploy](https://github.com/dai175/smart_photo_diary/workflows/iOS%20Deploy/badge.svg)
```

### 実行履歴確認
```
GitHub → Actions タブ → 各ワークフロー選択
```

## 🐛 トラブルシューティング

### よくある問題

1. **ビルド失敗**
   - `.env`ファイルの設定確認
   - 依存関係の更新（`flutter pub get`）
   - コード生成の実行（`dart run build_runner build`）

2. **テスト失敗**
   - ローカルでのテスト実行確認
   - モックデータの整合性確認
   - 環境固有の問題の調査

3. **デプロイ失敗**
   - Secrets設定の確認
   - 署名証明書の有効期限確認
   - ストア側の設定確認

### デバッグ方法
```bash
# ローカルで同等のコマンド実行
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

## 📈 今後の拡張予定

- [ ] 自動テスト拡張（E2Eテスト）
- [ ] パフォーマンステスト自動化
- [ ] セキュリティスキャン追加
- [ ] 通知システム統合
- [ ] メトリクス収集・監視