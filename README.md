# Smart Photo Diary

写真を選ぶだけでAIが自動的に日記を生成してくれる次世代の写真日記アプリです。フリーミアムモデルでBasic（無料）とPremium（有料）プランを提供し、高品質なAI日記生成とライティングプロンプト機能を搭載しています。

## ✨ 特徴

### 基本機能
- 📸 **AI日記生成**: Google Gemini APIを使用した高品質な日記の自動生成
- 🎨 **直感的なUI/UX**: Material Design 3準拠の美しいダークテーマ対応デザイン
- 🔒 **完全プライベート**: データはすべて端末内に保存（プライバシーファースト設計）
- 📊 **統計・分析機能**: 日記の振り返りと使用パターン分析をサポート
- 🌐 **オフライン対応**: ネットワーク接続なしでも基本機能が利用可能

### 収益化システム（フリーミアムモデル）
- **Basic（無料）**: 月10回のAI生成、基本プロンプト5種類
- **Premium（¥300/月、¥2,800/年）**: 月100回のAI生成、全20種類のプロンプト、高度な分析機能

### ライティングプロンプト機能
- 📝 **20種類の厳選プロンプト**: 8カテゴリ（日常、旅行、仕事、感謝、振り返り、創作、健康、人間関係）
- 🎯 **スマート検索**: プロンプトテキスト、タグ、説明での全文検索対応
- 🎲 **重み付きランダム選択**: 優先度に基づく自動プロンプト提案
- 📈 **使用量分析**: 4層の包括的な分析システム（頻度、カテゴリ人気度、行動パターン、改善提案）

## 🏗 アーキテクチャ

### サービス層パターン
- **依存性注入**: ServiceLocatorによる疎結合設計
- **Result<T>パターン**: 関数型エラーハンドリングで型安全性を確保
- **インターフェース指向**: テスタビリティを重視した設計
- **3層テスト戦略**: ユニット・ウィジェット・統合テスト（683テスト、100%成功率）

### 主要サービス
- `DiaryService`: 日記データ管理（Hive DB）
- `AiService`: Google Gemini API連携とオフラインフォールバック
- `SubscriptionService`: In-App Purchase統合とプラン管理
- `PromptService`: ライティングプロンプト管理と分析
- `PhotoService`: 写真アクセスと権限管理
- `SettingsService`: アプリ設定とテーマ管理

## 🚀 技術スタック

### Core Framework
- **Flutter 3.32.0**: FVM管理推奨、日本語ロケール対応
- **Dart 3**: Records、Patterns、sealed classesを活用

### データストレージ
- **Hive & hive_flutter**: 高速NoSQLローカルデータベース
- **SharedPreferences**: アプリ設定の永続化
- **File Picker**: ユーザー選択可能なエクスポート先

### AI・API連携
- **Google Gemini 2.5 Flash**: 高品質なAI日記生成
- **HTTP**: AI API通信
- **Connectivity Plus**: ネットワーク状態監視
- **Flutter Dotenv**: 環境変数管理

### UI/UX
- **Material Design 3**: モダンで統一されたデザインシステム
- **Google Fonts**: 高品質なタイポグラフィ
- **Table Calendar**: カレンダーベースの日記タイムライン
- **Photo Manager**: フォトライブラリアクセス

### 収益化・分析
- **In-App Purchase 3.1.10**: サブスクリプション管理（StoreKit 2互換性対応）
- **Usage Analytics**: 4層分析システム（Shannon Entropy、Gini係数、時系列分析）
- **Package Info Plus**: アプリバージョン管理

### 開発・テスト
- **Build Runner & Hive Generator**: コード生成自動化
- **Mocktail**: モック化テストフレームワーク
- **Flutter Lints**: コード品質管理
- **UUID**: ユニーク識別子生成
- **Intl**: 国際化対応

## 🛠 開発環境構築

### 前提条件
- Flutter SDK (3.8.0+)
- FVM (Flutter Version Management) - 推奨
- Android Studio / Xcode
- Google Gemini API キー

### セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/your-username/smart_photo_diary.git
cd smart_photo_diary

# FVMを利用している場合（推奨）
fvm flutter pub get

# コード生成実行
fvm dart run build_runner build

# 環境変数設定（.envファイル作成）
# GEMINI_API_KEY=your_api_key_here

# アプリを起動
fvm flutter run
```

## 🧪 テスト・品質管理

### テスト実行
```bash
# 全テスト実行（683テスト）
fvm flutter test

