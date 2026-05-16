# UI リデザイン 残タスクチェックリスト

**作成日**: 2026-05-16
**ブランチ**: `feat/design_handoff`
**対象**: ハンドオフ未反映 + ダークモード色バグ

---

## 推奨着手順

```
4-1（l10n）→ 0-1〜0-4（ダークバグ）→ 1-1〜1-2（ホーム）→ 3-1（統計）→ 2-3〜2-5 → 2-1〜2-2（詳細）→ 4-2（検証）
```

---

## Phase 0 — ダークモード色バグ修正

> 影響範囲最小・独立タスク。最優先で対応する。

### Task 0-1: `lib/widgets/diary_card_widget.dart`

- [x] `_buildPhotoFallback()` のシグネチャを `_buildPhotoFallback(BuildContext context)` に変更し、呼び出し元も更新
- [x] 行 111: `color: AppColors.cardBg`（白固定）→ ダーク時は `colorScheme.surfaceContainerHigh` に
- [x] 行 148: `color: AppColors.muted` → `colorScheme.onSurfaceVariant`
- [x] 行 239: `color: AppColors.glyphBg`（写真なし背景）→ `colorScheme.surfaceContainerHighest`
- [x] 行 242: `color: AppColors.muted`（写真なしアイコン）→ `colorScheme.onSurfaceVariant`

### Task 0-2: `lib/ui/components/modern_chip.dart`

- [x] `_ChipVariant` enum に `.tonedTag` を追加
- [x] `ModernChip` に `final int? _toneIndex` フィールドを追加（`tonedTag` 時のみ非 null）
- [x] 既存コンストラクタ（`ModernChip(...)`・`.tag`・`.badge`）のイニシャライザリストに `_toneIndex = null` を追加（追加しないと Dart がビルドエラーになるため必須）
- [x] ダーク用 3-tone 定数を追加（`_tonedTagBgsDark` / `_tonedTagFgsDark`）
  - tone 0: bg `Color(0xFF3A3530)` / fg `Color(0xFFD4CFC9)`
  - tone 1: bg `Color(0xFF3F3630)` / fg `Color(0xFFD9CFC6)`
  - tone 2: bg `Color(0xFF453228)` / fg `Color(0xFFD4A68E)`
- [x] `factory ModernChip.tonedTag` で `_variant: _ChipVariant.tonedTag`・`_toneIndex: index % 3` を設定（`backgroundColor` は null のままで可）
- [x] `_getChipColorData()` に `_ChipVariant.tonedTag` ケースを追加し、`isDark` に応じてトーン色を返す

### Task 0-3: `lib/widgets/settings/settings_row.dart`

- [x] 行 40: `color: AppColors.glyphBg`（アイコンボックス背景）→ `colorScheme.surfaceContainerHighest`
- [x] 行 92: `color: AppColors.divider`（区切り線）→ `colorScheme.outlineVariant`

### Task 0-4: `lib/screens/settings_screen.dart` — `_buildPlanCard()`

- [x] メソッド冒頭に `final isDark = Theme.of(context).brightness == Brightness.dark;` を追加
- [x] 行 228: `color: AppColors.glyphBg`（null 状態背景）→ `colorScheme.surfaceContainerHighest`
- [x] 行 235: `color: AppColors.muted`（null 状態テキスト）→ `colorScheme.onSurfaceVariant`
- [x] 行 249: `color: AppColors.premiumBg` → `isDark ? const Color(0xFF2E2420) : AppColors.premiumBg`
- [x] 行 282 / 287: `color: AppColors.muted`（使用量テキスト）→ `colorScheme.onSurfaceVariant`
- [x] 行 297: `backgroundColor: AppColors.divider`（プログレスバー背景）→ `colorScheme.outlineVariant`

---

## Phase 1 — ホーム画面コンポーネント更新

### Task 1-1: `lib/widgets/home_content_widget.dart` — ヘッダーリデザイン

- [x] `app_en.arb` / `app_ja.arb` に `homeHeaderSubtitle` キーを追加（Task 4-1 先行）
- [x] `_buildHeader()` を `PreferredSize`（高さ 108）ベースのカスタムヘッダーに差し替え
  - 左カラム: 日付小ラベル（`AppTypography.dateLabel` / `accentMuted`）+ `context.l10n.timelineToday`（既存キー・ja: "今日"）（28pt/w700/-0.4）+ サブテキスト（13.5pt/`onSurfaceVariant`）
  - 右: `_buildUsagePill()`
