import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/subscription_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/services/logging_service.dart';
import 'package:smart_photo_diary/services/subscription_purchase_manager.dart';
import 'package:smart_photo_diary/services/subscription_status_manager.dart';
import 'package:smart_photo_diary/services/subscription_usage_tracker.dart';
import 'package:smart_photo_diary/services/subscription_access_control_manager.dart';
import '../helpers/hive_test_helpers.dart';

// モッククラス
class MockLoggingService extends Mock implements LoggingService {}

class MockSubscriptionPurchaseManager extends Mock
    implements SubscriptionPurchaseManager {}

class MockSubscriptionStatusManager extends Mock
    implements SubscriptionStatusManager {}

class MockSubscriptionUsageTracker extends Mock
    implements SubscriptionUsageTracker {}

class MockSubscriptionAccessControlManager extends Mock
    implements SubscriptionAccessControlManager {}

void main() {
  group('SubscriptionService ファサードテスト', () {
    late SubscriptionService subscriptionService;
    late MockLoggingService mockLoggingService;

    setUpAll(() async {
      // Hiveテスト環境のセットアップ
      await HiveTestHelpers.setupHiveForTesting();
    });

    setUp(() async {
      // モックインスタンス作成
      mockLoggingService = MockLoggingService();

      // LoggingServiceモックのセットアップ
      when(
        () => mockLoggingService.debug(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.info(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.warning(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mockLoggingService.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
        ),
      ).thenReturn(null);

      // 各テスト前にHiveボックスをクリア
      await HiveTestHelpers.clearSubscriptionBox();

      // SubscriptionServiceインスタンスをリセット
      SubscriptionService.resetForTesting();
    });

    tearDownAll(() async {
      // テスト終了時にHiveを閉じる
      await HiveTestHelpers.closeHive();
    });

    group('ファサード初期化テスト', () {
      test('getInstance()でファサードが正しく初期化される', () async {
        // Act
        final instance = await SubscriptionService.getInstance();

        // Assert
        expect(instance, isNotNull);
        expect(instance.isInitialized, isTrue);
      });

      test('シングルトンパターンが正しく動作する', () async {
        // Act
        final instance1 = await SubscriptionService.getInstance();
        final instance2 = await SubscriptionService.getInstance();

        // Assert
        expect(instance1, same(instance2));
        expect(instance1.isInitialized, isTrue);
      });
    });

    group('ファサード委任テスト - ステータス管理', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });

      test('getCurrentStatus()がStatusManagerに委任される', () async {
        // Act
        final result = await subscriptionService.getCurrentStatus();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.planId, equals('basic'));
        expect(result.value.isActive, isTrue);
      });

      test('updateStatus()がStatusManagerに委任される', () async {
        // Arrange
        final newStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          autoRenewal: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now(),
          transactionId: 'test_transaction',
          lastPurchaseDate: DateTime.now(),
        );

        // Act
        final updateResult = await subscriptionService.updateStatus(newStatus);
        final getResult = await subscriptionService.getCurrentStatus();

        // Assert
        expect(updateResult.isSuccess, isTrue);
        expect(getResult.isSuccess, isTrue);
        expect(getResult.value.planId, equals('premium_monthly'));
        expect(getResult.value.monthlyUsageCount, equals(5));
      });

      test('refreshStatus()がStatusManagerに委任される', () async {
        // Act
        final result = await subscriptionService.refreshStatus();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('createStatusClass()がStatusManagerに委任される', () async {
        // Arrange
        await subscriptionService.clearStatus();
        final basicPlan = BasicPlan();

        // Act
        final result = await subscriptionService.createStatusClass(basicPlan);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value.planId, equals('basic'));
        expect(result.value.isActive, isTrue);
        expect(result.value.expiryDate, isNull);
      });

      test('clearStatus()がStatusManagerに委任される', () async {
        // Act
        final result = await subscriptionService.clearStatus();

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });

    group('ファサード委任テスト - 使用量管理', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });

      test('canUseAiGeneration()がUsageTrackerに委任される', () async {
        // Act
        final result = await subscriptionService.canUseAiGeneration();

        // Assert
        expect(result.isSuccess, isTrue);
        // 初期状態では使用可能
        expect(result.value, isTrue);
      });

      test('incrementAiUsage()がUsageTrackerに委任される', () async {
        // Act
        final incrementResult = await subscriptionService.incrementAiUsage();
        final statusResult = await subscriptionService.getCurrentStatus();

        // Assert
        expect(incrementResult.isSuccess, isTrue);
        expect(statusResult.isSuccess, isTrue);
        expect(statusResult.value.monthlyUsageCount, equals(1));
      });

      test('getRemainingAiGenerations()がUsageTrackerに委任される', () async {
        // Arrange
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await subscriptionService.createStatusClass(premiumMonthlyPlan);

        // 5回使用
        for (int i = 0; i < 5; i++) {
          await subscriptionService.incrementAiUsage();
        }

        // Act
        final result = await subscriptionService.getRemainingAiGenerations();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(95)); // Premium: 100 - 5 = 95
      });

      test('getNextResetDate()がUsageTrackerに委任される', () async {
        // Act
        final result = await subscriptionService.getNextResetDate();

        // Assert
        expect(result.isSuccess, isTrue);
        final nextReset = result.value;
        final now = DateTime.now();

        // 翌月の1日であることを確認
        if (now.month == 12) {
          expect(nextReset.year, equals(now.year + 1));
          expect(nextReset.month, equals(1));
        } else {
          expect(nextReset.year, equals(now.year));
          expect(nextReset.month, equals(now.month + 1));
        }
        expect(nextReset.day, equals(1));
      });

      test('resetMonthlyUsageIfNeeded()がUsageTrackerに委任される', () async {
        // Arrange
        await subscriptionService.incrementAiUsage();
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // 前月の日付でリセット日を設定
        final status = (await subscriptionService.getCurrentStatus()).value;
        final previousMonth = DateTime(
          DateTime.now().month == 1
              ? DateTime.now().year - 1
              : DateTime.now().year,
          DateTime.now().month == 1 ? 12 : DateTime.now().month - 1,
          1,
        );

        final modifiedStatus = SubscriptionStatus(
          planId: status.planId,
          isActive: status.isActive,
          startDate: status.startDate,
          expiryDate: status.expiryDate,
          autoRenewal: status.autoRenewal,
          monthlyUsageCount: status.monthlyUsageCount,
          lastResetDate: previousMonth,
          transactionId: status.transactionId,
          lastPurchaseDate: status.lastPurchaseDate,
        );

        await subscriptionService.updateStatus(modifiedStatus);

        // Act
        await subscriptionService.resetMonthlyUsageIfNeeded();
        final newStatus = (await subscriptionService.getCurrentStatus()).value;

        // Assert
        expect(newStatus.monthlyUsageCount, equals(0));
      });
    });

    group('ファサード委任テスト - アクセス制御', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });

      test('canAccessPremiumFeatures()がAccessControlManagerに委任される', () async {
        // Arrange - Basicプラン
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // Act
        final result = await subscriptionService.canAccessPremiumFeatures();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは基本機能のみ
      });

      test('canAccessWritingPrompts()がAccessControlManagerに委任される', () async {
        // Act
        final result = await subscriptionService.canAccessWritingPrompts();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // 基本プロンプトは利用可能
      });

      test('canAccessAdvancedFilters()がAccessControlManagerに委任される', () async {
        // Arrange - Basicプラン
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // Act
        final result = await subscriptionService.canAccessAdvancedFilters();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは高度なフィルタ利用不可
      });

      test('canAccessDataExport()がAccessControlManagerに委任される', () async {
        // Act
        final result = await subscriptionService.canAccessDataExport();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // 基本エクスポートは利用可能
      });

      test('canAccessStatsDashboard()がAccessControlManagerに委任される', () async {
        // Arrange - Basicプラン
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // Act
        final result = await subscriptionService.canAccessStatsDashboard();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isFalse); // Basicプランは統計ダッシュボード利用不可
      });

      test('getFeatureAccess()がAccessControlManagerに委任される', () async {
        // Arrange - Basicプラン
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // Act
        final result = await subscriptionService.getFeatureAccess();

        // Assert
        expect(result.isSuccess, isTrue);
        final features = result.value;
        expect(features['premiumFeatures'], isFalse);
        expect(features['writingPrompts'], isTrue);
        expect(features['advancedFilters'], isFalse);
        expect(features['dataExport'], isTrue);
        expect(features['statsDashboard'], isFalse);
      });
    });

    group('統合テスト - Premium プラン機能', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });

      test('Premiumプランでは制限が100回に設定される', () async {
        // Arrange
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        // Act
        final remainingResult = await subscriptionService
            .getRemainingAiGenerations();
        final premiumFeaturesResult = await subscriptionService
            .canAccessPremiumFeatures();
        final advancedFiltersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final statsDashboardResult = await subscriptionService
            .canAccessStatsDashboard();

        // Assert
        expect(remainingResult.isSuccess, isTrue);
        expect(remainingResult.value, equals(100)); // Premium制限
        expect(premiumFeaturesResult.value, isTrue);
        expect(advancedFiltersResult.value, isTrue);
        expect(statsDashboardResult.value, isTrue);
      });

      test('期限切れのPremiumプランでは制限が適用される', () async {
        // Arrange - 期限切れのPremiumプランを作成
        final expiredStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          expiryDate: DateTime.now().subtract(const Duration(days: 30)),
          autoRenewal: false,
          monthlyUsageCount: 0,
          lastResetDate: DateTime.now(),
          transactionId: 'expired_premium',
          lastPurchaseDate: DateTime.now().subtract(const Duration(days: 60)),
        );

        await subscriptionService.updateStatus(expiredStatus);

        // Act
        final canUseResult = await subscriptionService.canUseAiGeneration();
        final remainingResult = await subscriptionService
            .getRemainingAiGenerations();
        final premiumFeaturesResult = await subscriptionService
            .canAccessPremiumFeatures();
        final advancedFiltersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final statsDashboardResult = await subscriptionService
            .canAccessStatsDashboard();

        // Assert
        expect(canUseResult.value, isFalse); // 期限切れなので使用不可
        expect(remainingResult.value, equals(0)); // 期限切れなので0
        expect(premiumFeaturesResult.value, isFalse); // 期限切れなので利用不可
        expect(advancedFiltersResult.value, isFalse); // 期限切れなので利用不可
        expect(statsDashboardResult.value, isFalse); // 期限切れなので利用不可
      });

      test('Basicプランでは制限が10回に設定される', () async {
        // Arrange
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        // Basic制限の10回まで使用
        for (int i = 0; i < 10; i++) {
          final result = await subscriptionService.incrementAiUsage();
          expect(result.isSuccess, isTrue);
        }

        // Act - 11回目は制限エラー
        final limitResult = await subscriptionService.incrementAiUsage();
        final canUseResult = await subscriptionService.canUseAiGeneration();

        // Assert
        expect(limitResult.isFailure, isTrue);
        expect(
          limitResult.error.toString(),
          contains('Monthly AI generation limit reached'),
        );
        expect(canUseResult.value, isFalse); // 制限に達したので使用不可
      });
    });

    group('プラン比較統合テスト', () {
      setUp(() async {
        subscriptionService = await SubscriptionService.getInstance();
      });

      test('Basic vs Premium プラン機能比較', () async {
        // Basic プランのテスト
        final basicPlan = BasicPlan();
        await subscriptionService.createStatusClass(basicPlan);

        var featureResult = await subscriptionService.getFeatureAccess();
        expect(featureResult.isSuccess, isTrue);
        var features = featureResult.value;
        expect(features['premiumFeatures'], isFalse);
        expect(features['writingPrompts'], isTrue);
        expect(features['advancedFilters'], isFalse);
        expect(features['dataExport'], isTrue);
        expect(features['statsDashboard'], isFalse);

        // Premium プランのテスト
        final premiumYearlyPlan = PremiumYearlyPlan();
        await subscriptionService.createStatusClass(premiumYearlyPlan);

        featureResult = await subscriptionService.getFeatureAccess();
        expect(featureResult.isSuccess, isTrue);
        features = featureResult.value;
        expect(features['premiumFeatures'], isTrue);
        expect(features['writingPrompts'], isTrue);
        expect(features['advancedFilters'], isTrue);
        expect(features['dataExport'], isTrue);
        expect(features['statsDashboard'], isTrue);
      });

      test('全機能のアクセス権限チェック', () async {
        // Premium月額プランで全機能テスト
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        await subscriptionService.createStatusClass(premiumMonthlyPlan);

        final premiumFeaturesResult = await subscriptionService
            .canAccessPremiumFeatures();
        final writingPromptsResult = await subscriptionService
            .canAccessWritingPrompts();
        final advancedFiltersResult = await subscriptionService
            .canAccessAdvancedFilters();
        final dataExportResult = await subscriptionService
            .canAccessDataExport();
        final statsDashboardResult = await subscriptionService
            .canAccessStatsDashboard();

        expect(premiumFeaturesResult.value, isTrue);
        expect(writingPromptsResult.value, isTrue);
        expect(advancedFiltersResult.value, isTrue);
        expect(dataExportResult.value, isTrue);
        expect(statsDashboardResult.value, isTrue);
      });
    });

    group('ファサード内部状態確認', () {
      test('ファサードが正しく初期化される', () async {
        // Act
        subscriptionService = await SubscriptionService.getInstance();

        // Assert
        expect(subscriptionService.isInitialized, isTrue);
        expect(subscriptionService.subscriptionBox, isNotNull);
        expect(subscriptionService.subscriptionBox!.isOpen, isTrue);
      });

      test('resetForTesting()でファサードインスタンスがリセットされる', () async {
        // Arrange
        final instance1 = await SubscriptionService.getInstance();

        // Act
        SubscriptionService.resetForTesting();
        final instance2 = await SubscriptionService.getInstance();

        // Assert
        expect(instance1, isNot(same(instance2)));
        expect(instance2.isInitialized, isTrue);
      });

      test('各マネージャーが正しく初期化される', () async {
        // Act
        subscriptionService = await SubscriptionService.getInstance();

        // Assert - ファサードが正しく動作していることを間接的に確認
        final statusResult = await subscriptionService.getCurrentStatus();
        final canUseResult = await subscriptionService.canUseAiGeneration();
        final featuresResult = await subscriptionService.getFeatureAccess();

        expect(statusResult.isSuccess, isTrue);
        expect(canUseResult.isSuccess, isTrue);
        expect(featuresResult.isSuccess, isTrue);
      });
    });
  });
}
