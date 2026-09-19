import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';
import 'package:smart_photo_diary/utils/upgrade_dialog_utils.dart';
import 'package:smart_photo_diary/widgets/upgrade/plan_option_card.dart';
import 'package:smart_photo_diary/widgets/upgrade/upgrade_dialog.dart';

import '../../integration/mocks/mock_services.dart';
import '../../test_helpers/widget_test_helpers.dart';

void main() {
  late MockILoggingService mockLogger;
  late MockSubscriptionServiceInterface mockSubscription;
  final plan = PremiumMonthlyPlan();

  setUpAll(registerMockFallbacks);

  setUp(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();

    mockLogger = TestServiceSetup.getLoggingService();
    mockSubscription = TestServiceSetup.getSubscriptionService();
    serviceLocator.registerSingleton<ISubscriptionService>(mockSubscription);

    when(
      () => mockSubscription.getProductPrice(any()),
    ).thenAnswer((_) async => const Success(null));
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  Widget buildApp() {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => UpgradeDialogUtils.showUpgradeDialog(
              context,
              logger: mockLogger,
              subscriptionService: mockSubscription,
            ),
            child: const Text('Open paywall'),
          ),
        ),
      ),
    );
  }

  Future<void> openPaywall(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open paywall'));
    await tester.pumpAndSettle();
  }

  Future<void> selectMonthlyPlan(WidgetTester tester) async {
    await tester.runAsync(() async {
      tester.widget<PlanOptionCard>(find.byType(PlanOptionCard).first).onTap();
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('UpgradeDialogUtils.showUpgradeDialog', () {
    testWidgets('shows a success snackbar and closes the paywall on purchase', (
      WidgetTester tester,
    ) async {
      when(
        () => mockSubscription.purchaseStream,
      ).thenAnswer((_) => const Stream<PurchaseResult>.empty());
      when(() => mockSubscription.purchasePlanClass(any())).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.purchased,
            productId: plan.productId,
          ),
        ),
      );

      await openPaywall(tester);
      await selectMonthlyPlan(tester);

      expect(
        find.text('Your Premium subscription is now active.'),
        findsOneWidget,
      );
      expect(find.byType(UpgradeDialog), findsNothing);
    });

    testWidgets('keeps the paywall open with the cancel message on cancel', (
      WidgetTester tester,
    ) async {
      final statusController = StreamController<PurchaseResult>.broadcast();
      addTearDown(statusController.close);
      when(
        () => mockSubscription.purchaseStream,
      ).thenAnswer((_) => statusController.stream);
      when(() => mockSubscription.purchasePlanClass(any())).thenAnswer((
        _,
      ) async {
        statusController.add(
          PurchaseResult(
            status: PurchaseStatus.cancelled,
            productId: plan.productId,
          ),
        );
        return Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        );
      });

      await openPaywall(tester);
      await selectMonthlyPlan(tester);

      expect(
        find.text('Your Premium subscription is now active.'),
        findsNothing,
      );
      expect(find.text('Purchase was canceled.'), findsOneWidget);
      expect(find.byType(UpgradeDialog), findsOneWidget);
    });
  });
}
