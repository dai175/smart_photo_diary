import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/settings_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import '../../mocks/mock_subscription_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsService V2メソッドテスト', () {
    late SettingsService settingsService;
    late MockSubscriptionService mockSubscriptionService;

    setUpAll(() async {
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
    });

    setUp(() async {
      // 完全なリセット
      ServiceLocator().clear();
      SettingsService.resetInstance();
    });

    tearDown(() async {
      ServiceLocator().clear();
    });

    test('getSubscriptionInfoV2()でV2形式の情報を取得できる', () async {
      // Basicプランの状態を設定
      mockSubscriptionService = MockSubscriptionService();
      mockSubscriptionService.setCurrentStatus(
        SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          monthlyUsageCount: 5,
          lastResetDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      );
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      final result = await settingsService.getSubscriptionInfoV2();

      expect(result.isSuccess, true);
      final info = result.value;
      expect(info.currentPlan, isA<BasicPlan>());
      expect(info.currentPlan.id, 'basic');
      expect(info.usageStats.monthlyUsageCount, 5);
      expect(info.usageStats.monthlyLimit, 10);
    });

    test('getCurrentPlanClass()でPlanクラスを取得できる', () async {
      // Premiumプランの状態を設定
      mockSubscriptionService = MockSubscriptionService();
      mockSubscriptionService.setCurrentStatus(
        SubscriptionStatus(planId: 'premium_monthly', isActive: true),
      );
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      final result = await settingsService.getCurrentPlanClass();

      expect(result.isSuccess, true);
      final plan = result.value;
      expect(plan, isA<PremiumMonthlyPlan>());
      expect(plan.id, 'premium_monthly');
      expect(plan.isPremium, true);
    });

    test('getUsageStatisticsWithPlanClass()でV2形式の統計を取得できる', () async {
      // 使用量の多い状態を設定
      mockSubscriptionService = MockSubscriptionService();
      mockSubscriptionService.setCurrentStatus(
        SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          monthlyUsageCount: 8,
          lastResetDate: DateTime.now(),
        ),
      );
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      final result = await settingsService.getUsageStatisticsWithPlanClass();

      expect(result.isSuccess, true);
      final stats = result.value;
      expect(stats.monthlyUsageCount, 8);
      expect(stats.monthlyLimit, 10);
      expect(stats.remainingCount, 2);
      expect(stats.isNearLimit, true); // 80%以上
      expect(stats.usageRate, 0.8);
      expect(stats.usageDisplay, '8 / 10回');
    });

    test('getPlanPeriodInfoV2()でV2形式の期限情報を取得できる', () async {
      // 期限間近のPremiumプラン
      final expiryDate = DateTime.now().add(const Duration(days: 5));
      mockSubscriptionService = MockSubscriptionService();
      mockSubscriptionService.setCurrentStatus(
        SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          startDate: DateTime.now().subtract(const Duration(days: 25)),
          expiryDate: expiryDate,
          autoRenewal: true,
        ),
      );
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      final result = await settingsService.getPlanPeriodInfoV2();

      expect(result.isSuccess, true);
      final periodInfo = result.value;
      expect(periodInfo.expiryDate, expiryDate);
      expect(periodInfo.isExpiryNear, true);
      expect(periodInfo.isExpired, false);
      expect(periodInfo.autoRenewal, true);
      expect(periodInfo.daysUntilExpiry, lessThanOrEqualTo(7));
    });

    test('getAvailablePlansV2()でPlanクラスのリストを取得できる', () async {
      // MockSubscriptionServiceを設定
      mockSubscriptionService = MockSubscriptionService();
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      final result = await settingsService.getAvailablePlansV2();

      expect(result.isSuccess, true);
      final plans = result.value;
      expect(plans.length, 3);

      // 各プランの型チェック
      expect(plans.any((p) => p is BasicPlan), true);
      expect(plans.any((p) => p is PremiumMonthlyPlan), true);
      expect(plans.any((p) => p.id == 'premium_yearly'), true);
    });

    test('V2メソッドとレガシーメソッドの互換性', () async {
      // 同じ状態を設定
      mockSubscriptionService = MockSubscriptionService();
      mockSubscriptionService.setCurrentStatus(
        SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          monthlyUsageCount: 30,
        ),
      );
      await mockSubscriptionService.initialize();
      ServiceLocator().registerSingleton<ISubscriptionService>(
        mockSubscriptionService,
      );

      // SettingsServiceを初期化
      settingsService = await SettingsService.getInstance();

      // V2メソッド
      final v2PlanResult = await settingsService.getCurrentPlanClass();
      final v2StatsResult = await settingsService
          .getUsageStatisticsWithPlanClass();

      // V2メソッドが成功すること
      expect(v2PlanResult.isSuccess, true);
      expect(v2StatsResult.isSuccess, true);

      // MockServiceで設定されたプランが取得できること
      expect(v2PlanResult.value.id, equals('premium_monthly'));

      // MockServiceで設定された統計データが取得できること
      expect(v2StatsResult.value.monthlyUsageCount, equals(30));
      expect(v2StatsResult.value.monthlyLimit, equals(100)); // PremiumMonthlyPlanの制限
    });
  });
}