- [x] `_buildHeaderDateLabel(BuildContext)` メソッドを実装（`DateFormat('EEEE · MMM d', locale).format(now).toUpperCase()`）
- [x] `_buildUsagePill()` メソッドを実装（`ISubscriptionService` から使用量を取得、ピル UI、タップで既存 `_showUsageStatus()` を呼ぶ）
- [x] `_buildTimelineSection()` 内の選択解除バー（`AnimatedSize` + `ListenableBuilder` ブロック 行 100〜144）を削除

### Task 1-2: `lib/widgets/smart_fab_widget.dart` + `lib/widgets/timeline_fab_integration.dart`

- [x] `SmartFABWidget._buildFAB()` を `SmartFABState.camera` と `createDiary` で分岐するように改修
- [x] `_buildCameraFAB()`: 既存 `FloatingActionButton` を移動。背景色を `AppColors.accent`（`#B8856C`）固定に
- [x] `_buildSelectionPill()`: 全幅ピルバーを実装
  - `Container` height 56 / radius 999 / 背景 `AppColors.accent`
  - 左: 選択枚数テキスト（白 14pt/w600）
  - 右: `context.l10n.homeSelectionClearAll`（既存キー・ja: "選択解除"）テキストボタン（白70）+ `context.l10n.fabCreateDiaryShort` ピルボタン（白背景 20% / 白テキスト）
- [x] `app_en.arb` / `app_ja.arb` に `fabCreateDiaryShort` キーを追加（Task 4-1 先行）
- [x] `AnimatedSwitcher.transitionBuilder` を `FadeTransition` のみに簡略化（形状変化に対応）
- [x] `timeline_fab_integration.dart` の `Positioned` を `ListenableBuilder` でラップし、選択時は `left: 16` も追加して全幅配置に

---

## Phase 2 — 日記詳細画面の全面リレイアウト

> 2-3 / 2-4 / 2-5 を先に完了させてから 2-1 / 2-2 を組み上げる。

### Task 2-3: `lib/screens/diary_detail/diary_detail_photo_section.dart`

- [x] `CustomCard` ラッパーを廃止
- [x] `AspectRatio(4/3)` + `Stack` 構造に変更
- [x] グラデーションスクリム（上部 45% 高さ、`rgba(0,0,0,0.5)` → 透明）を追加
- [x] 複数写真時の枚数バッジ（右下、`Colors.black54` / blur / "1 / N"）を追加
- [x] 写真ロード: `IPhotoCacheService.getThumbnail` + `Image.memory`（既存 `diary_card_widget` パターン参考）

### Task 2-4: `lib/screens/diary_detail/diary_detail_content_editor.dart`

- [x] `build()` から `_buildHeader()`（アイコン + `diaryDetailContentHeading`）の呼び出しを削除
- [x] `CustomCard` ラッパーを廃止し、`Column` のみを返す
- [x] 閲覧モードメソッド（`_buildReadOnlyTitle` / `_buildReadOnlyContent`）を削除（content 側に移動済みとなるため）

### Task 2-5: `lib/screens/diary_detail/diary_detail_metadata_section.dart`

- [x] タグ表示ブロックを削除（タグは `diary_detail_content.dart` 側に移動）
- [x] MetaRow のみ（作成日・更新日・写真枚数など）を返すように縮小
- [x] `CustomCard` ラッパーを廃止

### Task 2-1: `lib/screens/diary_detail/diary_detail_screen.dart`

- [x] `Scaffold.extendBodyBehindAppBar: true` を追加
- [x] 閲覧モード時: `appBar: null`、`body` を `Stack` でラップしてフローティングコントロールを上層配置
- [x] 編集モード時: 既存 `_buildAppBar()` を維持
- [x] `_buildFloatingControls()` を実装（戻る / シェア / 編集 / ⋯ の 36×36 ピルボタン）
  - 位置: `top: MediaQuery.padding.top + 12` / `left: 20` / `right: 20`
  - スタイル: `Colors.black.withValues(alpha: 0.45)` 背景 / 白アイコン
- [x] `_showMoreMenu()` を実装（既存 `PopupMenuButton` の削除メニューを代替）
- [x] `PopScope` は維持（物理バックキー対応）

### Task 2-2: `lib/screens/diary_detail/diary_detail_content.dart`

- [x] `_buildDateHeader()` メソッドを削除
- [x] `SingleChildScrollView` 内を 1面エディトリアルレイアウトに全面書き換え
  - `_buildHeroPhotoSection(context)` または写真なしプレースホルダー（Task 2-3 を使用）
  - 日付ラベル: `AppTypography.dateLabel` / `accentMuted`（`_buildDateLabel()` メソッドで生成）
  - タイトル: 閲覧時 `AppTypography.detailTitle` / 編集時 `_buildEditableTitleInline()`
  - 3-tone タグ chips（`ModernChip.tonedTag`）
  - `Divider`（height 1 / thickness 1）
  - 本文: 閲覧時 `AppTypography.detailBody` / 編集時 `_buildEditableContentInline()`
  - `_buildInlineGallery()`: 2枚目以降の写真を 3列グリッド（radius 10 / `shrinkWrap: true`）
  - `Divider` + `DiaryDetailMetadataSection`
