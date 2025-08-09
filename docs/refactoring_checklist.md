# リファクタリング チェックリスト

## 🔴 優先度：高（重要かつ緊急）

### 1. analyticsディレクトリ全体の削除
- [x] `lib/services/analytics/` ディレクトリのバックアップ作成
- [x] 依存関係の確認（他のファイルからのimport文を検索）
- [x] 以下のファイルを削除
  - [x] `category_popularity_reporter.dart` (515行)
  - [x] `improvement_suggestion_tracker.dart` (845行)
  - [x] `prompt_usage_analytics.dart` (619行)
  - [x] `user_behavior_analyzer.dart` (822行)
- [x] 削除後のビルド確認
- [x] テストの実行と成功確認

### 2. デバッグプリントの本番環境での除去（34ファイル）
#### コアサービス
- [x] `services/logging_service.dart` - kDebugMode条件追加
- [x] `services/subscription_service.dart` - LoggingServiceへ移行
- [x] `services/photo_service.dart` - LoggingServiceへ移行
- [x] `services/photo_cache_service.dart` - LoggingServiceへ移行
- [x] `services/photo_access_control_service.dart` - LoggingServiceへ移行
- [x] `services/ai/diary_generator.dart` - LoggingServiceへ移行
- [x] `services/ai/tag_generator.dart` - LoggingServiceへ移行
- [x] `services/ai/gemini_api_client.dart` - LoggingServiceへ移行

#### スクリーン
- [x] `screens/home_screen.dart` - print文を削除またはkDebugMode条件付き
- [x] `screens/diary_screen.dart` - print文を削除またはkDebugMode条件付き
- [x] `screens/diary_detail_screen.dart` - print文を削除またはkDebugMode条件付き
- [x] `screens/diary_preview_screen.dart` - print文を削除またはkDebugMode条件付き
- [x] `screens/settings_screen.dart` - print文を削除またはkDebugMode条件付き
- [x] `screens/statistics_screen.dart` - print文を削除またはkDebugMode条件付き

#### ウィジェット
- [ ] `widgets/home_content_widget.dart` - print文を削除
- [ ] `widgets/prompt_selection_modal.dart` - print文を削除
- [ ] `shared/filter_bottom_sheet.dart` - print文を削除

#### その他
- [ ] `main.dart` - 初期化ログの条件付き出力
- [ ] `config/environment_config.dart` - API keyログの削除
- [ ] `core/service_registration.dart` - 登録ログの条件付き
- [ ] `core/service_locator.dart` - デバッグログの条件付き
- [ ] `core/errors/error_handler.dart` - エラーログの適切な処理
- [ ] `models/diary_entry.dart` - デバッグ出力の削除
- [ ] `debug/font_debug_screen.dart` - デバッグ画面なので保持
- [ ] `utils/performance_monitor.dart` - パフォーマンスログの条件付き
- [ ] `utils/dialog_utils.dart` - ダイアログログの削除
- [ ] `utils/url_launcher_utils.dart` - URLログの削除
- [ ] `utils/upgrade_dialog_utils.dart` - アップグレードログの削除
- [ ] `ui/components/animated_button.dart` - アニメーションログの削除
- [ ] `ui/components/custom_dialog.dart` - ダイアログログの削除
- [ ] `ui/error_display/error_display_service.dart` - エラー表示ログの適切化
- [ ] `ui/error_display/error_display_widgets.dart` - ウィジェットログの削除

### 3. Result<T>パターンへの移行強化

#### DiaryService
- [ ] `saveDiaryEntry()` → `Future<Result<DiaryEntry>>`
- [ ] `updateDiaryEntry()` → `Future<Result<DiaryEntry>>`
- [ ] `deleteDiaryEntry()` → `Future<Result<void>>`
- [ ] `getDiaryEntries()` → `Future<Result<List<DiaryEntry>>>`
- [ ] `searchDiaries()` → `Future<Result<List<DiaryEntry>>>`
- [ ] `exportDiaries()` → `Future<Result<String>>`
- [ ] `importDiaries()` → `Future<Result<ImportResult>>`
- [ ] エラーハンドリングのAppException統一
- [ ] 呼び出し元での.fold()処理実装

