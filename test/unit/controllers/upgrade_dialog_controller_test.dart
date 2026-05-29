import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/upgrade_dialog_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

class MockLoggingService extends Mock implements ILoggingService {}

class MockSubscriptionService extends Mock implements ISubscriptionService {}

void main() {
  late MockLoggingService mockLogger;
  late MockSubscriptionService mockSubscription;

  setUp(() {
    mockLogger = MockLoggingService();
    mockSubscription = MockSubscriptionService();

    when(
      () => mockLogger.info(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.debug(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.warning(
        any(),
        context: any(named: 'context'),
        data: any(named: 'data'),
      ),
    ).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        context: any(named: 'context'),
        error: any(named: 'error'),
      ),
    ).thenReturn(null);
  });

  UpgradeDialogController createController({
    Stream<PurchaseResult>? purchaseStream,
  }) {
    final stream = purchaseStream ?? const Stream<PurchaseResult>.empty();
    when(() => mockSubscription.purchaseStream).thenAnswer((_) => stream);
    return UpgradeDialogController(
      logger: mockLogger,
      subscriptionService: mockSubscription,
    );
  }

  final plan = PremiumMonthlyPlan();

  group('UpgradeDialogController.purchasePlan', () {
    test('購入 pending → purchased でシュミレートすると showingPlans に戻る', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      final controller = createController(
        purchaseStream: streamController.stream,
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      final purchaseFuture = controller.purchasePlan(plan);
      expect(controller.state, UpgradeDialogState.purchasing);

      streamController.add(
        PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: plan.productId,
        ),
      );

      expect(await purchaseFuture, true);
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('キャンセル時も showingPlans に戻る', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      final controller = createController(
        purchaseStream: streamController.stream,
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      final purchaseFuture = controller.purchasePlan(plan);
      streamController.add(
        PurchaseResult(
          status: PurchaseStatus.cancelled,
          productId: plan.productId,
        ),
      );

      await purchaseFuture;
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('エラーイベント受信時も showingPlans に戻る', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      final controller = createController(
        purchaseStream: streamController.stream,
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      final purchaseFuture = controller.purchasePlan(plan);
      streamController.add(
        PurchaseResult(status: PurchaseStatus.error, productId: plan.productId),
      );

      await purchaseFuture;
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('別 productId のイベントは無視し、本命 productId で完了する', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      final controller = createController(
        purchaseStream: streamController.stream,
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      final purchaseFuture = controller.purchasePlan(plan);

      // 別プランのイベント（無視されるべき）
      streamController.add(
        const PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: 'other_product',
        ),
      );
      await Future.delayed(Duration.zero);
      // まだ purchasing 状態のまま
      expect(controller.state, UpgradeDialogState.purchasing);

      // 本命プランのイベント
      streamController.add(
        PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: plan.productId,
        ),
      );
      await purchaseFuture;
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('purchasePlanClass が Failure の場合は即完了して showingPlans に戻る', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => const Failure(ServiceException('Purchase not available')),
      );

      await controller.purchasePlan(plan);
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('シミュレータモック経路: purchasePlanClass が Success(purchased) を即返す', () async {
      final controller = createController();
      addTearDown(controller.dispose);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.purchased,
            productId: plan.productId,
          ),
        ),
      );

      await controller.purchasePlan(plan);
      expect(controller.state, UpgradeDialogState.showingPlans);
    });

    test('同時購入リクエストは無視される', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      final controller = createController(
        purchaseStream: streamController.stream,
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      final first = controller.purchasePlan(plan);
      final second = controller.purchasePlan(plan);

      streamController.add(
        PurchaseResult(
          status: PurchaseStatus.purchased,
          productId: plan.productId,
        ),
      );

      expect(await first, true);
      // 2回目はガード発動で false
      expect(await second, false);

      // purchasePlanClass は1回だけ呼ばれる
      verify(() => mockSubscription.purchasePlanClass(plan)).called(1);
    });

    test('タイムアウト後に showingPlans に戻る', () async {
      final streamController = StreamController<PurchaseResult>.broadcast();
      when(
        () => mockSubscription.purchaseStream,
      ).thenAnswer((_) => streamController.stream);

      // テスト用に短いタイムアウトを注入
      final controller = UpgradeDialogController(
        logger: mockLogger,
        subscriptionService: mockSubscription,
        purchaseTimeout: const Duration(milliseconds: 50),
      );
      addTearDown(controller.dispose);
      addTearDown(streamController.close);

      when(() => mockSubscription.purchasePlanClass(plan)).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );

      await controller.purchasePlan(plan);
      // タイムアウト後に purchasing → showingPlans に遷移する
      expect(controller.state, UpgradeDialogState.showingPlans);
    });
  });
}
