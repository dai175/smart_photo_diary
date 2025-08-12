import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/subscription_access_control_manager.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';

class MockLoggingService extends Mock implements LoggingService {}

/// SubscriptionAccessControlManager 単体テスト
///
/// SubscriptionServiceから分離されたアクセス制御ロジックの独立テスト
/// - 依存性分離（LoggingServiceのモック使用）
/// - 各機能メソッドの個別検証
/// - Result<T>パターンのエラーハンドリング
/// - 初期化状態の管理
/// - ファサード機能の並行処理
void main() {
  group('SubscriptionAccessControlManager 単体テスト', () {
    late SubscriptionAccessControlManager manager;
    late MockLoggingService mockLoggingService;

    setUp(() {
      mockLoggingService = MockLoggingService();
      manager = SubscriptionAccessControlManager(mockLoggingService);
    });

    tearDown(() {
      manager.dispose();
    });

    group('初期化・破棄処理', () {
      test('コンストラクタで正しく初期化される', () {
        expect(manager.isInitialized, isTrue);
        verify(() => mockLoggingService.debug(
          'SubscriptionAccessControlManager initialized',
          context: 'SubscriptionAccessControlManager',
          data: null,
        )).called(1);
      });

      test('dispose後は初期化フラグがfalseになる', () {
        manager.dispose();

        expect(manager.isInitialized, isFalse);
        verify(() => mockLoggingService.info(
          'Disposing SubscriptionAccessControlManager...',
          context: 'SubscriptionAccessControlManager',
          data: null,
        )).called(1);
        verify(() => mockLoggingService.info(
          'SubscriptionAccessControlManager disposed',
          context: 'SubscriptionAccessControlManager',
          data: null,
        )).called(1);
      });
    });

    group('プレミアム機能アクセス権限判定', () {
      test('Basicプランではプレミアム機能にアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status, 
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('Premium月額プランではプレミアム機能にアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Premium年額プランではプレミアム機能にアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('無効なサブスクリプションではプレミアム機能にアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = false
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('ライティングプロンプト機能アクセス権限判定', () {
      test('Basicプランではライティングプロンプトにアクセスできる（制限付き）', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessWritingPrompts(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('Premium月額プランではライティングプロンプトにアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessWritingPrompts(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('期限切れのPremiumプランでも基本ライティングプロンプトアクセス可能', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().subtract(const Duration(days: 1));

        bool isValidSubscription(SubscriptionStatus s) => 
          s.isActive && (s.expiryDate?.isAfter(DateTime.now()) ?? false);

        final result = await manager.canAccessWritingPrompts(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('高度なフィルタ機能アクセス権限判定', () {
      test('Basicプランでは高度なフィルタにアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessAdvancedFilters(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランでは高度なフィルタにアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessAdvancedFilters(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('無効なPremiumプランでは高度なフィルタにアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = false
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessAdvancedFilters(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });

    group('高度な分析機能アクセス権限判定', () {
      test('Basicプランでは高度な分析にアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessAdvancedAnalytics(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランでは高度な分析にアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessAdvancedAnalytics(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('データエクスポート機能アクセス権限判定', () {
      test('Basicプランでもデータエクスポートにアクセスできる（JSON形式のみ）', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessDataExport(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });

      test('有効なPremiumプランではデータエクスポートにアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessDataExport(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('統計ダッシュボード機能アクセス権限判定', () {
      test('Basicプランでは統計ダッシュボードにアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessStatsDashboard(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランでは統計ダッシュボードにアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessStatsDashboard(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('優先サポート機能アクセス権限判定', () {
      test('Basicプランでは優先サポートにアクセスできない', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPrioritySupport(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('有効なPremiumプランでは優先サポートにアクセスできる', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPrioritySupport(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue);
      });
    });

    group('統合機能アクセス権限取得', () {
      test('Basicプランの機能アクセス権限マップを取得', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.getFeatureAccess(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<Map<String, bool>>());

        final featureAccess = result.value;
        expect(featureAccess['premiumFeatures'], isFalse);
        expect(featureAccess['writingPrompts'], isTrue);
        expect(featureAccess['advancedFilters'], isFalse);
        expect(featureAccess['dataExport'], isTrue);
        expect(featureAccess['statsDashboard'], isFalse);
        expect(featureAccess['advancedAnalytics'], isFalse);
        expect(featureAccess['prioritySupport'], isFalse);
      });

      test('Premium月額プランの機能アクセス権限マップを取得', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.getFeatureAccess(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<Map<String, bool>>());

        final featureAccess = result.value;
        expect(featureAccess['premiumFeatures'], isTrue);
        expect(featureAccess['writingPrompts'], isTrue);
        expect(featureAccess['advancedFilters'], isTrue);
        expect(featureAccess['dataExport'], isTrue);
        expect(featureAccess['statsDashboard'], isTrue);
        expect(featureAccess['advancedAnalytics'], isTrue);
        expect(featureAccess['prioritySupport'], isTrue);
      });

      test('Premium年額プランの機能アクセス権限マップを取得', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumYearlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 365));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.getFeatureAccess(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);

        final featureAccess = result.value;
        expect(featureAccess['premiumFeatures'], isTrue);
        expect(featureAccess['writingPrompts'], isTrue);
        expect(featureAccess['advancedFilters'], isTrue);
        expect(featureAccess['dataExport'], isTrue);
        expect(featureAccess['statsDashboard'], isTrue);
        expect(featureAccess['advancedAnalytics'], isTrue);
        expect(featureAccess['prioritySupport'], isTrue);
      });

      test('並行処理でのアクセス権限マップ取得', () async {
        final status = SubscriptionStatus()
          ..planId = SubscriptionConstants.premiumMonthlyPlanId
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final results = await Future.wait([
          manager.getFeatureAccess(status, isValidSubscription),
          manager.getFeatureAccess(status, isValidSubscription),
          manager.getFeatureAccess(status, isValidSubscription),
        ]);

        for (final result in results) {
          expect(result.isSuccess, isTrue);
          expect(result.value, isA<Map<String, bool>>());
        }

        final firstResult = results[0].value;
        for (final result in results) {
          expect(result.value, equals(firstResult));
        }
      });
    });

    group('エラーハンドリング', () {
      test('初期化前の呼び出しでServiceExceptionが返される', () async {
        final uninitializedManager = SubscriptionAccessControlManager(
          mockLoggingService,
        );
        uninitializedManager.dispose();

        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true;

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await uninitializedManager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        expect(result.error.message, contains('AccessControlManager is not initialized'));
      });

      test('例外発生時の適切なエラーハンドリング', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true;

        bool isValidSubscription(SubscriptionStatus s) => 
          throw Exception('Test exception');

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
        verify(() => mockLoggingService.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
        )).called(greaterThan(0));
      });

      test('getFeatureAccessで個別機能エラー時の伝播', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true;

        manager.dispose(); // 初期化フラグをfalseにしてエラーを発生させる

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.getFeatureAccess(
          status,
          isValidSubscription,
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServiceException>());
      });
    });

    group('ログ出力検証', () {
      test('デバッグログが適切に出力される', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        await manager.canAccessPremiumFeatures(status, isValidSubscription);

        verify(() => mockLoggingService.debug(
          'Checking premium features access...',
          context: 'SubscriptionAccessControlManager',
          data: null,
        )).called(1);

        verify(() => mockLoggingService.debug(
          'Premium features access check completed',
          context: 'SubscriptionAccessControlManager',
          data: any(named: 'data'),
        )).called(1);
      });

      test('エラーログが適切に出力される', () async {
        final status = SubscriptionStatus()
          ..planId = 'basic'
          ..isActive = true;

        bool isValidSubscription(SubscriptionStatus s) => 
          throw Exception('Test error');

        await manager.canAccessPremiumFeatures(status, isValidSubscription);

        verify(() => mockLoggingService.error(
          any(that: contains('Operation failed: canAccessPremiumFeatures')),
          context: 'SubscriptionAccessControlManager.canAccessPremiumFeatures',
          error: any(named: 'error'),
        )).called(1);
      });
    });

    group('境界条件テスト', () {
      test('空文字planIdでの動作', () async {
        final status = SubscriptionStatus()
          ..planId = ''
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });

      test('不明なplanIdでの動作', () async {
        final status = SubscriptionStatus()
          ..planId = 'unknown_plan'
          ..isActive = true
          ..expiryDate = DateTime.now().add(const Duration(days: 30));

        bool isValidSubscription(SubscriptionStatus s) => s.isActive;

        final result = await manager.canAccessPremiumFeatures(
          status,
          isValidSubscription,
        );

        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse);
      });
    });
  });
}