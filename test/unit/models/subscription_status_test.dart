import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_photo_diary/models/subscription_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';

void main() {
  group('SubscriptionStatus', () {
    late Box<SubscriptionStatus> testBox;
    
    setUpAll(() async {
      // テスト用のHive初期化
      Hive.init('./test/temp');
      Hive.registerAdapter(SubscriptionStatusAdapter());
    });

    setUp(() async {
      // 各テスト前にテスト用Boxを作成
      testBox = await Hive.openBox<SubscriptionStatus>('test_subscription');
    });

    tearDown(() async {
      // 各テスト後にBoxをクリア
      await testBox.clear();
      await testBox.close();
    });

    tearDownAll(() async {
      // 全テスト終了後にHiveをクリア
      await Hive.deleteFromDisk();
    });

    group('基本的な初期化テスト', () {
      test('デフォルトコンストラクタで正しく初期化される', () {
        final status = SubscriptionStatus();
        
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.monthlyUsageCount, equals(0));
        expect(status.autoRenewal, isFalse);
        expect(status.currentPlan, equals(SubscriptionPlan.basic));
      });

      test('createDefaultで正しいデフォルト状態が作成される', () {
        final status = SubscriptionStatus.createDefault();
        
        expect(status.planId, equals('basic'));
        expect(status.isActive, isTrue);
        expect(status.currentPlan, equals(SubscriptionPlan.basic));
        expect(status.monthlyUsageCount, equals(0));
        expect(status.autoRenewal, isFalse);
        expect(status.startDate, isNotNull);
      });

      test('createPremiumで正しいPremium状態が作成される', () {
        final startDate = DateTime.now();
        final status = SubscriptionStatus.createPremium(
          startDate: startDate,
          plan: SubscriptionPlan.premiumYearly,
          transactionId: 'test_transaction',
        );
        
        expect(status.planId, equals('premium_yearly'));
        expect(status.isActive, isTrue);
        expect(status.currentPlan, equals(SubscriptionPlan.premiumYearly));
        expect(status.startDate, equals(startDate));
        expect(status.expiryDate, equals(startDate.add(const Duration(days: 365))));
        expect(status.autoRenewal, isTrue);
        expect(status.transactionId, equals('test_transaction'));
        expect(status.lastPurchaseDate, equals(startDate));
      });
    });

    group('プラン管理テスト', () {
      test('currentPlanが正しく取得される', () {
        final basicStatus = SubscriptionStatus(planId: 'basic');
        final premiumStatus = SubscriptionStatus(planId: 'premium_yearly');
        
        expect(basicStatus.currentPlan, equals(SubscriptionPlan.basic));
        expect(premiumStatus.currentPlan, equals(SubscriptionPlan.premiumYearly));
      });

      test('不正なプランIDでもBasicにフォールバックする', () {
        final status = SubscriptionStatus(planId: 'invalid_plan');
        
        expect(status.currentPlan, equals(SubscriptionPlan.basic));
      });

      test('changePlanでプランが正しく変更される', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);
        
        status.changePlan(SubscriptionPlan.premiumYearly);
        
        expect(status.planId, equals('premium_yearly'));
        expect(status.currentPlan, equals(SubscriptionPlan.premiumYearly));
        expect(status.isActive, isTrue);
        expect(status.autoRenewal, isTrue);
        expect(status.startDate, isNotNull);
        expect(status.expiryDate, isNotNull);
      });

      test('BasicプランへのchangePlanで期限がクリアされる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);
        
        status.changePlan(SubscriptionPlan.basic);
        
        expect(status.planId, equals('basic'));
        expect(status.currentPlan, equals(SubscriptionPlan.basic));
        expect(status.expiryDate, isNull);
        expect(status.autoRenewal, isFalse);
      });
    });

    group('有効性チェックテスト', () {
      test('Basicプランは常に有効', () {
        final status = SubscriptionStatus.createDefault();
        
        expect(status.isValid, isTrue);
        expect(status.isExpired, isFalse);
      });

      test('有効なPremiumプランは有効', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: futureDate,
        );
        
        expect(status.isValid, isTrue);
        expect(status.isExpired, isFalse);
      });

      test('期限切れのPremiumプランは無効', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: pastDate,
        );
        
        expect(status.isValid, isFalse);
        expect(status.isExpired, isTrue);
      });

      test('非アクティブなプランは無効', () {
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: false,
          expiryDate: DateTime.now().add(const Duration(days: 30)),
        );
        
        expect(status.isValid, isFalse);
      });
    });

    group('使用量管理テスト', () {
      test('初期状態では使用量制限に達していない', () {
        final status = SubscriptionStatus.createDefault();
        
        expect(status.hasReachedMonthlyLimit, isFalse);
        expect(status.canUseAiGeneration, isTrue);
        expect(status.remainingGenerations, equals(10)); // Basic plan limit
      });

      test('使用量をインクリメントできる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);
        
        expect(status.monthlyUsageCount, equals(0));
        
        status.incrementAiUsage();
        expect(status.monthlyUsageCount, equals(1));
        expect(status.remainingGenerations, equals(9));
        
        status.incrementAiUsage();
        expect(status.monthlyUsageCount, equals(2));
        expect(status.remainingGenerations, equals(8));
      });

      test('制限に達すると使用できなくなる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);
        
        // Basic plan limit (10) まで使用
        for (int i = 0; i < 10; i++) {
          status.incrementAiUsage();
        }
        
        expect(status.hasReachedMonthlyLimit, isTrue);
        expect(status.canUseAiGeneration, isFalse);
        expect(status.remainingGenerations, equals(0));
      });

      test('使用量をリセットできる', () async {
        final status = SubscriptionStatus.createDefault();
        await testBox.add(status);
        
        // 使用量を増やす
        for (int i = 0; i < 5; i++) {
          status.incrementAiUsage();
        }
        expect(status.monthlyUsageCount, equals(5));
        
        status.resetUsage();
        expect(status.monthlyUsageCount, equals(0));
        expect(status.remainingGenerations, equals(10));
        expect(status.lastResetDate, isNotNull);
      });

      test('Premiumプランでは制限が異なる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);
        
        expect(status.remainingGenerations, equals(100)); // Premium plan limit
        
        // 使用量をインクリメント
        status.incrementAiUsage();
        expect(status.remainingGenerations, equals(99));
      });
    });

    group('アクセス権限チェックテスト', () {
      test('Basicプランではプレミアム機能にアクセスできない', () {
        final status = SubscriptionStatus.createDefault();
        
        expect(status.canAccessPremiumFeatures, isFalse);
        expect(status.canAccessWritingPrompts, isFalse);
        expect(status.canAccessAdvancedFilters, isFalse);
        expect(status.canAccessAdvancedAnalytics, isFalse);
      });

      test('有効なPremiumプランではプレミアム機能にアクセスできる', () {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        
        expect(status.canAccessPremiumFeatures, isTrue);
        expect(status.canAccessWritingPrompts, isTrue);
        expect(status.canAccessAdvancedFilters, isTrue);
        expect(status.canAccessAdvancedAnalytics, isTrue);
      });

      test('期限切れのPremiumプランではプレミアム機能にアクセスできない', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          expiryDate: pastDate,
        );
        
        expect(status.canAccessPremiumFeatures, isFalse);
        expect(status.canAccessWritingPrompts, isFalse);
        expect(status.canAccessAdvancedFilters, isFalse);
        expect(status.canAccessAdvancedAnalytics, isFalse);
      });
    });

    group('キャンセル・復元テスト', () {
      test('サブスクリプションをキャンセルできる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);
        
        expect(status.isActive, isTrue);
        expect(status.cancelDate, isNull);
        
        status.cancel();
        
        expect(status.isActive, isFalse);
        expect(status.autoRenewal, isFalse);
        expect(status.cancelDate, isNotNull);
        expect(status.planId, equals('basic'));
      });

      test('将来の日付でキャンセル予約できる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);
        
        final futureDate = DateTime.now().add(const Duration(days: 7));
        status.cancel(effectiveDate: futureDate);
        
        expect(status.isActive, isTrue); // まだアクティブ
        expect(status.autoRenewal, isFalse);
        expect(status.cancelDate, equals(futureDate));
      });

      test('サブスクリプションを復元できる', () async {
        final status = SubscriptionStatus.createPremium(
          startDate: DateTime.now(),
          plan: SubscriptionPlan.premiumYearly,
        );
        await testBox.add(status);
        
        status.cancel();
        expect(status.isActive, isFalse);
        
        status.restore();
        expect(status.isActive, isTrue);
        expect(status.cancelDate, isNull);
      });
    });

    group('日付計算テスト', () {
      test('nextResetDateが正しく計算される', () {
        final status = SubscriptionStatus.createDefault();
        final nextReset = status.nextResetDate;
        final now = DateTime.now();
        final expectedNextMonth = DateTime(now.year, now.month + 1, 1);
        
        expect(nextReset.year, equals(expectedNextMonth.year));
        expect(nextReset.month, equals(expectedNextMonth.month));
        expect(nextReset.day, equals(1));
      });

      test('期限までの残り日数が正しく計算される', () {
        final futureDate = DateTime.now().add(const Duration(days: 30));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          expiryDate: futureDate,
        );
        
        final daysUntilExpiry = status.daysUntilExpiry;
        expect(daysUntilExpiry, isNotNull);
        expect(daysUntilExpiry!, greaterThanOrEqualTo(29));
        expect(daysUntilExpiry, lessThanOrEqualTo(30));
      });

      test('期限切れの場合は0日が返される', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          expiryDate: pastDate,
        );
        
        expect(status.daysUntilExpiry, equals(0));
      });

      test('期限がない場合はnullが返される', () {
        final status = SubscriptionStatus.createDefault();
        
        expect(status.daysUntilExpiry, isNull);
      });
    });

    group('toStringテスト', () {
      test('toStringが正しい情報を含む', () {
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
          monthlyUsageCount: 5,
        );
        
        final string = status.toString();
        expect(string, contains('planId: premium_yearly'));
        expect(string, contains('isActive: true'));
        expect(string, contains('monthlyUsageCount: 5/100'));
      });
    });
  });
}