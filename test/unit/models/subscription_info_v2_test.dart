import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/subscription_info_v2.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';

void main() {
  group('UsageStatisticsV2', () {
    test('fromStatusAndPlanで正しく構築される', () {
      final plan = BasicPlan();
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime(2026, 1, 1),
        monthlyUsageCount: 3,
      );

      final stats = UsageStatisticsV2.fromStatusAndPlan(status, plan);

      expect(stats.monthlyUsageCount, 3);
      expect(stats.monthlyLimit, plan.monthlyAiGenerationLimit);
      expect(stats.remainingCount, plan.monthlyAiGenerationLimit - 3);
    });

    test('usageRate → 使用率が正しく計算される', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 5,
        monthlyLimit: 10,
        remainingCount: 5,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 1.0,
      );

      expect(stats.usageRate, 0.5);
    });

    test('monthlyLimit=0の場合usageRateは0.0', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 0,
        monthlyLimit: 0,
        remainingCount: 0,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 0.0,
      );

      expect(stats.usageRate, 0.0);
    });

    test('isNearLimit → 80%以上で残りありの場合true', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 8,
        monthlyLimit: 10,
        remainingCount: 2,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 1.0,
      );

      expect(stats.isNearLimit, isTrue);
    });

    test('isNearLimit → 80%未満の場合false', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 3,
        monthlyLimit: 10,
        remainingCount: 7,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 1.0,
      );

      expect(stats.isNearLimit, isFalse);
    });

    test('isNearLimit → 残り0の場合false', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 10,
        monthlyLimit: 10,
        remainingCount: 0,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 1.0,
      );

      expect(stats.isNearLimit, isFalse);
    });

    test('getLocalizedUsageDisplay → フォーマッタが正しく適用される', () {
      final stats = UsageStatisticsV2(
        monthlyUsageCount: 3,
        monthlyLimit: 10,
        remainingCount: 7,
        nextResetDate: DateTime(2026, 3, 1),
        dailyAverageLimit: 1.0,
      );

      final display = stats.getLocalizedUsageDisplay(
        (used, limit) => '$used/$limit回使用済み',
      );

      expect(display, '3/10回使用済み');
    });

    test('remainingCountは負にならない', () {
      final plan = BasicPlan();
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime(2026, 1, 1),
        monthlyUsageCount: 999,
      );

      final stats = UsageStatisticsV2.fromStatusAndPlan(status, plan);

      expect(stats.remainingCount, 0);
    });

    test('12月のnextResetDateは翌年1月1日', () {
      final plan = BasicPlan();
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime(2025, 12, 15),
        lastResetDate: DateTime(2025, 12, 15),
      );

      final stats = UsageStatisticsV2.fromStatusAndPlan(status, plan);

      expect(stats.nextResetDate, DateTime(2026, 1, 1));
    });

    test('lastResetDateがnullの場合は現在日付ベースで計算', () {
      final plan = BasicPlan();
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime(2026, 1, 1),
      );

      final stats = UsageStatisticsV2.fromStatusAndPlan(status, plan);

      expect(stats.nextResetDate, isNotNull);
    });
  });

  group('AutoRenewalInfoV2', () {
    test('自動更新有効 → 説明とURLが設定される', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        autoRenewal: true,
      );

      final info = AutoRenewalInfoV2.fromStatus(status);

      expect(info.isAutoRenewalEnabled, isTrue);
      expect(info.managementUrl, isNotNull);
      expect(info.autoRenewalDescription, contains('有効'));
    });

    test('自動更新無効 → URLがnull', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        autoRenewal: false,
      );

      final info = AutoRenewalInfoV2.fromStatus(status);

      expect(info.isAutoRenewalEnabled, isFalse);
      expect(info.managementUrl, isNull);
      expect(info.autoRenewalDescription, contains('無効'));
    });
  });

  group('PlanPeriodInfoV2', () {
    test('有効期限ありのPremium → daysUntilExpiryが正しく計算', () {
      final plan = PremiumMonthlyPlan();
      final futureDate = DateTime.now().add(const Duration(days: 30));
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: futureDate,
      );

      final info = PlanPeriodInfoV2.fromStatusAndPlan(status, plan);

      expect(info.daysUntilExpiry, greaterThanOrEqualTo(29));
      expect(info.isExpired, isFalse);
      expect(info.isExpiryNear, isFalse);
    });

    test('期限切れ → isExpiredがtrue', () {
      final plan = PremiumMonthlyPlan();
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: false,
        startDate: DateTime.now().subtract(const Duration(days: 35)),
        expiryDate: pastDate,
      );

      final info = PlanPeriodInfoV2.fromStatusAndPlan(status, plan);

      expect(info.isExpired, isTrue);
    });

    test('期限まで7日以内 → isExpiryNearがtrue', () {
      final plan = PremiumMonthlyPlan();
      final nearDate = DateTime.now().add(const Duration(days: 3));
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 27)),
        expiryDate: nearDate,
      );

      final info = PlanPeriodInfoV2.fromStatusAndPlan(status, plan);

      expect(info.isExpiryNear, isTrue);
    });

    test('期限なし(Basic) → daysUntilExpiryがnull', () {
      final plan = BasicPlan();
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );

      final info = PlanPeriodInfoV2.fromStatusAndPlan(status, plan);

      expect(info.daysUntilExpiry, isNull);
      expect(info.isExpiryNear, isFalse);
      expect(info.isExpired, isFalse);
    });
  });

  group('SubscriptionInfoV2', () {
    test('fromStatusでBasicプラン情報が正しく構築される', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime(2026, 1, 1),
        monthlyUsageCount: 2,
      );

      final info = SubscriptionInfoV2.fromStatus(status);

      expect(info.isActive, isTrue);
      expect(info.isPremium, isFalse);
      expect(info.currentPlan, isA<BasicPlan>());
      expect(info.usageStats.monthlyUsageCount, 2);
    });

    test('fromStatusAndPlanで正しく構築される', () {
      final plan = PremiumMonthlyPlan();
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );

      final info = SubscriptionInfoV2.fromStatusAndPlan(status, plan);

      expect(info.isPremium, isTrue);
      expect(info.currentPlan, plan);
    });

    test('getLocalizedPlanDisplayName → jaの場合日本語', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      expect(info.getLocalizedPlanDisplayName('ja'), 'ベーシック');
      expect(info.getLocalizedPlanDisplayName('en'), 'Basic');
    });

    test('getLocalizedPlanDisplayName → premium_monthly', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      expect(info.getLocalizedPlanDisplayName('ja'), 'プレミアム（月額）');
      expect(info.getLocalizedPlanDisplayName('en'), 'Premium (monthly)');
    });

    test('planFeatures → プランの機能リスト', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      expect(info.planFeatures, isNotEmpty);
    });

    test('getLocalizedUsageWarningMessage → 制限に近い場合メッセージあり', () {
      final plan = BasicPlan();
      final limit = plan.monthlyAiGenerationLimit;
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
        monthlyUsageCount: (limit * 0.9).toInt(),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      final message = info.getLocalizedUsageWarningMessage(
        () => '制限に達しました',
        (remaining) => 'あと$remaining回',
      );

      if (info.usageStats.isNearLimit) {
        expect(message, isNotNull);
      }
    });

    test('getLocalizedUsageWarningMessage → 余裕がある場合null', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
        monthlyUsageCount: 1,
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      final message = info.getLocalizedUsageWarningMessage(
        () => '制限に達しました',
        (remaining) => 'あと$remaining回',
      );

      expect(message, isNull);
    });

    test('getLocalizedPlanRecommendationMessage → Premiumはnull', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      final message = info.getLocalizedPlanRecommendationMessage(
        (limit) => 'プレミアムに$limit回',
        () => 'アップグレード推奨',
      );

      expect(message, isNull);
    });

    test('getLocalizedPlanRecommendationMessage → Basic使用率高い場合メッセージあり', () {
      final plan = BasicPlan();
      final limit = plan.monthlyAiGenerationLimit;
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
        monthlyUsageCount: (limit * 0.85).toInt(),
      );
      final info = SubscriptionInfoV2.fromStatus(status);

      final message = info.getLocalizedPlanRecommendationMessage(
        (l) => 'プレミアムに$l回',
        () => 'アップグレード推奨',
      );

      expect(message, isNotNull);
    });
  });
}
