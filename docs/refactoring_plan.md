# リファクタリング計画書 (Refactoring Plan)

このドキュメントは、Smart Photo Diaryアプリの今後の機能追加に向けて必要なリファクタリング作業を整理したものです。

## 概要

現在のコードベースは基本的な機能は実装されているものの、以下の課題により今後の機能追加が困難になる可能性があります：
- 大きなファイルサイズ（main.dart: 470行、ai_service.dart: 835行）
- サービス間の密結合
- 一貫性のないエラーハンドリング
- テストカバレッジの不足

## 優先度別リファクタリングタスク

### 🔴 高優先度（即座に対応が必要）

#### 1. 大きなファイルの分割

**main.dart (470行) の分割**
- [x] lib/main.dart の軽量化（初期化とアプリ設定のみ）
- [x] lib/screens/home_screen.dart の作成（ホーム画面）
- [x] lib/widgets/home_content_widget.dart の作成（メインコンテンツ）
- [x] lib/widgets/navigation_widget.dart の作成（ナビゲーション）

**ai_service.dart (835行) の分割**
- [x] lib/services/ai/gemini_api_client.dart の作成（API通信）
- [x] lib/services/ai/diary_generator.dart の作成（日記生成）
- [x] lib/services/ai/tag_generator.dart の作成（タグ生成）
- [x] lib/services/ai/offline_fallback_service.dart の作成（オフライン対応）
- [x] lib/services/ai/ai_service_interface.dart の作成（インターフェース定義）
- [x] 既存 ai_service.dart の置き換えと統合テスト

**diary_screen.dart (509行) の分割**
- [x] lib/screens/diary_screen.dart の軽量化（画面構成のみ）
- [x] lib/widgets/diary_card_widget.dart の作成（日記カード）
- [x] lib/widgets/diary_search_widget.dart の作成（検索機能）
- [x] lib/controllers/diary_screen_controller.dart の作成（ビジネスロジック）

#### 2. 依存性注入の実装

- [x] AiServiceInterface の作成（抽象化）
- [x] PhotoServiceInterface の作成（抽象化）
- [x] DiaryService での依存性注入パターン適用
- [x] サービスロケータまたはDIコンテナの導入
- [x] 既存サービス間の密結合解消

#### 3. テストカバレッジの追加

**Unit Tests**
- [x] test/unit/services/diary_service_test.dart の作成
- [x] test/unit/services/ai_service_test.dart の作成
- [x] test/unit/services/photo_service_test.dart の作成
- [x] test/unit/services/image_classifier_service_test.dart の作成
- [x] test/unit/models/diary_entry_test.dart の作成
- [x] 既存 widget_test.dart の更新（カウンターアプリテンプレート削除）
- [x] test/unit/core/service_locator_test.dart の作成

**Widget Tests**
- [x] test/widget/diary_card_test.dart の作成
- [x] test/widget/photo_grid_test.dart の作成
- [x] test/widget/filter_bottom_sheet_test.dart の作成
- [x] test/widget/recent_diaries_widget_test.dart の作成
- [x] test/widget/home_content_test.dart の作成
- [x] test/test_helpers/widget_test_helpers.dart の作成（テストユーティリティ）

**Integration Tests**
- [x] test/integration/diary_flow_test.dart の作成（写真選択→日記生成フロー）
- [x] test/integration/settings_flow_test.dart の作成
- [x] test/integration/basic_integration_test.dart の作成（基本動作確認）
- [x] test/integration/test_helpers/integration_test_helpers.dart の作成
- [x] test/integration/mocks/mock_services.dart の作成
- [x] mocktail によるモック実装の整備
- [x] プラットフォームチャンネルのモック対応
- [x] サービスロケータ連携の統合テスト環境構築

### 🟡 中優先度（機能追加前に対応）

#### 4. エラーハンドリングの統一

- [ ] Result<T> 型の導入（Success/Failure パターン）
- [ ] 統一されたエラーログ仕組みの実装
- [ ] 各サービスでのエラーハンドリング統一
- [ ] UI レベルでのエラー表示統一
- [ ] 例外からResult型への変換レイヤー作成

#### 5. 状態管理の一元化

- [ ] Provider または Riverpod の導入検討・選択
- [ ] PhotoSelectionController の Provider/Riverpod 移行
- [ ] 各画面の StatefulWidget → Consumer パターン移行
- [ ] ViewModelパターンの導入
- [ ] グローバル状態とローカル状態の明確な分離

#### 6. 画像キャッシュとパフォーマンス最適化

- [ ] CachedNetworkImage の導入
- [ ] 画像サムネイルキャッシュシステムの実装
- [ ] const コンストラクタの適用（全ウィジェット監査）
- [ ] FutureBuilder の最適化と再構築削減
- [ ] 大きなリストでの仮想スクロール導入検討

### 🟢 低優先度（長期的な改善）

#### 7. 機能ベースアーキテクチャへの移行

- [ ] features/diary/ ディレクトリ構造の設計
- [ ] features/photo/ ディレクトリ構造の設計  
- [ ] features/ai/ ディレクトリ構造の設計
- [ ] shared/ 共通コンポーネントの整理
- [ ] core/ インフラレイヤーの設計
- [ ] 既存コードの段階的移行計画策定
- [ ] 新アーキテクチャでの依存関係ルール策定

#### 8. 国際化対応の準備

- [ ] flutter_localizations の導入
- [ ] 日本語ハードコーディング文字列の洗い出し
- [ ] lib/l10n/ ディレクトリとARBファイルの作成
- [ ] 各画面・ウィジェットでの国際化対応
- [ ] 英語翻訳の追加

#### 9. CI/CDパイプラインの構築

- [ ] GitHub Actions ワークフローの設定
- [ ] コード品質チェック（flutter analyze）の自動化
- [ ] テスト実行の自動化
- [ ] ビルド成功確認の自動化
- [ ] カバレッジレポート生成の自動化

## 実装スケジュール案

### Phase 1: 基盤整備 (2-3週間) ✅ **完了**
- [x] main.dart の分割
- [x] ai_service.dart の分割
- [x] 基本的なテストの追加
- [x] 既存機能の動作確認

### Phase 2: アーキテクチャ改善 (2-3週間) ✅ **完了** 
- [x] 依存性注入の実装
- [x] エラーハンドリングの統一
- [x] diary_screen.dart の分割
- [x] テストカバレッジの拡充

### Phase 3: 最適化 (1-2週間)
- [ ] パフォーマンス最適化
- [ ] 状態管理の一元化
- [ ] キャッシュ機能の実装
- [ ] 最終的な統合テスト

## 期待される効果

### コード品質の向上
- 可読性とメンテナビリティの向上
- バグの早期発見
- コードレビューの効率化

### 開発効率の向上
- 新機能追加時の影響範囲の限定
- テスト駆動開発の促進
- チーム開発への対応

### アプリケーションの安定性向上
- エラーハンドリングの一貫性
- パフォーマンスの最適化
- ユーザー体験の向上

## 進捗管理

各チェックボックスは以下の基準で更新してください：
- [ ] 未着手
- [x] 完了

定期的な進捗レビューを実施し、必要に応じてスケジュールを調整してください。

## 注意事項

1. **段階的実装**: 一度に全てを変更せず、段階的にリファクタリングを実施
2. **後方互換性**: 既存機能への影響を最小限に抑制
3. **テスト実装**: リファクタリング前後でのテスト実装を徹底
4. **コードレビュー**: 各フェーズでのコードレビューを実施

この計画に従ってリファクタリングを実施することで、今後の機能追加において安定かつ効率的な開発が可能になります。