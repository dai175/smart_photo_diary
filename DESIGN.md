# DESIGN.md — Smart Photo Diary デザインシステム

## デザイン哲学 — Quiet Luxury

写真が主役のアプリとして、UIは**写真を邪魔しない**ことを最優先とする。
派手な色・グラデーション・強いコントラストを避け、温かみのあるニュートラルで統一する。

- **写真ファースト**: UIクロームは極力控えめに
- **温かみ**: 純白・純黒を使わず、ウォームオフホワイト（`#F8F6F3`）とウォームニアブラック（`#1A1816`）を基調
- **軽やかさ**: タイポグラフィは軽いウェイト（w300/w400中心）とゆとりのあるレタースペーシング

---

## カラーパレット

実装: `lib/ui/design_system/app_colors.dart`

### 3階層カラー構造

| 役割 | トークン | HEX | 用途 |
|------|---------|-----|------|
| Primary | `AppColors.primary` | `#6B7B8D` | Warm Slate — 主要UIアクセント |
| Secondary | `AppColors.secondary` | `#A68B7B` | Warm Taupe — 控えめなアクセント |
| Accent | `AppColors.accent` | `#B8856C` | Terracotta — ここぞの強調のみ |
| AccentDark | `AppColors.accentDark` | `#8E6450` | **CTA・インタラクティブ要素専用** |

### アクセントカラーの使い分けルール（WCAG準拠）

- **`accentDark` (`#8E6450`)** → ElevatedButton・FAB・選択状態など、**白文字を乗せるすべてのインタラクティブ要素**に使用
  - 理由: `accent (#B8856C)` on white はコントラスト比が WCAG AA（4.5:1）を下回るため
- **`accent` (`#B8856C`)** → OutlinedButton・TextButton・アンダーライン等、**背景なしで使う装飾要素**に使用

> このルールはコミット `refactor: unify interactive colors on accent and fix WCAG contrast` で統一された。
> 新しいボタン・インタラクティブ要素を追加する際は必ず `accentDark` を使うこと。

### セマンティックカラー

パレットと調和するよう、純粋な赤・緑・黄を避けてミュートトーンで定義している。

| 用途 | トークン | 色調 |
|------|---------|------|
| エラー | `AppColors.error` | テラコッタ系ブリックレッド（`#994F47`） |
| 成功 | `AppColors.success` | セージグリーン（`#5C8A62`） |
| 警告 | `AppColors.warning` | ウォームアンバー（`#C4844A`） |
- `AppColors.primary` / `primaryLight` / `AppColors.info` はテキスト・アイコン・背景いずれにも使用しない（カレンダーの「今日」マーカーは意図的な例外）

### 3トーン タグシステム

タグは primary / secondary / accent の3トーンでカテゴリを視覚的に区別する。
ダークモード対応トークンも定義済み（`tagPrimaryBgDark` 等）。

```
tagPrimary:   背景 #E5E0DA / 文字 #2C3338
tagSecondary: 背景 #EFE6DE / 文字 #3E322B
tagAccent:    背景 #F1DCCB / 文字 #8E6450
```

---

## タイポグラフィ

実装: `lib/ui/design_system/app_typography.dart`
フォント: **Noto Sans JP**（Google Fonts、テスト環境ではシステムフォントにフォールバック）

### Quiet Luxury タイポグラフィ原則

- Display/Statistics 系: **w300** — エディトリアルな軽やかさ
- 見出し系: **w400** — やや広めのレタースペーシング（+0.3）
- タイトル/ラベル: **w500** — 控えめなエンファシス
- 日本語専用スタイル: `japaneseBody` は `letterSpacing: 0`・`height: 1.60` でカーニングしない

### デザインハンドオフ専用スタイル（`// DESIGN HANDOFF STYLES`）

通常の MD3 スタイルとは別に、カード・詳細画面用の高密度スタイルが定義されている。

| スタイル | サイズ | ウェイト | 用途 |
|---------|-------|---------|------|
| `cardTitle` | 22pt / w700 / ls-0.2 | Bold | ヒーローカードタイトル |
| `magazineTitle` | 19pt / w700 / ls-0.1 | Bold | マガジンカードタイトル |
| `detailTitle` | 26pt / w700 / ls-0.3 | Bold | 詳細画面タイトル |
| `detailBody` | 15.5pt / w400 / ls+0.05 / lh1.75 | Regular | 詳細本文（読みやすさ重視） |
| `statsDisplay` | 40pt / w700 / ls-1.2 | Bold | 統計ヒーロー数字 |
| `sectionLabel` | 11pt / w700 / ls+0.8 | Bold uppercase | セクションヘッダー |

