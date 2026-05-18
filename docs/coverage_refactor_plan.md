# テストカバレッジ拡充 → ファイル肥大化解消 計画

**方針**: 粗いスモークテストで安全網を張る → 肥大ファイルを分割 → 細かい単体テストを追加

---

## フェーズ 1: スモークテスト（安全網の構築）

> **目標**: 主要ユーザージャーニー 4 本を粗くカバーし、リファクタリング時の退行検知を可能にする。
> 内部実装の詳細には依存しない E2E 観点で書く。

### 1-1. 写真選択 → 日記生成フロー

- [x] `test/integration/smoke/photo_to_diary_smoke_test.dart` を新規作成
  - [x] 写真を選択すると `DiaryPreviewController` が生成フローを開始する
  - [x] AI サービスが呼ばれ、日記テキストが返却される
  - [x] 生成完了後に `DiaryPreviewScreen` に遷移する
  - [x] エラー時（API 失敗）に適切なエラー状態になる

### 1-2. 日記保存 → 一覧表示フロー

- [x] `test/integration/smoke/diary_save_view_smoke_test.dart` を新規作成
  - [x] プレビュー画面から保存すると `DiaryService.create` が呼ばれる
  - [x] 保存後に日記一覧画面に日記が表示される
  - [x] 日記詳細画面が正しく日記データを表示する

### 1-3. サブスクリプション購入フロー

- [x] `test/integration/smoke/subscription_smoke_test.dart` を新規作成
  - [x] 購入開始 → IAP フロー → `SubscriptionStateService` の状態更新 の一連を確認
  - [x] 購入失敗時に状態が変化しないことを確認
  - [x] 復元フローが状態を正しく更新することを確認
  - [x] ※既存の `subscription_service_integration_test.dart` との重複に注意し差分のみカバー

### 1-4. 設定変更フロー

- [x] `test/integration/smoke/settings_flow_smoke_test.dart` を新規作成
  - [x] `SettingsService` の言語設定変更が永続化される
  - [x] `FeatureAccessService` が Premium/Basic に応じて正しく機能制限を返す

### 1-5. スモークテスト共通

- [ ] 既存の `basic_integration_test.dart` の内容をレビューし、重複があれば統合
- [ ] 全スモークテストが `fvm flutter test test/integration/smoke/` で通ることを確認
- [ ] CI の `ci.yml` にスモークテストのステップを追加（既存テストと別ステップ）

---

## フェーズ 2: サービス層の肥大ファイル分割

> **目標**: 400 行超のサービスファイルを単一責任の小さなクラスに分割する。
> 各分割後にフェーズ 1 のスモークテストがグリーンであることを確認する。

### 2-1. `photo_query_service.dart`（542 行）

- [x] 責務分析: クエリ・フィルタ・日付レンジの 3 責務を特定
- [x] `PhotoFilterService` を抽出（フィルタ条件の構築）
- [x] `PhotoDateRangeService` を抽出（日付範囲解決ロジック）
- [x] `PhotoQueryService` を薄いオーケストレーター層に削減（目標 200 行以下）
- [x] 分割後の各クラスに単体テストを追加

### 2-2. `subscription_state_service.dart`（503 行）

- [x] 責務分析: 状態保持・プラン判定・制限チェックの 3 責務を特定
- [x] `SubscriptionPlanResolver` を抽出（プラン種別の判定ロジック）
- [x] `SubscriptionLimitChecker` を抽出（機能制限の判定ロジック）
- [x] `SubscriptionStateService` を状態管理のみに削減（結果 324 行、内部委譲パターン採用）
- [x] 分割後の各クラスに単体テストを追加

### 2-3. `prompt_service.dart`（486 行）

- [x] 責務分析: キャッシュ・フィルタ・永続化の責務を特定
- [x] `PromptCacheService` を抽出（メモリキャッシュ管理）
- [x] `PromptFilterService` を抽出（フィルタ・ソートロジック）
- [x] `PromptService` を薄いファサードに削減（結果 279 行、内部委譲パターン採用）
- [x] `service_registration.dart` の登録を更新（新クラスは PromptService 内部でインスタンス化のため変更不要と確認）
- [x] 分割後の各クラスに単体テストを追加

### 2-4. `diary_generator.dart`（427 行）

- [x] 責務分析: プロンプト組み立て・API 呼び出し・レスポンス解析の責務を特定
- [x] レスポンス解析ロジックを `DiaryResponseParser` に抽出
- [x] `DiaryGenerator` を薄いオーケストレーターに削減（結果 352 行、`DiaryResponseParser` 分離で内部委譲パターン採用）
- [x] 分割後の各クラスに単体テストを追加

### 2-5. `diary_prompt_builder.dart`（406 行）

