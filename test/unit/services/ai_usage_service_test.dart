import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/services/ai_usage_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../helpers/hive_test_helpers.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late AiUsageService usageService;
  late SubscriptionStateService stateService;
  late MockLoggingService mockLogger;

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearSubscriptionBox();
    mockLogger = MockLoggingService();
    stateService = SubscriptionStateService(logger: mockLogger);
    await stateService.initialize();
    usageService = AiUsageService(
      stateService: stateService,
      logger: mockLogger,
    );
  });

  tearDown(() async {
    if (stateService.isInitialized) {
      await stateService.dispose();
    }
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  group('canUseAiGeneration', () {
    test('Basic 初期状態 → Success(true)', () async {
      final result = await usageService.canUseAiGeneration();
      expect(result.isSuccess, isTrue);
      expect(result.value, isTrue);
    });

    test('制限到達時 → Success(false)', () async {
      // Basic plan limit = 10
      for (int i = 0; i < SubscriptionConstants.basicMonthlyAiLimit; i++) {
        await usageService.incrementAiUsage();
      }

      final result = await usageService.canUseAiGeneration();
      expect(result.isSuccess, isTrue);
      expect(result.value, isFalse);
    });

    test('Premium プラン → 制限値がプランに依存', () async {
      await stateService.createStatusForPlan(PremiumMonthlyPlan());

      // Premium limit = 100, should be able to use
      final result = await usageService.canUseAiGeneration();
      expect(result.isSuccess, isTrue);
      expect(result.value, isTrue);
    });
  });

  group('incrementAiUsage', () {
    test('正常インクリメント → Success + usageCount + 1', () async {
      final result = await usageService.incrementAiUsage();
      expect(result.isSuccess, isTrue);

      final statusResult = await stateService.getCurrentStatus();
      expect(statusResult.value.monthlyUsageCount, equals(1));
    });

    test('制限到達後のインクリメント → Failure', () async {
      for (int i = 0; i < SubscriptionConstants.basicMonthlyAiLimit; i++) {
        await usageService.incrementAiUsage();
      }

      final result = await usageService.incrementAiUsage();
      expect(result.isFailure, isTrue);
    });
  });

  group('getRemainingGenerations', () {
    test('初期状態 → プランの制限値', () async {
      final result = await usageService.getRemainingGenerations();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(SubscriptionConstants.basicMonthlyAiLimit));
    });

    test('N回使用後 → 制限値 - N', () async {
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();

      final result = await usageService.getRemainingGenerations();
      expect(result.isSuccess, isTrue);
      expect(
        result.value,
        equals(SubscriptionConstants.basicMonthlyAiLimit - 3),
      );
    });

    test('全使用後 → 0', () async {
      for (int i = 0; i < SubscriptionConstants.basicMonthlyAiLimit; i++) {
        await usageService.incrementAiUsage();
      }

      final result = await usageService.getRemainingGenerations();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });
  });

  group('getMonthlyUsage', () {
    test('初期状態 → Success(0)', () async {
      final result = await usageService.getMonthlyUsage();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(0));
    });

    test('インクリメント後 → 正しいカウント', () async {
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();

      final result = await usageService.getMonthlyUsage();
      expect(result.isSuccess, isTrue);
      expect(result.value, equals(2));
    });
  });

  group('resetUsage', () {
    test('リセット後 monthlyUsageCount が 0', () async {
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();

      final resetResult = await usageService.resetUsage();
      expect(resetResult.isSuccess, isTrue);

      final usageResult = await usageService.getMonthlyUsage();
      expect(usageResult.value, equals(0));
    });
  });

  group('resetMonthlyUsageIfNeeded', () {
    test('同月 → リセットなし', () async {
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();

      final result = await usageService.resetMonthlyUsageIfNeeded();
      expect(result.isSuccess, isTrue);

      final usageResult = await usageService.getMonthlyUsage();
      expect(usageResult.value, equals(2));
    });

    test('月跨ぎ → 自動リセット', () async {
      await usageService.incrementAiUsage();
      await usageService.incrementAiUsage();

      // Set the lastResetDate to a previous month
      final statusResult = await stateService.getCurrentStatus();
      final oldStatus = statusResult.value;
      final previousMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month - 1,
        1,
      );
      final updatedStatus = oldStatus.copyWith(
        lastResetDate: previousMonth,
        usageMonth:
            '${previousMonth.year.toString().padLeft(4, '0')}-${previousMonth.month.toString().padLeft(2, '0')}',
      );
      await stateService.updateStatus(updatedStatus);

      final result = await usageService.resetMonthlyUsageIfNeeded();
      expect(result.isSuccess, isTrue);

      final usageResult = await usageService.getMonthlyUsage();
      expect(usageResult.value, equals(0));
    });
  });

  group('getNextResetDate', () {
    test('次月1日を返す', () async {
      final result = await usageService.getNextResetDate();
      expect(result.isSuccess, isTrue);

      final now = DateTime.now();
      final expectedMonth = now.month == 12 ? 1 : now.month + 1;
      final expectedYear = now.month == 12 ? now.year + 1 : now.year;

      expect(result.value.year, equals(expectedYear));
      expect(result.value.month, equals(expectedMonth));
      expect(result.value.day, equals(1));
    });

    test('12月 → 翌年1月1日', () async {
      // Set lastResetDate to December
      final statusResult = await stateService.getCurrentStatus();
      final updatedStatus = statusResult.value.copyWith(
        lastResetDate: DateTime(2025, 12, 15),
      );
      await stateService.updateStatus(updatedStatus);

      final result = await usageService.getNextResetDate();
      expect(result.isSuccess, isTrue);
      expect(result.value.year, equals(2026));
      expect(result.value.month, equals(1));
      expect(result.value.day, equals(1));
    });
  });
}