#### PhotoService
- [ ] `requestPermission()` → `Future<Result<bool>>`
- [ ] `getTodayPhotos()` → `Future<Result<List<AssetEntity>>>`
- [ ] `getPastPhotos()` → `Future<Result<List<AssetEntity>>>`
- [ ] `getPhotoThumbnail()` → `Future<Result<Uint8List?>>`
- [ ] `getPhotoData()` → `Future<Result<Uint8List?>>`
- [ ] `handleLimitedPhotoAccess()` → `Future<Result<void>>`
- [ ] PhotoAccessException使用の統一
- [ ] 呼び出し元でのエラー処理改善

#### AiService
- [ ] 既存のResult<DiaryGenerationResult>の活用確認
- [ ] `generateTags()` → `Future<Result<List<String>>>`
- [ ] `isOnline()` → `Future<Result<bool>>`
- [ ] AiProcessingExceptionの一貫した使用
- [ ] クレジット消費タイミングの保証強化

## 🟠 優先度：中（重要だが急がない）

### 4. SubscriptionService（2,032行）のリファクタリング

#### ファイル分割計画
- [ ] `subscription_purchase_manager.dart` の作成
  - [ ] 購入関連メソッドの移動
  - [ ] リストア処理の移動
  - [ ] 購入検証ロジックの移動
- [ ] `subscription_status_manager.dart` の作成
  - [ ] ステータス管理メソッドの移動
  - [ ] プラン判定ロジックの移動
  - [ ] 有効期限管理の移動
- [ ] `subscription_usage_tracker.dart` の作成
  - [ ] AI使用量カウントの移動
  - [ ] 月次リセットロジックの移動
  - [ ] 使用制限チェックの移動
- [ ] `subscription_service.dart` をファサードパターンに変更
- [ ] インターフェースの更新と整合性確認
- [ ] テストの分割と更新

### 5. StatefulWidgetの状態管理改善（20ファイル）

#### 状態管理ライブラリ導入検討
- [ ] Riverpod vs Provider vs Bloc の比較検討
- [ ] 段階的移行計画の策定

#### 移行対象Widget（優先順位順）
- [ ] `home_screen.dart` - メイン画面の状態管理
- [ ] `diary_preview_screen.dart` - プレビュー状態管理
- [ ] `diary_screen.dart` - 日記一覧の状態管理
- [ ] `settings_screen.dart` - 設定画面の状態管理
- [ ] `diary_detail_screen.dart` - 詳細画面の状態管理
- [ ] `statistics_screen.dart` - 統計画面の状態管理
- [ ] `home_content_widget.dart` - ホームコンテンツ状態
- [ ] `optimized_photo_grid_widget.dart` - 写真グリッド状態
- [ ] `past_photo_calendar_widget.dart` - カレンダー状態
- [ ] `prompt_selection_modal.dart` - プロンプト選択状態
- [ ] `filter_bottom_sheet.dart` - フィルター状態
- [ ] `animated_button.dart` - アニメーション状態
- [ ] `modern_chip.dart` - チップ選択状態
- [ ] `loading_shimmer.dart` - ローディング状態
- [ ] `gradient_app_bar.dart` - アプリバー状態
- [ ] `custom_card.dart` - カード状態
- [ ] `micro_interactions.dart` - インタラクション状態
- [ ] `list_animations.dart` - リストアニメーション状態
- [ ] `main.dart` - アプリ全体の状態
- [ ] `font_debug_screen.dart` - デバッグ画面（低優先度）

### 6. AlertDialog → CustomDialogへの完全移行

