# UI リデザイン実装プラン — Claude Design ハンドオフ適用

**作成日**: 2026-05-15  
**ブランチ**: `feat/design_handoff`  
**デザイン方針**: Quiet Luxury を維持しつつ、ハンドオフ定義のカラートークン・タイポグラフィ・コンポーネントに更新

---

## 対象カードバリアント

**Hero Photo バリアント** を採用（日記リストカード）

---

## 実装フェーズ

### Phase 1: デザイントークン基盤

#### 1. `lib/ui/design_system/app_colors.dart`

追加するセマンティックカラートークン:

| トークン名 | 値 | 用途 |
|---|---|---|
| `cardBg` | `#FFFFFF` | カード背景 |
| `muted` | `#6B6560` | ナビ非アクティブ |
| `accentMuted` | `#8E6450` | uppercaseラベル、テラコッタ |
| `divider` | `#EDE9E4` | 区切り線 |
| `chipOutline` | `#DDD8D2` | チップ枠線 |
| `glyphBg` | `#F0EDE8` | アイコン背景 |
| `photoFallback` | `#F0EDE8` | 写真なし時の背景 |
| `handle` | `#DDD8D2` | ドラッグハンドル |

3-toneタグシステム:

| トークン名 | 値 |
|---|---|
| `tagPrimaryBg` | `#E5E0DA` |
| `tagPrimaryFg` | `#2C3338` |
| `tagSecondaryBg` | `#EFE6DE` |
| `tagSecondaryFg` | `#3E322B` |
| `tagAccentBg` | `#F1DCCB` |
| `tagAccentFg` | `#8E6450` |

カレンダートークン:

| トークン名 | 値 |
|---|---|
| `calEntryBg` | `rgba(184,133,108,0.18)` → `0x2EB8856C` |
| `calCountBg` | `#B8856C` |
| `calCountFg` | `#FFFFFF` |
| `calToday` | `#6B7B8D` |
| `calSelected` | `#B8856C` |
| `calDot` | `#8E6450` |

カード選択状態:

| トークン名 | 値 |
|---|---|
| `selectedBg` | `rgba(184,133,108,0.10)` → `0x1AB8856C` |

---

#### 2. `lib/ui/design_system/app_typography.dart`

**既存スタイルは変更しない**: `titleLarge` / `labelSmall` / `bodyLarge` / `bodyMedium` / `diaryTitle` / `statisticsNumber` は設定・ダイアログ・オンボーディング等で広く参照されているため直接更新しない。対象ウィジェット側で以下の新規スタイルに置き換える。

**新規追加スタイル**:

| スタイル名 | 仕様 | 用途 | 置き換え元 |
|---|---|---|---|
| `detailTitle` | 26pt/w700/-0.3/lh1.2 | 詳細画面タイトル | `diaryTitle` |
| `detailBody` | 15.5pt/w400/+0.05/1.75lh | 詳細本文 | `bodyLarge` |
| `statsDisplay` | 40pt/w700/-1.2/lh1.0 | 統計ヒーロー数字 | `statisticsNumber` |
| `sectionLabel` | 11pt/w700/uppercase/+0.8/lh1.2 | セクションヘッダー | `labelSmall` |
| `dateLabel` | 11pt/w700/uppercase/+0.6/lh1.2 | 日付アクセント | — |
| `cardTitle` | 22pt/w700/-0.2/lh1.2 | ヒーローカードタイトル | `titleLarge` |
| `magazineTitle` | 19pt/w700/-0.1/lh1.25 | マガジンカードタイトル | — |
| `cardBody` | 13.5pt/w400/+0.1/1.55lh | カード本文抜粋 | `bodyMedium` |

---

#### 3. `lib/ui/component_constants.dart`

追加・更新する定数クラス:

