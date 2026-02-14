# コードレビュー改善アクションアイテム

辛口評価 **68点/100点** に基づく改善項目を優先順にまとめたもの。

---

## 優先度 S: 設計矛盾の解消（+9点見込み）

### S-1. Result<T> の全面採用（エラーハンドリング +4点）

**現状**: Result<T> sealed class が存在するが、採用率は20-30%。215箇所の try-catch が残存。

**対象ファイル（最優先）**:
- `lib/services/ai/gemini_api_client.dart` — `sendTextRequest()`, `sendVisionRequest()` が `Map?` を返す。Result型に変更
- `lib/services/ai/ai_service.dart` — `_recordAiUsage()` が例外を飲み込む

**対象ファイル（段階的）**:
- `lib/services/diary_service.dart` — 一部メソッドがtry-catchのまま
- `lib/services/photo_query_service.dart` — 内部メソッドのResult化
- `lib/services/in_app_purchase_service.dart` — 購入フローのResult統一

**方針**:
1. GeminiApiClient の戻り値を `Future<Result<Map<String, dynamic>>>` に変更
2. 呼び出し側（AiService）をswitch式でパターンマッチに変更
3. ErrorHandler の `handleError()` を `Result<T>` を返す形に統一し、二重系統を解消

### S-2. Getter副作用の排除（コード品質 +2点）

**現状**: `SubscriptionStatus.hasReachedMonthlyLimit` プロパティが `_resetMonthlyUsageIfNeeded()` を呼び、Hive DBへの書き込みが発生。

**対象ファイル**:
- `lib/models/subscription_status.dart:153-156` — `hasReachedMonthlyLimit`
- `lib/models/subscription_status.dart:159-161` — `canUseAiGeneration`
- `lib/models/subscription_status.dart:164-169` — `remainingGenerations`

**方針**:
1. `_resetMonthlyUsageIfNeeded()` を呼ぶ副作用getterを全て明示的メソッドに変更
2. 月次リセットはサービス層（`SubscriptionStateService`）で実行
3. モデルのgetterは純粋な計算のみに限定

### S-3. Model-永続層分離（コード品質 +3点）

**現状**: `DiaryEntry.updateContent()` が内部で `HiveObject.save()` を直接呼ぶ。モデルが永続層と密結合。

**対象ファイル**:
- `lib/models/diary_entry.dart:58-70` — `updateContent()`, `updateTags()` が `save()` を呼ぶ
- `lib/models/subscription_status.dart:100-131` — `changePlanClass()` が `save()` を呼ぶ
- `lib/models/subscription_status.dart:172-176` — `incrementAiUsage()` が `save()` を呼ぶ

**方針**:
1. モデルから `save()` 呼び出しを全て削除
2. サービス層（DiaryService, SubscriptionStateService）が明示的に `box.put()` で保存
3. モデルはPODO（Plain Old Dart Object）として振る舞う

---

## 優先度 A: テスト基盤の強化（+5点見込み）

### A-1. カバレッジ閾値を60%に引き上げ（テスト +2点）

**現状**: CI閾値が40%。業界標準は60-70%。

**対象ファイル**:
- `.github/workflows/ci.yml` — 閾値変更
- 以下のサービステスト追加が先に必要

### A-2. 未テストサービスへのテスト追加（テスト +3点）

**現状**: 10サービス実装にユニットテストなし。

**優先順位（ロジック複雑度順）**:
1. `lib/services/subscription_state_service.dart` — 状態管理ロジックが複雑
2. `lib/services/diary_statistics_service.dart` — 集計ロジック
3. `lib/services/diary_tag_service.dart` — AI連携のタグ生成
4. `lib/services/prompt_usage_service.dart` — 使用量追跡
5. `lib/services/ai_usage_service.dart` — AI使用量管理

**プラットフォーム依存で優先度低**:
6. `lib/services/in_app_purchase_service.dart` — StoreKit依存
7. `lib/services/photo_query_service.dart` — photo_manager依存
8. `lib/services/camera_service.dart` — カメラAPI依存
9. `lib/services/photo_permission_service.dart` — permission_handler依存

---

## 優先度 B: アーキテクチャ改善（+4点見込み）

### B-1. ServiceLocator直接呼び出しの排除（アーキテクチャ +2点）

**現状**: 各サービスが `serviceLocator.get<T>()` を内部で直接呼ぶ（Service Locatorアンチパターン）。

**方針**:
- サービス内部での `serviceLocator.get<T>()` をコンストラクタ注入に段階的に移行
- `ServiceRegistration` でのDI構築時にコンストラクタで依存を渡す
- 遅延解決が必要な場合のみ `serviceLocator.get<T>()` を許容

### B-2. DiaryService インターフェースの分割（アーキテクチャ +2点）

**現状**: `IDiaryService` がメソッド30+個の God Interface。

**方針**:
- `IDiaryCrudService` — CRUD操作
- `IDiarySearchService` — 検索・フィルタ
- `IDiaryStreamService` — 変更ストリーム
- 既存の `IDiaryTagService`, `IDiaryStatisticsService` はそのまま維持
- 呼び出し側は必要なインターフェースのみ依存

---

## 優先度 C: UI層の整理（+2点見込み）

### C-1. 大規模ウィジェットの分割

**対象ファイル**:
- `lib/widgets/past_photo_calendar_widget.dart`（540行）→ カレンダー表示 / 写真ロード / 月ビュー計算に分割
- `lib/widgets/settings/storage_settings_section.dart`（485行）→ セクション別に分割
- `lib/widgets/prompt_selection_modal.dart`（485行）→ リスト表示 / 選択ロジックに分割

---

## 優先度 D: 細部の改善

### D-1. DiaryEntry の二重タグフィールド統一
- `cachedTags` と `tags` を単一フィールドに統合
- マイグレーション処理が必要

### D-2. 定数ファイルの分割
- `app_constants.dart`（166行）を `theme_constants.dart`, `ai_constants.dart` に分離

### D-3. グラデーション定義の整理
- `homeGradient` と `modernHomeGradient` の統一

---

## スコア改善見込み

| 施策 | 現在 | 改善後 | 差分 |
|------|------|--------|------|
| S-1: Result全面採用 | 7/15 | 11/15 | +4 |
| S-2: Getter副作用排除 | 10/15 | 12/15 | +2 |
| S-3: Model-DB分離 | (同上) | 13/15 | +3 |
| A-1+A-2: テスト強化 | 9/15 | 14/15 | +5 |
| B-1+B-2: アーキテクチャ改善 | 14/20 | 18/20 | +4 |
| C-1: ウィジェット分割 | 8/10 | 10/10 | +2 |
| **合計** | **68** | **88** | **+20** |

全て実施すれば 88点（プロダクション品質）に到達可能。
