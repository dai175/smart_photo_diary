import 'package:flutter_test/flutter_test.dart';

/// Phase 3.1.2: プロンプト機能統合テストスイート
///
/// このファイルは、プロンプト機能統合テストを
/// 一括実行するためのテストスイートです。
///
/// ## 実行方法
/// ```bash
/// # 全体テストスイート実行
/// fvm flutter test test/integration/prompt_features/ --reporter expanded
///
/// # 詳細レポート付きで実行
/// fvm flutter test test/integration/prompt_features/ --reporter json
///
/// # 特定のテストグループのみ実行
/// fvm flutter test test/integration/prompt_features/prompt_features_test.dart --name "3.1.2.1" --reporter expanded
/// ```
///
/// ## テスト内容
/// ### Phase 3.1.2: プロンプト機能統合テスト
///
/// #### 3.1.2.1: プラン別表示テスト
/// - Basicプランで基本プロンプト（5個）のみ表示確認
/// - Premiumプランで全プロンプト（20個）表示確認
/// - プラン変更時の表示切り替え確認
///
/// #### 3.1.2.2: Basic/Premium分離テスト
/// - Basic/Premium用プロンプトの正確な分離
/// - プラン権限による適切なフィルタリング
/// - 無効なプランでのアクセス制限
///
/// #### 3.1.2.3: プロンプト検索テスト
/// - キーワード検索の基本動作
/// - プラン制限下での検索結果フィルタリング
/// - 空検索結果の適切な処理
///
/// #### 3.1.2.4: カテゴリフィルタテスト
/// - カテゴリ別フィルタリング機能
/// - プラン制限を考慮したカテゴリフィルタ
/// - 複数カテゴリでの組み合わせテスト
///
/// ## 技術要件検証
/// - MockSubscriptionServiceとPromptServiceの統合使用
/// - ServiceLocatorを使った依存注入テスト
/// - `Result<T>`パターンでのエラーハンドリング検証
/// - 各テストケースは独立して実行可能
///
/// ## 期待される結果
/// - 全テストケースが成功すること
/// - プラン別アクセス制御が正しく動作すること
/// - 検索・フィルタ機能が期待通りに動作すること
/// - エラーハンドリングが適切に実装されていること

// プロンプト機能統合テストをインポート
import 'prompt_features_test.dart' as prompt_features;

/// Phase 3.1.2: プロンプト機能統合テストスイート
///
/// プロンプト機能の統合テストを実行します。
/// このテストスイートでは、MockSubscriptionServiceとPromptServiceを
/// 統合して、プラン別のプロンプト表示、検索、フィルタリング機能を
/// 包括的にテストします。
void main() {
  group('Phase 3.1.2: プロンプト機能統合テストスイート', () {
    // プロンプト機能統合テスト
    group('プロンプト機能統合テスト', prompt_features.main);
  });
}
