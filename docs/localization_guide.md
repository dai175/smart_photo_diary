# ローカライズ実装ガイド

Smart Photo Diary で新しい文言を追加・更新する際の手順と命名規約をまとめました。英語・日本語の2言語を前提にしていますが、追加のロケールにも対応できるよう設計しています。

## 基本方針
- 文字列は必ず `lib/l10n/app_*.arb` に定義し、UI からは `AppLocalizations` 経由で参照する。
- 動的に埋め込む値はプレースホルダーを使用し、`@` メタデータに説明と型を付与する。
- 例外・ログなどユーザに表示されない文言は、必要に応じて英語化するがブロッキングではない。
- ユーザ向けコピーの初稿は英語で作成し、日本語訳を付ける。順序を揃えることで翻訳差分を追いやすくする。

## 文言追加手順
1. `lib/l10n/app_en.arb` に英語キーを追加し、`lib/l10n/app_ja.arb` に対応する訳を追記する。
2. 必要に応じて `@@locale` などメタ情報を確認し、`@yourKey` に説明やプレースホルダー情報を追加する。
3. `fvm flutter gen-l10n` を実行して `lib/l10n/generated` を再生成する。
4. ウィジェットまたはサービスで `context.l10n.yourKey`（または `AppLocalizations.of(context)`）を利用して文言を参照する。
5. 既存テストに影響がある場合は、期待文言を更新し、多言語で成立するアサーションへ書き換える。

## キー命名規約
- 画面単位の接頭辞を付ける（例: `settingsLanguageDialogTitle`）。
- 共通文言は `common` 接頭辞を使用（例: `commonSave`, `commonCancel`）。
- プレースホルダーは `{variableName}` のスネークケースを避け、キャメルケースで統一する。
- 長文メッセージは `SectionActionOutcome` の順に並べ、意味が把握しやすいキー名にする（例: `diaryDeleteConfirmMessage`).

## プレースホルダーと複数形
- プレースホルダーには `@key` セクションで `placeholders` を定義し、`type` と `example` を記載する。
- 数値の複数形が必要な場合は `Intl.plural` を活用し、`app_en.arb` に `plural` セクションを追加する。
- 日付や金額はロケール依存のフォーマッタ（`context.l10n.formatFullDate` など）を通じて表示する。

## テスト・QA
- 新規キーを追加したら `fvm flutter gen-l10n` → `fvm flutter analyze` → `fvm flutter test` の順で実行する。
- 画面単体テストでは `locale` を切り替えて主要文言が変化することを確認する（`test/widget/locale_switch_widget_test.dart` 参照）。
- 翻訳忘れチェックには `scripts/find_unlocalized_strings.sh`（後述）や `rg "[ぁ-んァ-ン]" lib` などを利用する。

## スクリプトと補助ツール
- `scripts/dev_run.sh --gen-l10n` : ローカル実行前に L10n を自動生成。
- （追加予定）`scripts/find_unlocalized_strings.sh` : 日本語ハードコード検知の補助。

## レビュー時のポイント
- 新規キーが `app_en.arb` / `app_ja.arb` に揃っているか。
- `AppLocalizations` を通らないユーザ向け文言が残っていないか。
- テストがロケールに依存したハードコード値（例: 固定日付）を持っていないか。

以上の手順に従ってローカライズを進めてください。追加ロケール対応時は同じ流れで `app_xx.arb` を増やし、必要なテストを拡張します。
