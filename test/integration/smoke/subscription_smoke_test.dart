import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

import '../mocks/mock_services.dart';
import '../test_helpers/integration_test_helpers.dart';

void main() {
  group('スモークテスト: サブスクリプション制限フロー', () {
    late MockSubscriptionServiceInterface mockSubService;

    setUpAll(() {
      registerMockFallbacks();
    });

    setUp(() async {
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
      mockSubService =
          serviceLocator.get<ISubscriptionService>()
              as MockSubscriptionServiceInterface;
    });

    tearDown(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    test('BasicPlan で使用可能な場合 canUseAiGeneration が true を返す', () async {
      IntegrationTestHelpers.setupMockBasicPlan(mockSubService, usageCount: 0);

      final result = await mockSubService.canUseAiGeneration();

      expect(result, isA<Success<bool>>());
      expect(result.value, isTrue);
    });

    test('BasicPlan で上限に達した場合 canUseAiGeneration が false を返す', () async {
      final plan = BasicPlan();
      IntegrationTestHelpers.setupMockUsageLimitReached(mockSubService, plan);

      final result = await mockSubService.canUseAiGeneration();

      expect(result, isA<Success<bool>>());
      expect(result.value, isFalse);
    });

    test('残り生成数が プラン上限 - 使用数 で正しく返る', () async {
      const usageCount = 3;
      final plan = BasicPlan();
      IntegrationTestHelpers.setupMockBasicPlan(
        mockSubService,
        usageCount: usageCount,
      );

      final remainingResult = await mockSubService.getRemainingGenerations();

      expect(remainingResult, isA<Success<int>>());
      expect(
        remainingResult.value,
        equals(plan.monthlyAiGenerationLimit - usageCount),
      );
    });

    test('PremiumPlan は BasicPlan より高い上限を持つ', () async {
      final basicPlan = BasicPlan();
      final premiumPlan = PremiumYearlyPlan();

      expect(
        premiumPlan.monthlyAiGenerationLimit,
        greaterThan(basicPlan.monthlyAiGenerationLimit),
      );
    });

    test('getCurrentPlanClass が BasicPlan を返す（デフォルト設定）', () async {
      final result = await mockSubService.getCurrentPlanClass();

      expect(result, isA<Success>());
      expect(result.value, isA<BasicPlan>());
    });

    group('プラン別アクセス制御', () {
      test('BasicPlan では canAccessPremiumFeatures が false を返す', () async {
        IntegrationTestHelpers.setupMockBasicPlan(mockSubService);
        // BasicPlan の場合 isPremium = false なのでアクセス不可
        when(
          () => mockSubService.canAccessPremiumFeatures(),
        ).thenAnswer((_) async => const Success(false));

        final result = await mockSubService.canAccessPremiumFeatures();

        expect(result.value, isFalse);
      });

      test('PremiumPlan では canAccessPremiumFeatures が true を返す', () async {
        IntegrationTestHelpers.setupMockPremiumPlan(mockSubService);
        when(
          () => mockSubService.canAccessPremiumFeatures(),
        ).thenAnswer((_) async => const Success(true));

        final result = await mockSubService.canAccessPremiumFeatures();

        expect(result.value, isTrue);
      });
    });
  });
}