- [x] 責務分析: 分析・パラメータ決定と文字列構築の 2 責務を特定
- [x] `DiaryPromptAnalyzer` を抽出（プロンプト種別分析・最適化パラメータ・トークン定数）
- [x] `DiaryPromptBuilder` を文字列構築専用に削減（407行 → 270行）
- [x] テンプレート文字列の外部化はスコープ外と判断（AIプロンプトは l10n 不適、定数化でメリット薄）
- [x] 分割後の各クラスに単体テストを追加（diary_prompt_analyzer_test.dart 新規作成・32ケース）

---

## フェーズ 3: UI 層の肥大ファイル分割

> **目標**: 400 行超の画面・ウィジェットファイルを小さなコンポーネントに分割する。
> 分割後にウィジェットテストを追加する。

### 3-1. `prompt_selection_modal.dart`（586 行）

- [x] `PromptSearchBar` ウィジェットを抽出（検索入力 UI）
- [x] `PromptListItem` ウィジェットを抽出（リストアイテム表示）
- [x] `PromptSelectionModal` をシェルのみに削減（目標 200 行以下）
- [x] 各ウィジェットにウィジェットテストを追加

### 3-2. `diary_preview_generating.dart`（504 行）

- [x] `DiaryGeneratingSkeletonView` を抽出（スケルトン UI + 日付行）
- [x] `DiaryGeneratingBanner` を抽出（進捗バナー + `_PulsingDisc` + `_IndeterminateBar`）
- [x] `DiaryPreviewGeneratingScreen` をシェルに削減（504 行 → 200 行）
- [x] 各ウィジェットにウィジェットテストを追加（10 ケース）
- [x] `DiaryGeneratingErrorView` はスコープ外と判断（エラーは親 `diary_preview_screen.dart` で処理）

### 3-3. `settings_screen.dart`（441 行）

- [x] セクション別コンポーネントに分割: `AppearanceSettingsSection`, `DiarySettingsSection`, `PhotoFilterSettingsSection`, `StorageSettingsSection`, `AboutSettingsSection`, `PlanStatusCard`
- [x] `SettingsScreen` をスキャフォールドのみに削減（441行 → 139行）。`SettingsContentBody`, `SettingsLoadingView`, `SettingsLoadErrorView` を抽出
- [x] 各ウィジェットにウィジェットテストを追加（`appearance`, `about`, `storage` セクション）

### 3-4. `diary_detail_screen.dart`（441 行）

- [x] `DiaryDetailActionBar` を抽出（浮動ボタン群 + モアメニュー）
- [x] `DiaryDetailEditBottomBar` を抽出（編集モード Cancel/Save バー）
- [x] `DiaryDetailLoadingView` / `DiaryDetailErrorView` / `DiaryDetailNotFoundView` を `diary_detail_status_views.dart` に抽出
- [x] `DiaryDetailScreen` をルーティングと状態管理のみに削減（441 行 → 222 行）
- [x] ウィジェットテストを追加（`diary_detail_action_bar_test.dart` 8 ケース、`diary_detail_edit_bottom_bar_test.dart` 4 ケース）

### 3-5. `filter_bottom_sheet.dart`（528 行）

- [x] フィルタ条件別ウィジェットに分割（日付・タグ・時間帯）: `FilterSelectionChip`, `FilterDateSection`, `FilterTagSection`, `FilterTimeOfDaySection` を抽出（528行 → 351行）
- [x] ウィジェットテストを追加（`test/widget/shared/` に 30ケース）

### 3-6. `statistics_calendar.dart`（427 行）

- [ ] `CalendarDayCell` ウィジェットを抽出
- [ ] `StatisticsCalendar` をレイアウトのみに削減（目標 250 行以下）
- [ ] ウィジェットテストを追加

---

## フェーズ 4: モデル層の整理

### 4-1. `writing_prompt.dart`（532 行）

- [ ] `legacyTags` deprecated フィールドの扱いを決定（除去 or 移行）
- [ ] WritingPrompt 本体と関連 enum/extension を別ファイルに分割
- [ ] Hive アダプタ再生成（`fvm dart run build_runner build`）
- [ ] 移行後に単体テストを追加

---

## 進捗確認チェックポイント

各フェーズ終了時に以下を実行して確認:

```bash
fvm flutter test                    # 全テストがグリーン（100% 必須）
fvm flutter analyze                 # No issues found!
fvm dart format .                   # フォーマット済み
fvm flutter test --coverage         # カバレッジ 55% 以上（CI 閾値）
```

---

## 対象外（本計画のスコープ外）

- `lib/l10n/generated/` 配下（自動生成ファイル）
- `home_screen.dart`（401 行）— リファクタリング中の状態変化リスクが高い。フェーズ 3 完了後に判断
- `service_registration.dart`（407 行）— 設計上の必要性があるため原則維持
- アクセシビリティ対応（Semantics）— 別タスクとして管理