# テストカテゴリ別実行
fvm flutter test test/unit/          # ユニットテスト
fvm flutter test test/widget/        # ウィジェットテスト
fvm flutter test test/integration/   # 統合テスト

# 特定テストファイル実行
fvm flutter test test/unit/services/diary_service_mock_test.dart

# カバレッジレポート生成
fvm flutter test --coverage

# 詳細出力でテスト実行
fvm flutter test --reporter expanded
```

### コード品質
```bash
# 静的解析実行（エラー・警告0件維持）
fvm flutter analyze

# コードフォーマット
fvm dart format .

# 依存関係更新チェック
fvm flutter pub outdated
```

## 🔄 CI/CD・自動化

### GitHub Actions ワークフロー
- **ci.yml**: コード品質・テスト自動実行（プッシュ時）
- **release.yml**: GitHub Releases自動作成（バージョンタグ時）
- **android-deploy.yml**: Google Play Store自動デプロイ
- **ios-deploy.yml**: App Store/TestFlight自動デプロイ

```bash
# CI/CDトリガー例
git push origin main                    # ci.yml実行
git tag v1.0.0 && git push origin v1.0.0  # 全ワークフロー実行
```

### 必要なGitHub Secrets（本番用）
```
GEMINI_API_KEY              # Google Gemini API
GOOGLE_PLAY_SERVICE_ACCOUNT # Android デプロイ
APPSTORE_ISSUER_ID          # iOS デプロイ
ANDROID_SIGNING_KEY         # Android 署名
IOS_DISTRIBUTION_CERTIFICATE # iOS 署名
```

## 📦 ビルド・デプロイ

### 開発ビルド
```bash
# デバッグビルド
fvm flutter build apk --debug

# プラン強制指定（デバッグ限定）
fvm flutter run --dart-define=FORCE_PLAN=premium
```

### リリースビルド
```bash
# Android
fvm flutter build apk --release
fvm flutter build appbundle          # Google Play Store用

# iOS（Macのみ）
fvm flutter build ipa

# その他プラットフォーム
fvm flutter build macos
fvm flutter build windows
fvm flutter build linux
```

### インストール・起動
```bash
# Android実機インストール
adb install build/app/outputs/flutter-apk/app-release.apk

# アプリ起動
adb shell am start -n com.example.smart_photo_diary/.MainActivity
```

## 📊 開発状況

### 実装完了機能
- ✅ **コアアーキテクチャ**: Result<T>パターン、サービス層、依存性注入
- ✅ **収益化システム**: フリーミアムモデル、In-App Purchase統合
- ✅ **ライティングプロンプト**: 20プロンプト、8カテゴリ、高度検索
- ✅ **AI日記生成**: Google Gemini API、オフラインフォールバック
- ✅ **分析システム**: 4層包括分析（使用量、行動パターン、改善提案）
- ✅ **UI/UXシステム**: ダークテーマ、統一エラー表示、日本語フォント対応
- ✅ **データ管理**: エクスポート機能、データベース最適化
- ✅ **CI/CDパイプライン**: 4ワークフロー、自動テスト・ビルド・デプロイ

### テスト品質
- **683テスト**: 100%成功率維持
- **3層テスト戦略**: ユニット、ウィジェット、統合テスト
- **モック化対応**: 外部依存関係の完全分離
- **継続的品質管理**: 静的解析エラー0件
- **CI/CD統合**: GitHub Actionsによる自動テスト実行

### コード品質指標
- **静的解析**: エラー・警告0件（クリーンコードベース）
- **アーキテクチャ**: SOLID原則準拠、関数型プログラミング要素
- **ドキュメント**: 包括的CLAUDE.md、日本語コメント
- **保守性**: インターフェース指向、疎結合設計

## 🔐 プライバシー・セキュリティ

- **ローカルファースト**: 全ユーザーデータは端末内保存
- **API キー管理**: 環境変数による安全な管理
- **権限管理**: 最小限の権限要求（写真アクセスのみ）
- **暗号化**: Hiveデータベースによるローカル暗号化

## 🤝 コントリビューション

### 開発ガイドライン
- **新機能はResult<T>パターン必須**
- **全変更にテストコード必要**
- **静的解析エラー0件維持**
- **日本語UI、英語変数名規則**

プルリクエストは歓迎しています。大きな変更の場合は、最初にIssueを開いて議論してください。

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。