# 多言語対応チェックリスト

## フェーズ1: ローカリゼーション基盤整備
- [x] `l10n.yaml` を作成し `arb-dir`, `template-arb-file`, `output-localization-file` を設定する
- [x] `lib/l10n/app_ja.arb` と `lib/l10n/app_en.arb` を初期化し、`@@locale` を指定する
- [x] `.gitignore` に `lib/l10n/generated/` を追加し、自動生成ファイルを除外する
- [x] `flutter gen-l10n` を CI/ローカル手順に組み込み生成手順をドキュメント化する (`fvm flutter gen-l10n` をベースコマンドとして追記済み)

### フェーズ1手順メモ
- ローカル生成: `fvm flutter gen-l10n --arb-dir=lib/l10n --output-dir=lib/l10n/generated`
- CI 反映: コマンドをビルド前ステップへ追加し、生成物をコミット対象外に設定

## フェーズ2: アプリロケール管理
- [ ] `SettingsService` に言語設定キーを追加し、永続化/取得メソッドを実装する
- [ ] `MyApp` で `AppLocalizations` を読み込み、`locale` と `localeResolutionCallback` を設定する
- [ ] 言語変更イベントをアプリ全体に通知する仕組み（例: `ValueNotifier` や `InheritedWidget`）を導入する

## フェーズ3: UI言語切替
- [ ] `SettingsScreen` に言語選択UIを追加し、選択結果を `SettingsService` に反映する
- [ ] 初回起動/オンボーディング中にシステム言語へのフォールバックを確認する
- [ ] テーマ切替と同様に言語切替時のリビルドを検証する

## フェーズ4: 文言のローカライズ
- [ ] `AppConstants` などハードコードされた日本語文字列をローカライズキーへ移行する
- [ ] 各 `Screen` / `Widget` のテキストを `AppLocalizations` 経由に置き換える
- [ ] ダイアログ・トースト・SnackBar など共通文言をまとめるヘルパーを実装する
- [ ] 変数埋め込みが必要なメッセージはプレースホルダー付きで ARB に登録する

## フェーズ5: ドメインデータ・プロンプト
- [ ] `WritingPrompt` データ構造を多言語対応（言語別フィールド or ロケール別ファイル）に更新する
- [ ] `PromptService` と関連ユーティリティをロケールに応じてテキストを返すよう修正する
- [ ] プロンプト検索・タグ機能が両言語で機能するかを検証する

## フェーズ6: フォーマットと数値表現
- [ ] 日付表示を `intl` のロケール対応フォーマッターに統一する
- [ ] 通貨・数値表現をロケールごとの表示に切り替える
- [ ] ロケール別の曜日・月名が適切に表示されるか確認する

## フェーズ7: テストとQA
- [ ] 主要画面の Widget テストにロケール変更シナリオを追加する
- [ ] `flutter analyze` / `flutter test` / `flutter gen-l10n` を含むQA手順を更新する
- [ ] 英語・日本語双方のスクリーンショットを取得しUI崩れを確認する

## ドキュメント・共有
- [ ] ローカライズ作業手順と命名規約を `docs/` 配下にまとめる
- [ ] 翻訳リクエスト用テンプレート（翻訳未完了キー一覧など）を整備する

## 画面別翻訳差し替え
- [ ] `OnboardingScreen` のテキストをローカライズキーへ置換
- [ ] `HomeScreen` / `HomeContentWidget` のヘッダー・ダイアログ文言を置換
- [ ] `Diary*` 系画面（`DiaryScreen`, `DiaryDetailScreen`, `DiaryPreviewScreen`）を置換
- [ ] `SettingsScreen` と関連ダイアログを置換
- [ ] `StatisticsScreen` と分析メトリクスのラベルを置換
- [ ] 共通ウィジェット (`CustomDialog`, `PresetDialogs`, `TimelineFABIntegration` 等) を置換
- [ ] テスト用モックやサンプルデータの固定文言を更新
