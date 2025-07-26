import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/models/subscription_info.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/plan_factory.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import '../../../test/mocks/mock_subscription_service.dart';

/// SettingsService - Phase 1.8.1 サブスクリプション状態管理APIのテスト
///
/// 実装内容:
/// - 1.8.1.1: SettingsServiceにサブスクリプション情報取得API追加
/// - 1.8.1.2: 購入日・期限情報管理機能実装
/// - 1.8.1.3: 自動更新状態管理機能実装
/// - 1.8.1.4: 設定画面用データ提供API実装
void main() {
  group('SettingsService - Phase 1.8.1 サブスクリプション状態管理', () {
    late MockSubscriptionService mockSubscriptionService;
    late SettingsService settingsService;

    setUpAll(() async {
      // Flutter binding初期化
      TestWidgetsFlutterBinding.ensureInitialized();

      // SharedPreferencesのプラットフォームチャンネルをモック
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (MethodCall methodCall) async {
              if (methodCall.method == 'getAll') {
                return <String, Object>{}; // 空の設定を返す
              }
              return null;
            },
          );

      // ServiceLocatorのリセット
      ServiceLocator().clear();

      // MockSubscriptionServiceの登録
      mockSubscriptionService = MockSubscriptionService();
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceの取得
      settingsService = await SettingsService.getInstance();
    });

    tearDown(() async {
      // テスト間でモックをリセット
      mockSubscriptionService.resetToDefaults();
      // リセット後に再初期化
      await mockSubscriptionService.initialize();
    });

    tearDownAll(() {
      ServiceLocator().clear();
    });

    group('Phase 1.8.1.1: サブスクリプション情報取得API', () {
      test('getSubscriptionInfo()で包括的な情報を取得できる', () async {
        // Act
        final result = await settingsService.getSubscriptionInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final info = result.value;
        expect(info, isA<SubscriptionInfo>());
        expect(info.currentPlan, equals(SubscriptionPlan.basic));
        expect(info.isActive, isTrue);
        expect(info.isPremium, isFalse);
        expect(info.planDisplayName, equals('Basic'));
      });

      test('getCurrentPlan()で現在のプランを取得できる', () async {
        // Act
        final result = await settingsService.getCurrentPlan();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(SubscriptionPlan.basic));
      });

      test('Premiumプランでも正しく情報を取得できる', () async {
        // Arrange
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        mockSubscriptionService.setCurrentPlan(premiumMonthlyPlan);

        // Act
        final result = await settingsService.getSubscriptionInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final info = result.value;
        expect(info.currentPlan, equals(SubscriptionPlan.premiumMonthly));
        expect(info.isPremium, isTrue);
        expect(info.planDisplayName, equals('Premium (月額)'));
      });
    });

    group('Phase 1.8.1.2: 購入日・期限情報管理', () {
      test('getPlanPeriodInfo()でBasicプランの期限情報を取得できる', () async {
        // Act
        final result = await settingsService.getPlanPeriodInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final periodInfo = result.value;
        expect(periodInfo.startDate, isNotNull);
        expect(periodInfo.expiryDate, isNull); // Basicプランは期限なし
        expect(periodInfo.nextRenewalDate, isNull);
        expect(periodInfo.daysUntilExpiry, isNull);
        expect(periodInfo.isExpiryNear, isFalse);
      });

      test('Premiumプランで期限情報を正しく取得できる', () async {
        // Arrange
        final now = DateTime.now();
        final expiryDate = now.add(const Duration(days: 30));

        final premiumMonthlyPlan = PremiumMonthlyPlan();
        mockSubscriptionService.setCurrentPlan(premiumMonthlyPlan);
        mockSubscriptionService.setExpiryDate(expiryDate);

        // Act
        final result = await settingsService.getPlanPeriodInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final periodInfo = result.value;
        expect(periodInfo.expiryDate, isNotNull);
        expect(periodInfo.daysUntilExpiry, greaterThan(0));
        expect(periodInfo.isExpiryNear, isFalse);
      });

      test('期限が近い場合に警告フラグが正しく設定される', () async {
        // Arrange
        final now = DateTime.now();
        final expiryDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 5)); // 5日後

        final premiumMonthlyPlan2 = PremiumMonthlyPlan();
        mockSubscriptionService.setCurrentPlan(premiumMonthlyPlan2);
        mockSubscriptionService.setExpiryDate(expiryDate);

        // Act
        final result = await settingsService.getPlanPeriodInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final periodInfo = result.value;
        expect(periodInfo.isExpiryNear, isTrue); // 7日以内なので警告
        expect(periodInfo.daysUntilExpiry, lessThanOrEqualTo(5));
        expect(periodInfo.daysUntilExpiry, greaterThanOrEqualTo(4));
      });
    });

    group('Phase 1.8.1.3: 自動更新状態管理', () {
      test('getAutoRenewalInfo()で自動更新情報を取得できる', () async {
        // Act
        final result = await settingsService.getAutoRenewalInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final autoRenewalInfo = result.value;
        expect(
          autoRenewalInfo.isAutoRenewalEnabled,
          isFalse,
        ); // Basicプランは自動更新なし
        expect(autoRenewalInfo.autoRenewalDescription, contains('無効'));
        expect(autoRenewalInfo.statusDisplay, equals('無効'));
      });

      test('自動更新有効時の情報を正しく取得できる', () async {
        // Arrange
        final premiumMonthlyPlan3 = PremiumMonthlyPlan();
        mockSubscriptionService.setCurrentPlan(premiumMonthlyPlan3);
        mockSubscriptionService.setAutoRenewal(true);

        // Act
        final result = await settingsService.getAutoRenewalInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final autoRenewalInfo = result.value;
        expect(autoRenewalInfo.isAutoRenewalEnabled, isTrue);
        expect(autoRenewalInfo.autoRenewalDescription, contains('有効'));
        expect(autoRenewalInfo.statusDisplay, equals('有効'));
        expect(autoRenewalInfo.managementUrl, isNotNull);
      });
    });

    group('Phase 1.8.1.4: 設定画面用データ提供API', () {
      test('getUsageStatistics()で使用量統計を取得できる', () async {
        // Arrange
        mockSubscriptionService.setUsageCount(3);

        // Act
        final result = await settingsService.getUsageStatistics();

        // Assert
        expect(result.isSuccess, isTrue);

        final usageStats = result.value;
        expect(usageStats.currentMonthUsage, equals(3));
        expect(usageStats.monthlyLimit, equals(10)); // Basicプランの制限
        expect(usageStats.remainingCount, equals(7));
        expect(usageStats.usageRate, equals(0.3));
        expect(usageStats.isNearLimit, isFalse);
        expect(usageStats.usageDisplay, equals('3/10回'));
        expect(usageStats.usageRateDisplay, equals('30%'));
      });

      test('制限に近い使用量で警告フラグが設定される', () async {
        // Arrange
        mockSubscriptionService.setUsageCount(9); // 90%使用

        // Act
        final result = await settingsService.getUsageStatistics();

        // Assert
        expect(result.isSuccess, isTrue);

        final usageStats = result.value;
        expect(usageStats.isNearLimit, isTrue);
        expect(usageStats.usageRate, greaterThanOrEqualTo(0.8));
      });

      test('getRemainingGenerations()で残り回数を取得できる', () async {
        // Arrange
        mockSubscriptionService.setUsageCount(4);

        // Act
        final result = await settingsService.getRemainingGenerations();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, equals(6)); // 10 - 4 = 6
      });

      test('getNextResetDate()で次回リセット日を取得できる', () async {
        // Act
        final result = await settingsService.getNextResetDate();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<DateTime>());
      });

      test('canChangePlan()でプラン変更可否を確認できる', () async {
        // Act
        final result = await settingsService.canChangePlan();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isTrue); // 初期化済みなので変更可能
      });

      test('getAvailablePlans()で利用可能プラン一覧を取得できる', () async {
        // Act
        final result = await settingsService.getAvailablePlansV2();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.value, isA<List<Plan>>());
        expect(result.value.length, equals(3)); // Basic, Premium月額, Premium年額
      });
    });

    group('エラーハンドリング', () {
      test('正常にサービスが動作することを確認', () async {
        // シンプルなテスト: エラーハンドリングの詳細テストは除外
        final result = await settingsService.getSubscriptionInfo();
        expect(result.isSuccess, isTrue);
      });
    });

    group('データ変換テスト', () {
      test('SubscriptionInfo.fromStatus()でデータ変換が正しく行われる', () async {
        // Arrange
        final premiumMonthlyPlan4 = PremiumMonthlyPlan();
        mockSubscriptionService.setCurrentPlan(premiumMonthlyPlan4);
        mockSubscriptionService.setUsageCount(25);

        // Act
        final result = await settingsService.getSubscriptionInfo();

        // Assert
        expect(result.isSuccess, isTrue);

        final info = result.value;
        expect(info.currentPlan, equals(SubscriptionPlan.premiumMonthly));
        expect(info.usageStats.currentMonthUsage, equals(25));
        expect(info.usageStats.monthlyLimit, equals(100)); // Premiumプランの制限
        expect(info.planFeatures, isNotEmpty);
      });
    });
  });
}