```dart
class CardConstants {
  static const double radiusHero = 20.0;
  static const double radiusMagazine = 18.0;
  static const double radiusEditorial = 22.0;
}

class ButtonConstants {
  // 既存 borderWidth 維持
  static const double heightSm = 46.0;   // 現行 40 → 46
  static const double heightMd = 50.0;   // 新規
}

class BottomSheetConstants {
  static const double radius = 28.0;
}

class ModalConstants {
  static const double radius = 24.0;
}
```

---

### Phase 2: コアコンポーネント更新

#### 4. `lib/ui/components/modern_chip.dart`

3-toneサイクリングファクトリを追加:

```dart
factory ModernChip.tonedTag(String label, {required int index}) {
  final tone = index % 3;
  // tone 0: tagPrimaryBg/Fg
  // tone 1: tagSecondaryBg/Fg
  // tone 2: tagAccentBg/Fg
  return ModernChip(
    label: label,
    backgroundColor: [...][tone],
    foregroundColor: [...][tone],
    borderRadius: 8,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );
}
```

**後方互換**: 既存の `.tag()` / `.badge()` ファクトリは維持。

---

#### 5. `lib/widgets/diary_card_widget.dart`

**Hero Photo バリアント** に全面更新。

現行レイアウト:
```
[タイトル] [日付]
[本文プレビュー 3行]
[水平スクロール写真]
[タグ chips]
```

新レイアウト:
```
[写真 3:2 AspectRatio, top radius 20]
  └ 写真枚数バッジ (複数枚時: 右上)
[日付ラベル "FEB 18 · TUESDAY"  11pt/uppercase/accentMuted]
[タイトル  22pt/w700/-0.2]
[本文抜粋  13.5pt/1.6lh  最大2行]
[3-toneタグ chips  最大3個]
```

実装詳細:
- `AspectRatio(aspectRatio: 3/2)` でヒーロー写真
- 写真なし時: `glyphBg` 背景 + `Icons.photo_camera_outlined`
- 日付フォーマット: ロケール対応が必要。`DateFormat.yMMMEd(locale.toString()).format(date).toUpperCase()` を使用するか、フォーマットパターンを ARB キーで定義する（英語固定不可）
- タグ: `ModernChip.tonedTag(label, index: i)` で自動3-tone
- カード `borderRadius`: `BorderRadius.circular(20)`
- シャドウ: `BoxShadow(color: Color(0x0A231E1A), blurRadius: 22, offset: Offset(0, 6))`

---

#### 6. `lib/shared/filter_bottom_sheet.dart`

ハンドオフのFilter Sheet UIへ更新:

| 要素 | 仕様 |
|---|---|
| ドラッグハンドル | 36×5px / radius 999 / `handle`色 |
| ヘッダーラベル | `context.l10n` 経由の文言 / 11pt/uppercase / `accentMuted` |
| ヘッダータイトル | `context.l10n` 経由の文言 / 24pt/w700/-0.3 |
| DatePill | 2列グリッド / height 56 / radius 14 |
| DatePill 未選択 | `glyphBg` 背景 + border `divider` |
| DatePill 選択済 | `selectedBg` 背景 + border accent + ×クリア |
| タグチップ | pill (radius 999) / 未選択→選択トグル |
| Time of Day | 4チップ 朝🌅/昼☀️/夕🌆/夜🌙 |
| Applyボタン | height 50 / radius 14 / アクティブ時バッジ表示 |

---

#### 7. `lib/widgets/prompt_selection_modal.dart`

ハンドオフのPrompt Modal UIへ更新:

| 要素 | 仕様 |
|---|---|
| ヘッダー日付ラベル | 11pt/uppercase/`accentMuted` |
| ヘッダータイトル | `context.l10n` 経由の文言 / 22pt/w700 |
| Quick options | 2列グリッド: `context.l10n` 経由のラベル |
| プロンプトリスト行 | カテゴリタグ + プレミアムバッジ + タイトル + 説明 |
| スティッキーアクションバー | `context.l10n` 経由のボタン文言 |
| コンテキスト入力 | トグル付きオプションフィールド |

