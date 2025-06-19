import 'package:flutter_test/flutter_test.dart';

/// Phase 3.1.1: サブスクリプション機能テストスイート
/// 
/// このファイルは、サブスクリプション機能統合テストを
/// 一括実行するためのテストスイートです。
/// 
/// 実行方法:
/// ```bash
/// fvm flutter test test/integration/subscription_features/ --reporter expanded
/// ```

// 基本的なサブスクリプション統合テストをインポート
import 'basic_subscription_test.dart' as basic_subscription;

/// Phase 3.1.1: サブスクリプション機能統合テストスイート
/// 
/// 基本的なサブスクリプション機能の統合テストを実行します。
void main() {
  group('Phase 3.1.1: サブスクリプション機能統合テストスイート', () {
    // 基本的なサブスクリプション機能テスト
    group('サブスクリプション基本機能テスト', basic_subscription.main);
  });
}