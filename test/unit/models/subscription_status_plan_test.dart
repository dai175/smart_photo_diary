import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';

void main() {
  group('SubscriptionStatus - Plan統合機能', () {
    group('copyWithPlan', () {
      test('新しいPlanで正しくコピーが作成される', () {
        final originalStatus = SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          startDate: DateTime(2025, 1, 1),
          expiryDate: DateTime(2025, 12, 31),
          monthlyUsageCount: 5,
          lastResetDate: DateTime(2025, 1, 1),
          autoRenewal: false,
          transactionId: 'trans_123',
          lastPurchaseDate: DateTime(2025, 1, 1),
        );

        final newPlan = PremiumMonthlyPlan();
        final newStatus = originalStatus.copyWith(planId: newPlan.id);

        // Plan IDが変更されていることを確認
        expect(newStatus.planId, 'premium_monthly');

        // その他のプロパティが保持されていることを確認
        expect(newStatus.isActive, originalStatus.isActive);
        expect(newStatus.startDate, originalStatus.startDate);
        expect(newStatus.expiryDate, originalStatus.expiryDate);
        expect(newStatus.monthlyUsageCount, originalStatus.monthlyUsageCount);
        expect(newStatus.lastResetDate, originalStatus.lastResetDate);
        expect(newStatus.autoRenewal, originalStatus.autoRenewal);
        expect(newStatus.transactionId, originalStatus.transactionId);
        expect(newStatus.lastPurchaseDate, originalStatus.lastPurchaseDate);
      });

      test('各プランタイプで正しく動作する', () {
        final status = SubscriptionStatus(planId: 'basic', isActive: true);

        final plans = [BasicPlan(), PremiumMonthlyPlan(), PremiumYearlyPlan()];

        for (final plan in plans) {
          final newStatus = status.copyWith(planId: plan.id);
          expect(newStatus.planId, plan.id);
          // currentPlanのenumプロパティは削除されたため、Planクラスで検証
          final planClass = newStatus.currentPlanClass;
          expect(planClass.id, plan.id);
        }
      });
    });

    group('getCurrentPlanClass', () {
      test('正しいPlanクラスインスタンスを返す', () {
        final basicStatus = SubscriptionStatus(planId: 'basic', isActive: true);
        final monthlyStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
        );
        final yearlyStatus = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
        );

        expect(basicStatus.currentPlanClass, isA<BasicPlan>());
        expect(monthlyStatus.currentPlanClass, isA<PremiumMonthlyPlan>());
        expect(yearlyStatus.currentPlanClass, isA<PremiumYearlyPlan>());
      });

      test('プランIDに対応する正しいプロパティを持つ', () {
        final status = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
        );

        final plan = status.currentPlanClass;

        expect(plan.id, 'premium_yearly');
        expect(plan.price, 2800);
        expect(plan.monthlyAiGenerationLimit, 100);
        expect(plan.isPremium, true);
      });
    });

    group('Plan互換性', () {
      test('Planクラスの整合性', () {
        final statuses = [
          SubscriptionStatus(planId: 'basic', isActive: true),
          SubscriptionStatus(planId: 'premium_monthly', isActive: true),
          SubscriptionStatus(planId: 'premium_yearly', isActive: true),
        ];

        for (final status in statuses) {
          // Planクラスのプロパティを検証
          final classPlan = status.currentPlanClass;

          // Planクラスの基本プロパティを検証
          expect(classPlan.id, status.planId);
          expect(classPlan.price, isA<int>());
          expect(classPlan.monthlyAiGenerationLimit, isA<int>());
          expect(classPlan.isPremium, isA<bool>());
          expect(classPlan.hasWritingPrompts, isA<bool>());
          expect(classPlan.hasAdvancedFilters, isA<bool>());
          expect(classPlan.hasAdvancedAnalytics, isA<bool>());
          expect(classPlan.hasPrioritySupport, isA<bool>());
        }
      });

      test('無効なプランIDに対するエラーハンドリング', () {
        // 無効なプランIDの場合、planIdはそのまま保持される
        final invalidStatus = SubscriptionStatus(
          planId: 'invalid_plan',
          isActive: true,
        );

        // planIdはそのまま保持される
        expect(invalidStatus.planId, 'invalid_plan');

        // currentPlanClass ゲッターは不正なプランIDに対してBasicPlanにフォールバック
        expect(invalidStatus.currentPlanClass, isA<BasicPlan>());
      });
    });

    group('使用量管理とPlanクラス統合', () {
      test('AI生成制限がPlanクラスから正しく取得される', () {
        final basicStatus = SubscriptionStatus(
          planId: 'basic',
          isActive: true,
          monthlyUsageCount: 5,
        );
        final premiumStatus = SubscriptionStatus(
          planId: 'premium_monthly',
          isActive: true,
          monthlyUsageCount: 50,
        );

        final basicPlan = basicStatus.currentPlanClass;
        final premiumPlan = premiumStatus.currentPlanClass;

        // 制限値の確認
        expect(basicPlan.monthlyAiGenerationLimit, 10);
        expect(premiumPlan.monthlyAiGenerationLimit, 100);

        // 残り使用可能回数の計算
        expect(basicStatus.remainingGenerations, 5);
        expect(premiumStatus.remainingGenerations, 50);
      });

      test('機能アクセス権限がPlanクラスから正しく判定される', () {
        final basicStatus = SubscriptionStatus(planId: 'basic', isActive: true);
        final premiumStatus = SubscriptionStatus(
          planId: 'premium_yearly',
          isActive: true,
        );

        final basicPlan = basicStatus.currentPlanClass;
        final premiumPlan = premiumStatus.currentPlanClass;

        // Basicプランの機能制限
        expect(basicPlan.hasWritingPrompts, false);
        expect(basicPlan.hasAdvancedFilters, false);
        expect(basicPlan.hasAdvancedAnalytics, false);
        expect(basicPlan.hasPrioritySupport, false);

        // Premiumプランのフル機能
        expect(premiumPlan.hasWritingPrompts, true);
        expect(premiumPlan.hasAdvancedFilters, true);
        expect(premiumPlan.hasAdvancedAnalytics, true);
        expect(premiumPlan.hasPrioritySupport, true);
      });
    });
  });
}
