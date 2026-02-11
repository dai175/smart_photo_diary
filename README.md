# Smart Photo Diary

写真を選ぶだけでAIが自動的に日記を生成してくれる次世代の写真日記アプリです。フリーミアムモデルでBasic（無料）とPremium（有料）プランを提供し、高品質なAI日記生成とライティングプロンプト機能を搭載しています。

## 特徴

### 基本機能
- **AI日記生成**: Google Gemini 2.5 Flash APIを使用した高品質な日記の自動生成
- **タイムライン表示**: 日付別グルーピング（今日/昨日/月別）による写真タイムライン（スティッキーヘッダー対応）
- **多言語対応**: 日本語・英語の完全i18n対応（UI、AI生成、タグ全て）
- **SNSシェア**: X（Twitter）・Instagramへの日記シェア機能（画像生成対応）
- **完全プライベート**: データはすべて端末内に保存（プライバシーファースト設計）
- **統計・分析機能**: 日記の振り返りと使用パターン分析をサポート
- **過去の写真対応**: Premium会員限定で過去365日間の写真から日記作成可能
- **データ管理**: 日記データのエクスポート・インポート機能

### 収益化システム（フリーミアムモデル）
- **Basic（無料）**: 月10回のAI生成、基本プロンプト5種類
- **Premium（月額/年額）**: 月100回のAI生成、全20種類のプロンプト、高度な分析機能
  - ストアの地域・通貨に応じた動的価格対応（StoreKit 2）

### ライティングプロンプト機能
- **20種類の厳選プロンプト**: 9カテゴリ（感情、感覚、成長、つながり、発見、空想、癒し、エネルギー等）
- **スマート検索**: プロンプトテキスト、タグ、説明での全文検索対応
- **重み付きランダム選択**: 優先度に基づく自動プロンプト提案
- **使用量分析**: 包括的な分析システム（頻度、カテゴリ人気度、行動パターン、改善提案）

## アーキテクチャ

### 設計原則
- **依存性注入**: ServiceLocatorによる疎結合設計（2フェーズ初期化）
- **Result<T>パターン**: sealed classによる関数型エラーハンドリングで型安全性を確保
- **インターフェース指向**: テスタビリティを重視した設計（Iプレフィックス規約）
- **ChangeNotifier状態管理**: Provider/Riverpod等を使わないシンプルな状態管理
- **3層テスト戦略**: ユニット・ウィジェット・統合テスト（100%成功率維持）

### プロジェクト構成

```
lib/
├── core/           # コアアーキテクチャ（DI、Result<T>、例外階層）
├── services/       # サービス層（インターフェース指向）
├── models/         # データモデル（Hiveアダプター付き）
├── screens/        # 画面
├── controllers/    # 画面コントローラー（ChangeNotifier）
├── widgets/        # 再利用可能ウィジェット
├── ui/             # デザインシステム（MD3テーマ、共通コンポーネント）
├── constants/      # アプリ定数
├── utils/          # ユーティリティ
├── config/         # 環境・IAP設定
├── l10n/           # 国際化ARBファイル
└── localization/   # ロケール拡張・ユーティリティ
```

## 技術スタック

### Core Framework
- **Flutter 3.32.0**: FVM管理、日本語・英語ロケール対応
- **Dart 3**: Records、Patterns、sealed classesを活用

### データストレージ
- **Hive & hive_flutter**: 高速NoSQLローカルデータベース
- **SharedPreferences**: アプリ設定の永続化

### AI・API連携
- **Google Gemini 2.5 Flash**: 高品質なAI日記生成・タグ生成
- **Flutter Dotenv**: 環境変数管理

### UI/UX
- **Material Design 3**: モダンで統一されたデザインシステム
- **Google Fonts**: 高品質なタイポグラフィ（Noto Sans JP）
- **Photo Manager**: フォトライブラリアクセス
- **Flutter Sticky Header**: タイムラインのスティッキーヘッダー

### 収益化
- **In-App Purchase**: サブスクリプション管理（StoreKit 2対応）

### 開発・テスト
- **Build Runner & Hive Generator**: コード生成自動化
- **Mocktail**: モック化テストフレームワーク
- **GitHub Actions**: CI/CDパイプライン
- **Codecov**: テストカバレッジ追跡

## 開発環境構築

### 前提条件
- Flutter SDK (3.32.0)
- FVM (Flutter Version Management) - 推奨
- Xcode（iOSビルド用）
- Android Studio（Androidビルド用）
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

# 環境変数設定（プロジェクトルートに .env ファイル作成）
# GEMINI_API_KEY=your_api_key_here

# アプリを起動
fvm flutter run
```

## テスト・品質管理

### テスト実行
```bash
# 全テスト実行
fvm flutter test

# テストカテゴリ別実行
fvm flutter test test/unit/          # ユニットテスト
fvm flutter test test/widget/        # ウィジェットテスト
fvm flutter test test/integration/   # 統合テスト

# 詳細出力でテスト実行
fvm flutter test --reporter expanded

# カバレッジレポート生成
fvm flutter test --coverage
```

### コード品質
```bash
# 静的解析実行（エラー・警告0件維持）
fvm flutter analyze

# コードフォーマット
fvm dart format .
```

## CI/CD

### GitHub Actions ワークフロー
- **ci.yml**: コード品質・テスト自動実行（push + PR + 手動実行時）、Codecovカバレッジアップロード
- **release.yml**: GitHub Releases自動作成（バージョンタグ時）
- **ios-deploy.yml**: App Store/TestFlight手動デプロイ

## ビルド・デプロイ

```bash
# iOS
fvm flutter build ipa

# Android
fvm flutter build apk --release
fvm flutter build appbundle          # Google Play Store用

# デバッグ
fvm flutter run
fvm flutter run --dart-define=FORCE_PLAN=premium  # プラン強制指定
```

## プライバシー・セキュリティ

- **ローカルファースト**: 全ユーザーデータは端末内保存
- **API キー管理**: 環境変数による安全な管理（.envはプロジェクトルートに配置、gitignore済み）
- **権限管理**: 最小限の権限要求（写真アクセスのみ）

## ドキュメント

- **[CLAUDE.md](CLAUDE.md)** - AI開発アシスタント向けガイドライン
- **[docs/](docs/)** - 専門ドキュメント
  - [ci_cd_guide.md](docs/ci_cd_guide.md) - CI/CD詳細運用手順
  - [monetization_strategy.md](docs/monetization_strategy.md) - 収益化戦略
  - [sandbox_testing_guide.md](docs/sandbox_testing_guide.md) - サンドボックステスト手順
  - [prompt_categories.md](docs/prompt_categories.md) - プロンプトカテゴリ定義
