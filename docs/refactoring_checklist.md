# Smart Photo Diary リファクタリングチェックリスト

このドキュメントは、Smart Photo Diaryプロジェクトのリファクタリング作業を体系的に実行するためのチェックリストです。

## 概要

- **作成日**: 2025-08-16
- **対象ブランチ**: `feature/cleanup`
- **推定作業時間**: 40-60時間
- **テストカバレッジ維持**: 100%必須

---

## 最優先 (緊急) 🔥

### 1. Result<T>パターンの全面移行

**概要**: エラーハンドリングの統一による安定性向上

**現状分析**:
- ✅ SettingsService: 実装済み
- ✅ SubscriptionService: 実装済み  
- ✅ AiService: 実装済み
- ✅ DiaryService: 実装完了
- ❌ PhotoService: 未実装
- ❌ StorageService: 部分実装

**作業項目**:

#### DiaryService移行
- [x] IDiaryServiceにResult<T>メソッド追加
- [x] getAllDiaries()をResult<List<DiaryEntry>>に変更
- [x] saveDiary()をResult<DiaryEntry>に変更
- [x] deleteDiary()をResult<void>に変更
- [x] updateDiary()をResult<DiaryEntry>に変更
- [x] searchDiaries()をResult<List<DiaryEntry>>に変更
- [x] 呼び出し元の更新（DiaryScreenController、統計画面等）
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/diary_service_*`

#### PhotoService移行
- [x] IPhotoServiceにResult<T>メソッド追加
- [x] getPhotos()をResult<List<AssetEntity>>に変更
- [x] requestPermission()をResult<PermissionState>に変更
- [x] loadMorePhotos()をResult<List<AssetEntity>>に変更
- [x] 写真関連Controllerの更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/photo_service_*`

