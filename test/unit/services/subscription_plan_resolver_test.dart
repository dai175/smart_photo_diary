import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/subscription_plan_resolver.dart';

void main() {
  group('SubscriptionPlanResolver.resolve', () {
    test('basic → Success(BasicPlan)', () {
      final result = SubscriptionPlanResolver.resolve('basic');
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<BasicPlan>());
    });

    test('premium_monthly → Success(PremiumMonthlyPlan)', () {
      final result = SubscriptionPlanResolver.resolve('premium_monthly');
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<PremiumMonthlyPlan>());
    });

    test('premium_yearly → Success(PremiumYearlyPlan)', () {
      final result = SubscriptionPlanResolver.resolve('premium_yearly');
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<PremiumYearlyPlan>());
    });

    test('不正な planId → Failure', () {
      final result = SubscriptionPlanResolver.resolve('invalid_plan');
      expect(result.isFailure, isTrue);
    });
  });

  group('SubscriptionPlanResolver.resolveForcedPlanId', () {
    test("'premium' → premiumMonthlyPlanId", () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('premium'),
        equals(SubscriptionConstants.premiumMonthlyPlanId),
      );
    });

    test("'premium_monthly' → premiumMonthlyPlanId", () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('premium_monthly'),
        equals(SubscriptionConstants.premiumMonthlyPlanId),
      );
    });

    test("'PREMIUM_MONTHLY' (大文字) → premiumMonthlyPlanId", () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('PREMIUM_MONTHLY'),
        equals(SubscriptionConstants.premiumMonthlyPlanId),
      );
    });

    test("'premium_yearly' → premiumYearlyPlanId", () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('premium_yearly'),
        equals(SubscriptionConstants.premiumYearlyPlanId),
      );
    });

    test("'basic' → basicPlanId", () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('basic'),
        equals(SubscriptionConstants.basicPlanId),
      );
    });

    test('不明な値 → basicPlanId にフォールバック', () {
      expect(
        SubscriptionPlanResolver.resolveForcedPlanId('unknown'),
        equals(SubscriptionConstants.basicPlanId),
      );
    });
  });

  group('SubscriptionPlanResolver.buildStatusForPlan', () {
    test('BasicPlan → expiryDate=null, autoRenewal=false', () {
      final status = SubscriptionPlanResolver.buildStatusForPlan(BasicPlan());
      expect(status.planId, equals('basic'));
      expect(status.isActive, isTrue);
      expect(status.expiryDate, isNull);
      expect(status.autoRenewal, isFalse);
      expect(status.monthlyUsageCount, equals(0));
    });

    test('PremiumMonthlyPlan → expiryDate≈now+30days, autoRenewal=true', () {
      final status = SubscriptionPlanResolver.buildStatusForPlan(
        PremiumMonthlyPlan(),
      );
      expect(status.planId, equals('premium_monthly'));
      expect(status.isActive, isTrue);
      expect(status.autoRenewal, isTrue);
      expect(status.expiryDate, isNotNull);

      final expectedExpiry = status.startDate!.add(
        const Duration(days: SubscriptionConstants.subscriptionMonthDays),
      );
      expect(
        status.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('PremiumYearlyPlan → expiryDate≈now+365days', () {
      final status = SubscriptionPlanResolver.buildStatusForPlan(
        PremiumYearlyPlan(),
      );
      expect(status.planId, equals('premium_yearly'));
      expect(status.expiryDate, isNotNull);

      final expectedExpiry = status.startDate!.add(
        const Duration(days: SubscriptionConstants.subscriptionYearDays),
      );
      expect(
        status.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
        lessThan(1),
      );
    });
  });

  group('SubscriptionPlanResolver.applyForcePlan', () {
    test('EnvironmentConfig 未初期化時は status をそのまま返す', () {
      final original = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );
      final result = SubscriptionPlanResolver.applyForcePlan(original);
      expect(result.planId, equals('basic'));
      expect(result.isActive, isTrue);
    });
  });
}
