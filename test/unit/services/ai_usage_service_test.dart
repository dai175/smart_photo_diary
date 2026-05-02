import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/services/ai_usage_service.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_state_service_interface.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../helpers/hive_test_helpers.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class _MockSubscriptionStateService extends Mock
    implements ISubscriptionStateService {}

class _SubscriptionStatusFake extends Fake implements SubscriptionStatus {}

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

  // forcePlan 中の DB 汚染防止: 書き戻しは raw status をベースに行う。
  // forcePlan の実フラグはテストから操作できないため、stateService を mock し
  // getCurrentStatus と getRawStatus が異なる値を返す状況を再現する。
  group('writebacks use raw status (forcePlan invariant)', () {
    late _MockSubscriptionStateService mockState;
    late AiUsageService service;

    setUpAll(() {
      registerFallbackValue(_SubscriptionStatusFake());
    });

    SubscriptionStatus rawBasic({int count = 0, DateTime? lastResetDate}) {
      return SubscriptionStatus(
        planId: SubscriptionConstants.basicPlanId,
        isActive: true,
        startDate: DateTime(2026, 1, 1),
        expiryDate: null,
        autoRenewal: false,
        monthlyUsageCount: count,
        lastResetDate: lastResetDate ?? DateTime.now(),
      );
    }

    SubscriptionStatus forcedPremium({int count = 0, DateTime? lastResetDate}) {
      return SubscriptionStatus(
        planId: SubscriptionConstants.premiumMonthlyPlanId,
        isActive: true,
        startDate: DateTime(2026, 1, 1),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        autoRenewal: false,
        monthlyUsageCount: count,
        lastResetDate: lastResetDate ?? DateTime.now(),
      );
    }

    setUp(() {
      mockState = _MockSubscriptionStateService();
      when(() => mockState.isInitialized).thenReturn(true);
      when(() => mockState.isSubscriptionValid(any())).thenReturn(true);
      when(
        () => mockState.updateStatus(any()),
      ).thenAnswer((_) async => const Success(null));
      service = AiUsageService(
        stateService: mockState,
        logger: MockLoggingService(),
      );
    });

    test('incrementAiUsage は raw の planId/expiryDate を保持して書き戻す', () async {
      final raw = rawBasic(count: 3);
      final forced = forcedPremium(count: 3);

      when(
        () => mockState.getCurrentStatus(),
      ).thenAnswer((_) async => Success(forced));
      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(raw));

      final result = await service.incrementAiUsage();
      expect(result.isSuccess, isTrue);

      final captured =
          verify(() => mockState.updateStatus(captureAny())).captured.single
              as SubscriptionStatus;

      expect(captured.planId, equals(SubscriptionConstants.basicPlanId));
      expect(captured.expiryDate, isNull);
      expect(captured.monthlyUsageCount, equals(4));
    });

    test('resetUsage は raw の planId/expiryDate を保持して書き戻す', () async {
      final raw = rawBasic(count: 8);

      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(raw));

      final result = await service.resetUsage();
      expect(result.isSuccess, isTrue);

      final captured =
          verify(() => mockState.updateStatus(captureAny())).captured.single
              as SubscriptionStatus;

      expect(captured.planId, equals(SubscriptionConstants.basicPlanId));
      expect(captured.expiryDate, isNull);
      expect(captured.monthlyUsageCount, equals(0));
    });

    test('月跨ぎリセットは raw の planId/expiryDate を保持して書き戻す', () async {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);
      final raw = rawBasic(count: 5, lastResetDate: previousMonth);
      final forced = forcedPremium(count: 5, lastResetDate: previousMonth);

      when(
        () => mockState.getCurrentStatus(),
      ).thenAnswer((_) async => Success(forced));
      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(raw));

      final result = await service.resetMonthlyUsageIfNeeded();
      expect(result.isSuccess, isTrue);

      final captured =
          verify(() => mockState.updateStatus(captureAny())).captured.single
              as SubscriptionStatus;

      expect(captured.planId, equals(SubscriptionConstants.basicPlanId));
      expect(captured.expiryDate, isNull);
      expect(captured.monthlyUsageCount, equals(0));
    });

    test('incrementAiUsage は updateStatus 失敗を Failure として伝播する', () async {
      final raw = rawBasic(count: 2);
      final forced = forcedPremium(count: 2);

      when(
        () => mockState.getCurrentStatus(),
      ).thenAnswer((_) async => Success(forced));
      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(raw));
      when(() => mockState.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('hive write failed')),
      );

      final result = await service.incrementAiUsage();
      expect(result.isFailure, isTrue);
    });

    test('resetUsage は updateStatus 失敗を Failure として伝播する', () async {
      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(rawBasic(count: 5)));
      when(() => mockState.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('hive write failed')),
      );

      final result = await service.resetUsage();
      expect(result.isFailure, isTrue);
    });

    test('月跨ぎリセットの updateStatus 失敗時は上限超えとして判定される', () async {
      final now = DateTime.now();
      final previousMonth = DateTime(now.year, now.month - 1, 15);
      // raw/forced いずれも Basic、count = 上限 10、先月の lastResetDate
      final atLimit = rawBasic(
        count: SubscriptionConstants.basicMonthlyAiLimit,
        lastResetDate: previousMonth,
      );

      when(
        () => mockState.getCurrentStatus(),
      ).thenAnswer((_) async => Success(atLimit));
      when(
        () => mockState.getRawStatus(),
      ).thenAnswer((_) async => Success(atLimit));
      when(() => mockState.updateStatus(any())).thenAnswer(
        (_) async => const Failure(ServiceException('hive write failed')),
      );

      // helper が誤って 0 を返すなら 0 < 10 で true。修正後は元の count(10) が
      // 温存され 10 < 10 = false となり、Hive と乖離した判定が出ない。
      final result = await service.canUseAiGeneration();
      expect(result.isSuccess, isTrue);
      expect(result.value, isFalse);
    });
  });
}