#### 移行対象ファイル
- [ ] `screens/home_screen.dart` のAlertDialog検索と置換
- [ ] `screens/diary_screen.dart` のAlertDialog検索と置換
- [ ] `screens/diary_detail_screen.dart` のAlertDialog検索と置換
- [ ] `screens/diary_preview_screen.dart` のAlertDialog検索と置換
- [ ] `screens/settings_screen.dart` のAlertDialog検索と置換
- [ ] `screens/statistics_screen.dart` のAlertDialog検索と置換
- [ ] `widgets/home_content_widget.dart` のAlertDialog検索と置換
- [ ] `utils/dialog_utils.dart` のshowDialog実装確認
- [ ] `utils/upgrade_dialog_utils.dart` のダイアログ統一
- [ ] `utils/url_launcher_utils.dart` のエラーダイアログ統一
- [ ] `ui/error_display/error_display_widgets.dart` の統一
- [ ] `ui/error_display/error_display_service.dart` の統一
- [ ] `core/result/result_ui_extensions.dart` の統一

## 🟡 優先度：低（時間があれば対応）

### 7. Color定義の一元化（55箇所）

#### 対象ファイル
- [ ] `debug/font_debug_screen.dart` - 5箇所
- [ ] `widgets/photo_grid_widget.dart` - 18箇所
- [ ] `widgets/prompt_selection_modal.dart` - 3箇所
- [ ] `widgets/optimized_photo_grid_widget.dart` - 12箇所
- [ ] `widgets/home_content_widget.dart` - 1箇所
- [ ] `widgets/diary_card_widget.dart` - 3箇所
- [ ] `main.dart` - 2箇所
- [ ] `screens/diary_detail_screen.dart` - 6箇所
- [ ] `screens/home_screen.dart` - 3箇所
- [ ] `shared/filter_bottom_sheet.dart` - 2箇所

#### 実装タスク
- [ ] AppColorsに不足している色定義の追加
- [ ] 各ファイルでのColor直接指定をAppColors参照に変更
- [ ] テーマとの整合性確認

### 8. シングルトンパターンの統一

#### ServiceLocator移行対象
- [ ] `DiaryService.getInstance()` → ServiceLocator登録
- [ ] `PhotoService.getInstance()` → ServiceLocator登録
- [ ] `LoggingService.getInstance()` → ServiceLocator登録
- [ ] `StorageService` → ServiceLocator登録確認
- [ ] `SettingsService` → ServiceLocator登録確認
- [ ] 各サービスの初期化順序の整理
- [ ] 依存関係グラフの文書化

### 9. 過去の写真機能のテスト強化

#### テスト作成対象
- [ ] `PastPhotosNotifier` のユニットテスト
- [ ] `past_photos_state.dart` のモデルテスト
- [ ] `UnifiedPhotoController` の統合テスト
- [ ] `past_photo_calendar_widget.dart` のウィジェットテスト
- [ ] プラン別アクセス制限のテスト
- [ ] 日付範囲制限（365日）のテスト
- [ ] Premium/Basic切り替え時の動作テスト

### 10. build.gradle.ktsのTODOコメント対応

#### Android設定
- [ ] Application IDの本番用ID設定
- [ ] 署名設定の実装
  - [ ] キーストアファイルの作成
  - [ ] release用署名設定の追加
  - [ ] GitHub Secretsへの登録
- [ ] ProGuard/R8設定の最適化
- [ ] バージョニング戦略の文書化

## 完了後の確認項目

### テスト実行
- [ ] `fvm flutter test` - 全テストが成功（800+テスト）
- [ ] `fvm flutter analyze` - 警告・エラーなし
- [ ] `fvm dart format --set-exit-if-changed .` - フォーマット済み

### ビルド確認
- [ ] Debug APKビルド成功
- [ ] Release APKビルド成功
- [ ] iOS Debug ビルド成功
- [ ] iOS Release ビルド成功

### 動作確認
- [ ] 基本的な日記作成フロー
- [ ] 写真選択と権限処理
- [ ] AI生成機能
- [ ] サブスクリプション機能
- [ ] エラーハンドリング
- [ ] オフライン動作

## メトリクス目標

- コードベースサイズ: 3,800行以上削減（analytics削除）
- デバッグ出力: 本番環境で0件
- Result<T>採用率: 主要サービスの80%以上
- テスト成功率: 100%維持
- ビルド警告: 0件