- [x] `_buildDateLabel(BuildContext)` メソッドを実装（`DateFormat('MMM d · EEEE', locale).format(date).toUpperCase()`）
- [x] `_buildInlineGallery(BuildContext)` メソッドを実装

---

## Phase 3 — 統計カード更新

### Task 3-1: `lib/screens/statistics/statistics_cards.dart`

- [ ] 3-tone 背景色定数を追加
  - ライト: `#EEEAE3` / `#F2EAE2` / `#F4E1D2`
  - ダーク: `#2A2723` / `#2C2421` / `#2E211C`
- [ ] `_buildStatCard()` の第5引数を `IconData icon` → `int index` に変更
- [ ] `CustomCard` を廃止し、`Container` + `BoxDecoration(color: tones[index % 3])` に変更
- [ ] 数値スタイルを `headlineSmall`（24pt）→ `AppTypography.statsDisplay`（40pt/w700/-1.2）に変更
- [ ] ラベルスタイルを `AppTypography.sectionLabel`（11pt/w700/uppercase）に変更
- [ ] アイコン表示を廃止
- [ ] 呼び出し元 4箇所の `icon:` 引数を `index: 0/1/2/3` に変更

---

## Phase 4 — l10n 追加 + 検証

### Task 4-1: l10n キー追加（最初に実行）

- [ ] `lib/l10n/app_en.arb` に追加:
  ```json
  "homeHeaderSubtitle": "Tap photos from today to create a diary",
  "fabCreateDiaryShort": "Create diary →"
  ```
- [ ] `lib/l10n/app_ja.arb` に追加:
  ```json
  "homeHeaderSubtitle": "今日の写真をタップして日記を作成",
  "fabCreateDiaryShort": "日記を作成 →"
  ```
- [ ] `fvm flutter gen-l10n` を実行

### Task 4-2: 検証

- [ ] `fvm flutter analyze` — "No issues found!" を確認
- [ ] `fvm dart format .` を実行
- [ ] `fvm flutter test` — 全テスト通過を確認

**ライトモード目視確認**:
- [ ] ホーム: 日付ラベル（大文字）→ Today タイトル → サブテキスト → UsagePill
- [ ] ホーム（写真選択後）: 全幅ピルバー表示 / 上部選択バー非表示
- [ ] 日記詳細（写真あり）: 4:3 フルブリード → フローティングボタン → 日付ラベル → タイトル → タグ → Divider → 本文 → インラインギャラリー → MetaRow
- [ ] 日記詳細（写真なし）: プレースホルダー → テキストコンテンツ
- [ ] 日記詳細（編集モード）: AppBar 復活 + 編集フィールド + Save/Cancel バー
- [ ] 統計: 3-tone カード背景 + 40pt 数値
- [ ] 設定: PlanCard / SettingsRow アイコンボックス / divider

**ダークモード目視確認**:
- [ ] 日記リスト: カード背景がダーク（白でない）/ 本文色が `onSurfaceVariant`
- [ ] 日記リスト: 写真なしプレースホルダーがダーク背景
- [ ] 日記リスト: タグチップがダーク 3-tone パレット
- [ ] 設定 SettingsRow: アイコンボックスがダーク背景 / divider がダーク
- [ ] 設定 PlanCard（null 状態）: ダーク背景
- [ ] 設定 PlanCard（通常）: ダークテラコッタ背景（`#2E2420`）
- [ ] 設定 プログレスバー: ダーク背景色

---

## 変更しないもの

| ファイル | 理由 |
|---|---|
| `lib/ui/design_system/app_colors.dart` | ライトトークンは実装済み |
| `lib/ui/design_system/app_typography.dart` | 新規スタイルは実装済み |
| `lib/ui/component_constants.dart` | 定数は実装済み |
| `lib/shared/filter_bottom_sheet.dart` | 実装済み |
| `lib/widgets/prompt_selection_modal.dart` | 実装済み |
| `lib/ui/animations/` | 変更なし |
| `lib/ui/components/custom_dialog.dart` | 変更なし |
| データモデル・サービス層 | ビジネスロジックは変更なし |
| ナビゲーション構造（IndexedStack） | 変更なし |