---

### Phase 3: スクリーン更新

#### 8. `lib/screens/statistics/statistics_cards.dart`

3-toneカードタイントシステムへ更新:

| カードindex | 背景色 | 用途 |
|---|---|---|
| 0 (cycle) | `#EEEAE3` | Primary tone |
| 1 (cycle) | `#F2EAE2` | Secondary tone |
| 2 (cycle) | `#F4E1D2` | Accent tone |

タイポグラフィ更新:
- ラベル: 11pt/w700/uppercase/0.9tracking
- 数値: `statsDisplay` (40pt/w700/-1.2)
- 単位: 13pt/w500/`muted`

---

#### 9. `lib/screens/statistics/statistics_calendar.dart`

カラートークンをハンドオフ定義に更新:

| 状態 | トークン |
|---|---|
| エントリ日背景 | `calEntryBg` |
| 複数エントリバッジ背景/文字 | `calCountBg` / `calCountFg` (14×14px) |
| 今日リング | `calToday` |
| 選択日 | `calSelected` / white |
| ドット | `calDot` |

凡例UI追加: Entry / Multiple / Today / Selected の4アイテム

---

#### 10. `lib/screens/settings_screen.dart` + `lib/widgets/settings/settings_row.dart`

**Settings Screen** 構造更新:

```
[ヘッダー: "Account" ラベル(11pt/uppercase) + "Settings" 28pt/w700]
[PlanCard: radius 20 / premiumBg / 使用量バー / Upgradeボタン]
[SettingsGroup × 4]
  - Appearance: テーマ / 言語
  - Diary & Photos: フィルター等
  - Data: ストレージ / バックアップ
  - About: バージョン / 法的情報
```

**SettingsRow** 更新:

| 要素 | 仕様 |
|---|---|
| アイコンボックス | 36×36px / radius 10 / `glyphBg` |
| タイトル | 15pt/w600/-0.1 |
| サブタイトル | 12.5pt/`muted` / ellipsis |
| 区切り線 | 0.5px / `divider` / marginLeft 66 |

---

## 変更しないもの

- データモデル・サービス層（ビジネスロジック）
- ナビゲーション構造（IndexedStack）
- ローカライゼーション（既存 l10n 流用）
- `lib/ui/components/custom_dialog.dart`
- `lib/ui/animations/`
- テスト構造（widget テストは最小限の更新のみ）

---

## 検証手順

```bash
# 1. コード品質
fvm flutter analyze    # "No issues found!" 必須
fvm dart format .

# 2. テスト
fvm flutter test       # 全テスト通過

# 3. ビジュアル確認
fvm flutter run
# 確認画面:
# - Diaries: Hero Photoカード
# - Statistics: 3-toneカード + カレンダー
# - Settings: プランカード + グループ構造
# - フィルターシート: DatePill + TimeChip
# - プロンプトモーダル: Quick options + リスト

# 4. ダークモード確認
# シミュレータで外観をダーク切り替えて全画面チェック
```

---

## 実装順序

| # | ファイル | 依存 |
|---|---|---|
| 1 | `app_colors.dart` | なし |
| 2 | `app_typography.dart` | なし |
| 3 | `component_constants.dart` | なし |
| 4 | `modern_chip.dart` | 1 |
| 5 | `diary_card_widget.dart` | 1, 2, 3, 4 |
| 6 | `statistics_cards.dart` | 1, 2 |
| 7 | `statistics_calendar.dart` | 1 |
| 8 | `settings_screen.dart` + `settings_row.dart` | 1, 2, 3 |
| 9 | `filter_bottom_sheet.dart` | 1, 2, 3, 4 |
| 10 | `prompt_selection_modal.dart` | 1, 2, 3, 4 |
| 11 | `fvm flutter analyze && fvm flutter test` | 全 |