---

## スペーシングシステム

実装: `lib/ui/design_system/app_spacing.dart`

**8pt グリッドシステム**（`AppSpacing.base = 8.0`）

| トークン | 値 | 用途 |
|---------|---|------|
| `xxs` | 2pt | 極小マージン |
| `xs` | 4pt | アイコン-ラベル間など |
| `sm` | 8pt | 小間隔 |
| `md` | 12pt | カード内パディング |
| `lg` | 16pt | 画面端パディング・標準間隔 |
| `xl` | 24pt | セクション間・ダイアログ内 |
| `xxl` | 32pt | セクション間マージン |
| `xxxl` | 48pt | 大きなセクション区切り |

### 角丸スケール

| トークン | 値 | 用途 |
|---------|---|------|
| `borderRadiusSm` | 8pt | ボタン・入力フィールド |
| `borderRadiusMd` | 12pt | カード標準 |
| `borderRadiusLg` | 16pt | 大カード・ダイアログ |
| `borderRadiusXl` | 20pt | チップ（`AppSpacing.chipRadius`）・モーダル上2角（`AppSpacing.modalRadius`） |
| `ModalConstants.radius` | 24pt | **CustomDialog のみ** |
| `BottomSheetConstants.radius` | 28pt | **ボトムシート標準**（全ボトムシートで統一） |

### タッチターゲット

最小タッチターゲット: **44pt**（`AppSpacing.minTouchTarget`）。iOS HIG 準拠。

---

## コンポーネント規約

### ダイアログ — `CustomDialog` 必須

`AlertDialog` は**使用禁止**。必ず `lib/ui/components/custom_dialog.dart` の `CustomDialog` を使うこと。

- スケールアニメーション付き（`MicroInteractions.scaleTransition`）
- `ModalConstants.shadow`（3層シャドウ）を適用
- 閉じるボタンは `onClose` パラメータで X ボタンとして表示
- よく使うパターンは `preset_dialogs.dart` に定義済み

### モーダル・ボトムシート

- **CustomDialog の角丸**: `ModalConstants.radius = 24.0`（`AppSpacing.modalRadius` は上2角のみのプリセット）
- **ボトムシートの角丸**: `BottomSheetConstants.radius = 28.0`（上2角のみ）— `filter_bottom_sheet.dart` 等すべてのボトムシートで統一
- ドラッグハンドル: `BottomSheetConstants`（width=36、height=4、radius=2）
- アイコン背景: サイズ44・radius12（`ModalConstants.iconSize/iconRadius`）

### グラデーション禁止

グラデーションは使用しない。写真の上に乗せるオーバーレイも `Colors.black.withValues(alpha: ...)` の単色のみ。

---

## ダークモード

実装: `lib/ui/design_system/app_theme_dark.dart`

ダークモードはライトモードの色を単純反転せず、専用トークンで定義する。

| ライト | ダーク |
|--------|--------|
| `background: #F8F6F3` | `backgroundDark: #1A1816` |
| `surface: #FAF8F5` | `surfaceDark: #221F1D` |
| `outline: #DDD8D2` | `outlineDark: #3D3833` |

サーフェスコンテナ（エレベーション表現）:
- `surfaceContainerDark`: `#2A2623`
- `surfaceContainerHighDark`: `#2E2A27`
- `surfaceContainerHighestDark`: `#3A3633`

---

## 実装チェックリスト

新しい UI を追加する際の確認事項:

- [ ] CTA・選択状態は `accentDark`（`accent` は装飾のみ）
- [ ] `info`・`primary`・`primaryLight` をテキスト・アイコン・背景に使っていないか確認（代わりにウォームパレットのセマンティックカラーを使用）
- [ ] ダイアログは `CustomDialog`（`AlertDialog` は不可）
- [ ] スペーシングは `AppSpacing` トークンを使用（マジックナンバー禁止）
- [ ] タッチターゲットは最小 44pt
- [ ] グラデーションを使っていないか確認
- [ ] ダークモード対応（`Theme.of(context)` 経由で色を取得）
- [ ] 日本語テキストは `context.l10n` 経由（ハードコード禁止）