#### StorageService移行
- [x] IStorageServiceの作成
- [x] exportData()をResult<String?>に変更
- [x] getStorageInfo()をResult<StorageInfo>に変更
- [x] optimizeDatabase()をResult<bool>に変更
- [x] 呼び出し元の更新（settings_screen.dart）
- [x] ServiceLocator登録の更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/storage_service_test.dart`

**完了条件**:
- [x] 全テストが緑（800+テスト100%成功維持） ✅ **達成済み**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**
- [ ] 例外ベースのエラーハンドリングが全て除去 🔄 **進行中（Result<T>移行完了）**
- [ ] 132箇所のthrow/Exception使用箇所を50箇所以下に削減 📊 **現状178箇所→目標継続**

---

### 2. Deprecated API(@Deprecated)の除去

**場所**: `lib/services/settings_service.dart:158`

**作業項目**:
- [x] `getPlanPeriodInfo()`メソッドの削除
- [x] 呼び出し元の調査: `grep -r "getPlanPeriodInfo(" lib/`
- [x] 全ての呼び出し元を`getPlanPeriodInfoV2()`に更新
- [x] 関連テストケースの更新
- [x] 実装完了後のテスト実行: `fvm flutter test test/unit/services/settings_service_*`

**完了条件**:
- [x] @Deprecated アノテーションが完全除去 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**

---

## 高優先度 ⚡

### 3. サービス初期化パターンの統一

**現状**:
- ✅ 全サービスがServiceLocator経由でアクセス可能
- ✅ 依存関係が明確化され、循環依存が排除
- ✅ 初期化順序が最適化

**作業項目**:

#### ServiceLocator統一パターンへの移行
- [x] `lib/core/service_registration.dart`の現状分析
- [x] 全サービスのServiceLocator登録パターン統一
- [x] DiaryServiceのgetInstance()パターンを段階的廃止
- [x] SettingsServiceの初期化パターン統一
- [x] 各サービスのファクトリメソッド標準化

#### 依存関係の明確化
- [x] サービス間依存関係のドキュメント化
- [x] 循環依存の排除
- [x] 初期化順序の最適化

**完了条件**:
- [x] 全サービスがServiceLocator経由でアクセス可能 ✅ **達成済み**
- [x] 初期化パターンが統一 ✅ **達成済み**
- [x] テストでのモック化が容易 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み**

---

### 4. TODOコメントの解決

**調査結果**:
- ✅ libディレクトリ内: TODOコメントなし
- ✅ android/app/build.gradle.kts: 2箇所のTODOを解決済み

**作業項目**:
- [x] `grep -r "TODO\|FIXME\|HACK" lib/`で全TODO箇所を特定
- [x] 各TODOの内容分析と優先度付け
- [x] 実装可能なTODOの解決
- [x] 不要なTODOの削除
- [x] android/app/build.gradle.kts の説明コメント改善

**完了条件**:
- [x] プロジェクトコード内のTODOコメントが0個 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**

---

## 中優先度 📝

### 5. インターフェース命名規則の統一

**現状統一済み**: ✅ **完了**
- `IStorageService` (Iプレフィックス)
- `IPhotoService` (Iプレフィックス)
- `IPhotoCacheService` (Iプレフィックス)
- `IDiaryService` (Iプレフィックス)
- `IPhotoAccessControlService` (Iプレフィックス)
- `IAiService` (Iプレフィックス)

**作業項目**:

#### 命名規則の決定
- [x] プロジェクト標準命名規則の決定（採用: I*プレフィックス）
- [x] アーキテクチャドキュメントの更新

#### インターフェースリネーム
- [x] `StorageServiceInterface` → `IStorageService`
- [x] `PhotoServiceInterface` → `IPhotoService`
- [x] `PhotoCacheServiceInterface` → `IPhotoCacheService`
- [x] `DiaryServiceInterface` → `IDiaryService`
- [x] `PhotoAccessControlServiceInterface` → `IPhotoAccessControlService`
- [x] `AiServiceInterface` → `IAiService`
- [x] 全ての実装クラスの更新（39ファイルで133箇所）
- [x] インポート文の更新
- [x] 関連テストの更新

**完了条件**:
- [x] 命名規則が完全統一 ✅ **達成済み**
- [x] 全テストが成功 ✅ **達成済み（800+テスト100%成功）**
- [x] `fvm flutter analyze`でエラーなし ✅ **達成済み**

---

### 6. ログ出力の統一化

**概要**: LoggingServiceを使用した統一的なログ出力パターンの確立

**現状分析**:
- debugPrint使用: 121箇所（主にサービス層に集中）
- print使用: 2箇所
- LoggingService使用: 既に一部で利用中（widgets/home_content_widget.dartなど）
- ログレベルやフォーマットが不統一
- エラーハンドリング時のログ出力パターンが不統一

**段階的移行計画（3フェーズ）**:

#### フェーズ1: 高優先度サービス層（1-2週間）
**対象**: APIクライアントと重要なビジネスロジック
- [x] subscription_service.dart（44箇所のdebugPrint）
- [x] ai/diary_generator.dart（18箇所のdebugPrint）
- [x] ai/gemini_api_client.dart（21箇所のdebugPrint）
- [x] ai/tag_generator.dart（3箇所のdebugPrint）✅ **完了** - ServiceLocator経由LoggingService統合
- [x] エラーハンドリングの統一（error/warning/info レベル分類）✅ **完了**
- [x] コンテキスト情報の追加 ✅ **完了**
- [x] debugPrint完全除去・適切なimport整理 ✅ **完了**

#### フェーズ2: 設定・初期化層（1週間）
**対象**: アプリケーション設定と初期化関連
- [x] config/environment_config.dart（16箇所のdebugPrint）
- [x] core/service_registration.dart（8箇所のdebugPrint）
- [x] main.dart（5箇所のdebugPrint）
- [x] core/service_locator.dart（8箇所のdebugPrint）
- [x] 初期化関連ログの統一
- [x] 設定関連エラーのログレベル分類 ✅ **完了** - 画面ファイル群の統一化で対応済み
- [x] 起動時のログフローの最適化 ✅ **完了** - ServiceRegistration統一化済み

#### フェーズ3: UI・その他（1週間） ✅ **完了**
**対象**: ユーザーインターフェースと残りのコンポーネント
- [x] 画面ファイル群（17箇所のdebugPrint）✅ **完了** - ServiceLocator経由LoggingService統合、テスト修正含む
- [x] 写真関連サービス（6箇所のdebugPrint）✅ **完了**
- [x] ウィジェット・UI関連（27箇所のdebugPrint）✅ **完了** - 全体的なテスト・検証まで完了
- [x] ユーザー操作関連ログの整理 ✅ **完了**
- [x] UIエラーの適切なログレベル設定 ✅ **完了**
- [x] デバッグ専用ログの識別・整理 ✅ **完了**

#### ログ標準化ルール

**ログレベル分類ガイドライン**:
- `error`: 例外、API失敗、設定読み込みエラー、初期化失敗
- `warning`: 設定不備、非推奨機能使用、リトライ可能なエラー
- `info`: サービス初期化完了、重要な状態変更、成功した操作
- `debug`: 内部処理開始、詳細なトレース情報、早期リターン

**コンテキスト命名規則**:
- **クラスメソッド**: `クラス名.メソッド名` (例: `ServiceRegistration.initialize`)
- **トップレベル関数**: `ファイル名` または `関数名` (例: `main`)
- **インスタンスメソッド**: `サービス名.メソッド名` (例: `SubscriptionService.initializeStatus`)

**実装パターン**:
- **ServiceLocatorアクセス**: `static LoggingService get _logger => serviceLocator.get<LoggingService>();`
- **循環参照回避**: ServiceLocatorなど基盤システムではdebugPrint完全除去
- **データ付きログ**: `logger.info('メッセージ', context: 'Context', data: '追加情報')`

#### 全体的なテスト・検証
- [x] 各フェーズ完了後のテスト実行
- [x] ログ出力の動作確認
- [x] パフォーマンス影響の検証
- [x] 本番・デバッグビルドでのログレベル動作確認

**完了条件**:
- [x] print/debugPrint使用箇所が0個（LoggingServiceに統一）
- [x] 統一されたログフォーマットの適用
- [x] 各フェーズでのテスト成功（800+テストの100%成功維持）
- [x] `fvm flutter analyze`でエラーなし
- [x] 構造化されたログによるデバッグ効率向上の確認

---

### 7. 状態管理パターンの最適化

**現状**: 6つのControllerで24箇所のsetState/notifyListeners

**作業項目**:

#### 現状分析
- [ ] 各Controllerの責務分析
- [ ] 状態管理の重複箇所特定
- [ ] パフォーマンスボトルネック調査

#### 最適化実装
- [ ] 重複状態の統合
- [ ] リアクティブ性の向上
- [ ] Riverpod/Provider移行の検討（オプション）
- [ ] 状態更新の最適化

**完了条件**:
- [ ] setState/notifyListeners使用箇所が20個以下
- [ ] パフォーマンス改善が確認される
- [ ] 全テストが成功

---

## 低優先度（長期課題） 📋

### 8. 写真ウィジェットの統合

**対象ウィジェット**:
- OptimizedPhotoGridWidget
- PhotoGridWidget  
- PastPhotoCalendarWidget

**作業項目**:
- [ ] 各ウィジェットの機能分析
- [ ] 共通部分の抽出
- [ ] 統合ウィジェット設計
- [ ] 段階的統合実装
- [ ] パフォーマンステスト

**完了条件**:
- [ ] 重複コードが50%以上削減
- [ ] 機能性が維持される
- [ ] パフォーマンスが改善

---

### 9. UIコンポーネント設計システム強化

**作業項目**:
- [ ] 現在の設計システム分析
- [ ] コンポーネントライブラリの拡張
- [ ] デザイントークンの標準化
- [ ] ドキュメント化

**完了条件**:
- [ ] 設計システムが完全ドキュメント化
- [ ] 新規コンポーネントの追加が容易

---

## 作業実行ガイドライン

### 前提条件
- [ ] 現在のブランチ: `feature/cleanup`
- [ ] 全テスト成功確認: `fvm flutter test`
- [ ] 静的解析クリア: `fvm flutter analyze`
- [ ] フォーマット適用: `fvm dart format .`

### 各段階での必須チェック
- [ ] テスト実行: `fvm flutter test`
- [ ] 静的解析: `fvm flutter analyze`  
- [ ] フォーマット: `fvm dart format .`
- [ ] 機能動作確認
- [ ] パフォーマンステスト

### 完了条件
- [ ] 全800+テストが成功（100%維持）
- [ ] 静的解析エラーゼロ
- [ ] コードフォーマット準拠
- [ ] 機能回帰なし
- [ ] パフォーマンス改善または維持

---

## 進捗追跡

### 週次目標
- **Week 1**: Result<T>移行（DiaryService） ✅ **完了**
- **Week 2**: Result<T>移行（PhotoService、StorageService） ✅ **完了**
- **Week 3**: ServiceLocator統一、Deprecated API除去 ✅ **完了**
- **Week 4**: TODO解決、命名規則統一 ✅ **完了**
- **Week 5**: ログ出力統一化（フェーズ2完了、フェーズ3画面ファイル群完了） 🔄 **進行中**
- **Week 6**: 状態管理最適化
- **Week 7-8**: 低優先度項目（オプション）

### 完了チェック
- [ ] 全最優先項目完了
- [ ] 全高優先度項目完了
- [ ] 中優先度項目50%以上完了
- [ ] ドキュメント更新
- [ ] チームレビュー完了
- [ ] リリース準備完了

---

**最終更新**: 2025-08-19 (Week 5: ウィジェット・UI関連のログ出力統一化完了)  
**レビュー者**: [担当者名]  
**承認日**: [承認日]