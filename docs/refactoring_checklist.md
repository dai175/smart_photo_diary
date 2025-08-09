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
- [x] `widgets/home_content_widget.dart` - print文を削除
- [x] `widgets/prompt_selection_modal.dart` - print文を削除
- [x] `shared/filter_bottom_sheet.dart` - print文を削除

#### その他
- [x] `main.dart` - 初期化ログの条件付き出力
- [x] `config/environment_config.dart` - API keyログの削除
- [x] `core/service_registration.dart` - 登録ログの条件付き
- [x] `core/service_locator.dart` - デバッグログの条件付き
- [x] `core/errors/error_handler.dart` - エラーログの適切な処理
- [x] `models/diary_entry.dart` - デバッグ出力の削除
- [x] `debug/font_debug_screen.dart` - デバッグ画面なので保持
- [x] `utils/performance_monitor.dart` - パフォーマンスログの条件付き
- [x] `utils/dialog_utils.dart` - ダイアログログの削除
- [x] `utils/url_launcher_utils.dart` - URLログの削除
- [x] `utils/upgrade_dialog_utils.dart` - アップグレードログの削除
- [x] `ui/components/animated_button.dart` - アニメーションログの削除
- [x] `ui/components/custom_dialog.dart` - ダイアログログの削除
- [x] `ui/error_display/error_display_service.dart` - エラー表示ログの適切化
- [x] `ui/error_display/error_display_widgets.dart` - ウィジェットログの削除

### 3. Result<T>パターンへの移行強化

#### DiaryService
- [x] `saveDiaryEntry()` → `Future<Result<DiaryEntry>>`
- [x] `updateDiaryEntry()` → `Future<Result<DiaryEntry>>`
- [x] `deleteDiaryEntry()` → `Future<Result<void>>`
- [x] `getDiaryEntries()` → `Future<Result<List<DiaryEntry>>>`
- [x] `searchDiaries()` → `Future<Result<List<DiaryEntry>>>`
- [x] `exportDiaries()` → `Future<Result<String>>`
- [x] `importDiaries()` → `Future<Result<ImportResult>>`
- [x] エラーハンドリングのAppException統一
- [x] 呼び出し元での.fold()処理実装

#### DiaryService Result<T>移行の残作業（今後の課題）
- [x] `diary_screen_controller.dart` - Result<T>対応
- [x] `home_content_widget.dart` - forループのResult<T>対応
- [x] `past_photo_calendar_widget.dart` - Result<T>対応
- [x] テストファイルの移行（96個のエラー修正）
  - [x] `test/integration/diary_service_integration_test.dart`
  - [x] `test/integration/diary_service_past_photo_integration_test.dart`
  - [x] `test/integration/mocks/mock_services.dart`
  - [x] `test/integration/test_helpers/integration_test_helpers.dart`
- [x] `flutter analyze`の完全クリア（テストファイル修正後）

#### PhotoService（細分化版）

##### Phase 1: 基盤整備
- [ ] Result用ヘルパーユーティリティ作成
  - [ ] `lib/core/result/photo_result_helper.dart` 作成
  - [ ] `photoPermissionResult()`, `photoAccessResult()` 実装
- [ ] PhotoAccessException詳細化
  - [ ] `PhotoPermissionDeniedException` 追加
  - [ ] `PhotoPermissionPermanentlyDeniedException` 追加
  - [ ] `PhotoLimitedAccessException` 追加
  - [ ] `PhotoDataCorruptedException` 追加

##### Phase 2: Core Permission Methods（基本権限系）
- [ ] `requestPermission()` → `Future<Result<bool>>`（高優先度）
  - [ ] 権限拒否時の`PhotoPermissionDeniedException`
  - [ ] 永続拒否時の`PhotoPermissionPermanentlyDeniedException`
- [ ] `isPermissionPermanentlyDenied()` → `Future<Result<bool>>`
- [ ] `isLimitedAccess()` → `Future<Result<bool>>`

##### Phase 3: Core Photo Retrieval Methods（写真取得系）
- [ ] `getTodayPhotos()` → `Future<Result<List<AssetEntity>>>`（高優先度）
  - [ ] 権限エラー処理をResult型に統一
  - [ ] 写真取得失敗時の詳細エラー情報
- [ ] `getPhotosInDateRange()` → `Future<Result<List<AssetEntity>>>`（高優先度）
  - [ ] 複雑な日付範囲チェックのエラー処理改善
  - [ ] 破損写真検出時の詳細エラー情報
- [ ] `getPhotosForDate()` → `Future<Result<List<AssetEntity>>>`（高優先度）
  - [ ] タイムゾーン関連エラーの詳細化

##### Phase 4: Data Access Methods（データアクセス系）
- [ ] `getPhotoData()` → `Future<Result<Uint8List?>>`
  - [ ] nullチェックとエラー情報の充実
  - [ ] `PhotoDataCorruptedException`の活用
- [ ] `getThumbnailData()` → `Future<Result<Uint8List?>>`
  - [ ] キャッシュ系エラーとの連携
  - [ ] サムネイル生成失敗の詳細化
- [ ] `getThumbnail()` → `Future<Result<Uint8List?>>`（後方互換性維持）
- [ ] `getOriginalFile()` → `Future<Result<Uint8List?>>`（低優先度）

##### Phase 5: Advanced Methods（高度な機能系）
- [ ] `getPhotosEfficient()` → `Future<Result<List<AssetEntity>>>`
  - [ ] ページネーション関連エラーの詳細化
- [ ] `handleLimitedPhotoAccess()` 新規メソッド追加
  - [ ] `Future<Result<void>> handleLimitedPhotoAccess()` 実装
  - [ ] Limited Access時の統一的なハンドリング
- [ ] `presentLimitedLibraryPicker()` → `Future<Result<bool>>`
  - [ ] プラットフォーム固有エラーの詳細化

##### Phase 6: Interface & Caller Updates（インターフェース更新）
- [ ] PhotoServiceInterface更新
  - [ ] 全メソッドのシグネチャをResult型に更新
- [ ] 呼び出し元の段階的更新
  - [ ] `DiaryService` 更新（高優先度 - メイン機能）
  - [ ] `PastPhotosNotifier` 更新（中優先度 - Premium機能）
  - [ ] その他のUI層更新（低優先度）
- [ ] エラー処理の統一
  - [ ] `result.fold()`パターンの活用
  - [ ] 統一的なエラーダイアログ表示
  - [ ] Result型エラーの構造化ログ出力

##### Phase 7: Testing & Validation（テスト・検証）
- [ ] Unit Tests更新
  - [ ] `test/unit/services/photo_service_error_handling_test.dart` 更新
  - [ ] `test/unit/services/photo_service_mock_test.dart` 更新
  - [ ] Result型のテストケース追加
- [ ] Integration Tests更新
  - [ ] `test/integration/photo_service_integration_test.dart` 更新
  - [ ] Result型を考慮したエンドツーエンドテスト
- [ ] 手動テスト項目
  - [ ] 権限拒否シナリオのテスト
  - [ ] Limited Access対応の確認
  - [ ] エラーダイアログ表示の確認

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