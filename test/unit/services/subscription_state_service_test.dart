import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:smart_photo_diary/services/subscription_state_service.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/constants/subscription_constants.dart';
import '../helpers/hive_test_helpers.dart';

void main() {
  late SubscriptionStateService stateService;

  setUpAll(() async {
    await HiveTestHelpers.setupHiveForTesting();
  });

  setUp(() async {
    await HiveTestHelpers.clearSubscriptionBox();
    stateService = SubscriptionStateService();
  });

  tearDown(() async {
    if (stateService.isInitialized) {
      await stateService.dispose();
    }
  });

  tearDownAll(() async {
    await HiveTestHelpers.closeHive();
  });

  group('初期化', () {
    test('初期化成功時、isInitialized が true', () async {
      await stateService.initialize();
      expect(stateService.isInitialized, isTrue);
    });

    test('初期化時に Basic プランのデフォルト状態が作成される', () async {
      await stateService.initialize();

      final result = await stateService.getCurrentStatus();
      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('basic'));
      expect(result.value.isActive, isTrue);
      expect(result.value.monthlyUsageCount, equals(0));
      expect(result.value.expiryDate, isNull);
    });

    test('二重初期化しても問題なし', () async {
      await stateService.initialize();
      final result1 = await stateService.initialize();
      expect(result1.isSuccess, isTrue);
      expect(stateService.isInitialized, isTrue);
    });
  });

  group('状態取得', () {
    test('getCurrentStatus() が初期状態を返す', () async {
      await stateService.initialize();

      final result = await stateService.getCurrentStatus();
      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('basic'));
      expect(result.value.isActive, isTrue);
    });

    test('未初期化時は Failure を返す', () async {
      final result = await stateService.getCurrentStatus();
      expect(result.isFailure, isTrue);
    });
  });

  group('状態更新', () {
    setUp(() async {
      await stateService.initialize();
    });

    test('updateStatus() で状態を更新できる', () async {
      final newStatus = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        autoRenewal: true,
        monthlyUsageCount: 5,
        lastResetDate: DateTime.now(),
        transactionId: 'test_tx',
      );

      final updateResult = await stateService.updateStatus(newStatus);
      expect(updateResult.isSuccess, isTrue);
    });

    test('更新後に getCurrentStatus() で反映を確認', () async {
      final newStatus = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
        autoRenewal: true,
        monthlyUsageCount: 7,
        lastResetDate: DateTime.now(),
        transactionId: 'test_tx_2',
      );

      await stateService.updateStatus(newStatus);
      final result = await stateService.getCurrentStatus();

      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('premium_monthly'));
      expect(result.value.monthlyUsageCount, equals(7));
      expect(result.value.transactionId, equals('test_tx_2'));
    });

    test('未初期化時は Failure を返す', () async {
      final uninitService = SubscriptionStateService();
      final result = await uninitService.updateStatus(
        SubscriptionStatus(planId: 'basic'),
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('プラン作成', () {
    setUp(() async {
      await stateService.initialize();
    });

    test('createStatusForPlan(BasicPlan) で Basic 状態が作成される', () async {
      await stateService.clearStatus();

      final result = await stateService.createStatusForPlan(BasicPlan());
      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('basic'));
      expect(result.value.isActive, isTrue);
      expect(result.value.expiryDate, isNull);
      expect(result.value.autoRenewal, isFalse);
      expect(result.value.monthlyUsageCount, equals(0));
    });

    test('createStatusForPlan(PremiumMonthlyPlan) で有効期限付き状態が作成される', () async {
      await stateService.clearStatus();

      final result = await stateService.createStatusForPlan(
        PremiumMonthlyPlan(),
      );
      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('premium_monthly'));
      expect(result.value.isActive, isTrue);
      expect(result.value.expiryDate, isNotNull);
      expect(result.value.autoRenewal, isTrue);

      final expectedExpiry = result.value.startDate!.add(
        const Duration(days: SubscriptionConstants.subscriptionMonthDays),
      );
      expect(
        result.value.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
        lessThan(1),
      );
    });

    test('createStatusForPlan(PremiumYearlyPlan) で年間有効期限', () async {
      await stateService.clearStatus();

      final result = await stateService.createStatusForPlan(
        PremiumYearlyPlan(),
      );
      expect(result.isSuccess, isTrue);
      expect(result.value.planId, equals('premium_yearly'));
      expect(result.value.expiryDate, isNotNull);

      final expectedExpiry = result.value.startDate!.add(
        const Duration(days: SubscriptionConstants.subscriptionYearDays),
      );
      expect(
        result.value.expiryDate!.difference(expectedExpiry).inMinutes.abs(),
        lessThan(1),
      );
    });
  });

  group('プラン取得', () {
    setUp(() async {
      await stateService.initialize();
    });

    test('getPlanClass(basic) が BasicPlan を返す', () {
      final result = stateService.getPlanClass('basic');
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<BasicPlan>());
    });

    test('getPlanClass(premium_monthly) が PremiumMonthlyPlan を返す', () {
      final result = stateService.getPlanClass('premium_monthly');
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<PremiumMonthlyPlan>());
    });

    test('不正な planId は Failure を返す', () {
      final result = stateService.getPlanClass('invalid_plan');
      expect(result.isFailure, isTrue);
    });

    test('getCurrentPlanClass() が現在のプランを返す', () async {
      final result = await stateService.getCurrentPlanClass();
      expect(result.isSuccess, isTrue);
      expect(result.value, isA<BasicPlan>());
    });
  });

  group('サブスクリプション検証', () {
    setUp(() async {
      await stateService.initialize();
    });

    test('isSubscriptionValid: Basic プラン → true', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: true,
        startDate: DateTime.now(),
      );
      expect(stateService.isSubscriptionValid(status), isTrue);
    });

    test('isSubscriptionValid: Premium + 有効期限内 → true', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(stateService.isSubscriptionValid(status), isTrue);
    });

    test('isSubscriptionValid: Premium + 期限切れ → false', () {
      final status = SubscriptionStatus(
        planId: 'premium_monthly',
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        expiryDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(stateService.isSubscriptionValid(status), isFalse);
    });

    test('isSubscriptionValid: inactive → false', () {
      final status = SubscriptionStatus(
        planId: 'basic',
        isActive: false,
        startDate: DateTime.now(),
      );
      expect(stateService.isSubscriptionValid(status), isFalse);
    });
  });

  group('状態リフレッシュ', () {
    test('refreshStatus() で Box が再オープンされる', () async {
      await stateService.initialize();

      final newStatus = SubscriptionStatus(
        planId: 'premium_yearly',
        isActive: true,
        startDate: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 365)),
        monthlyUsageCount: 15,
        transactionId: 'test_refresh',
      );
      await stateService.updateStatus(newStatus);

      final result = await stateService.refreshStatus();
      expect(result.isSuccess, isTrue);

      final statusResult = await stateService.getCurrentStatus();
      expect(statusResult.isSuccess, isTrue);
      expect(statusResult.value.planId, equals('premium_yearly'));
      expect(statusResult.value.monthlyUsageCount, equals(15));
    });
  });

  group('テスト用API', () {
    setUp(() async {
      await stateService.initialize();
    });

    test('clearStatus() で状態が削除される', () async {
      final clearResult = await stateService.clearStatus();
      expect(clearResult.isSuccess, isTrue);

      final box = stateService.subscriptionBox;
      final status = box?.get(SubscriptionConstants.statusKey);
      expect(status, isNull);
    });

    test('subscriptionBox getter が Box を返す', () {
      final box = stateService.subscriptionBox;
      expect(box, isNotNull);
      expect(box, isA<Box<SubscriptionStatus>>());
      expect(box!.isOpen, isTrue);
    });
  });

  group('dispose', () {
    test('dispose() 後に isInitialized が false', () async {
      await stateService.initialize();
      expect(stateService.isInitialized, isTrue);

      await stateService.dispose();
      expect(stateService.isInitialized, isFalse);
    });
  });
}
