import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';

import '../test_helpers/integration_test_helpers.dart';

void main() {
  group('スモークテスト: サブスクリプション制限フロー', () {
    group('BasicPlan の AI 生成制限', () {
      test('使用回数 0 のとき canUseAiGeneration が true', () {
        final status = IntegrationTestHelpers.createTestSubscriptionStatus(
          plan: BasicPlan(),
          usageCount: 0,
        );
        expect(status.canUseAiGeneration, isTrue);
      });

      test('上限に達したとき canUseAiGeneration が false', () {
        final plan = BasicPlan();
        final status = IntegrationTestHelpers.createTestSubscriptionStatus(
          plan: plan,
          usageCount: plan.monthlyAiGenerationLimit,
        );
        expect(status.canUseAiGeneration, isFalse);
      });

      test('残り生成数が プラン上限 - 使用数 で正しく返る', () {
        const usageCount = 3;
        final plan = BasicPlan();
        final status = IntegrationTestHelpers.createTestSubscriptionStatus(
          plan: plan,
          usageCount: usageCount,
        );
        expect(
          status.remainingGenerations,
          equals(plan.monthlyAiGenerationLimit - usageCount),
        );
      });
    });

    test('PremiumPlan は BasicPlan より高い上限を持つ', () {
      final basicPlan = BasicPlan();
      final premiumPlan = PremiumYearlyPlan();
      expect(
        premiumPlan.monthlyAiGenerationLimit,
        greaterThan(basicPlan.monthlyAiGenerationLimit),
      );
    });

    test('デフォルト状態は BasicPlan を示す', () {
      final status = SubscriptionStatus.createDefault();
      expect(status.currentPlanClass, isA<BasicPlan>());
    });

    group('プラン別アクセス制御', () {
      test('BasicPlan では canAccessPremiumFeatures が false', () {
        final status = IntegrationTestHelpers.createTestSubscriptionStatus(
          plan: BasicPlan(),
        );
        expect(status.canAccessPremiumFeatures, isFalse);
      });

      test('PremiumPlan では canAccessPremiumFeatures が true', () {
        final status = IntegrationTestHelpers.createTestSubscriptionStatus(
          plan: PremiumYearlyPlan(),
        );
        expect(status.canAccessPremiumFeatures, isTrue);
      });
    });
  });
}
