import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/constants/app_constants.dart';
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
    // DynamicPricingUtils resolves ISubscriptionService through the locator
    serviceLocator.registerSingleton<ISubscriptionService>(mockSubscription);

    when(
      () => mockSubscription.getProductPrice(any()),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => mockSubscription.purchaseStream,
    ).thenAnswer((_) => const Stream<PurchaseResult>.empty());
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

  Future<void> openPaywallAndTapFirstPlan(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Open paywall'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PlanOptionCard).first);
    // UpgradeDialog defers onPlanSelected by quickAnimationDuration; nothing
    // keeps a frame scheduled in between, so pumpAndSettle alone returns early.
    await tester.pump(AppConstants.quickAnimationDuration);
    await tester.pumpAndSettle();
  }

  group('UpgradeDialogUtils.showUpgradeDialog', () {
    testWidgets('shows a success snackbar and closes the paywall on purchase', (
      WidgetTester tester,
    ) async {
      when(() => mockSubscription.purchasePlanClass(any())).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.purchased,
            productId: plan.productId,
          ),
        ),
      );

      await openPaywallAndTapFirstPlan(tester);

      expect(
        find.text('Your Premium subscription is now active.'),
        findsOneWidget,
      );
      expect(find.byType(UpgradeDialog), findsNothing);
    });

    testWidgets('keeps the paywall open with the cancel message on cancel', (
      WidgetTester tester,
    ) async {
      when(() => mockSubscription.purchasePlanClass(any())).thenAnswer(
        (_) async => Success(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: plan.productId,
          ),
        ),
      );
      when(() => mockSubscription.purchaseStream).thenAnswer(
        (_) => Stream.value(
          PurchaseResult(
            status: PurchaseStatus.cancelled,
            productId: plan.productId,
          ),
        ),
      );

      await openPaywallAndTapFirstPlan(tester);

      expect(
        find.text('Your Premium subscription is now active.'),
        findsNothing,
      );
      expect(find.text('Purchase was canceled.'), findsOneWidget);
      expect(find.byType(UpgradeDialog), findsOneWidget);
    });
  });
}
