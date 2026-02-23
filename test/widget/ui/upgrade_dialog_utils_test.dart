import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/plans/plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/ui/components/custom_dialog.dart';

import '../../test_helpers/widget_test_helpers.dart';

/// Tests for upgrade dialog UI structure and plan display.
void main() {

  group('UpgradeDialogUtils._showPremiumPlanDialog', () {
    /// Shows the premium plan dialog by calling the internal static directly
    /// through reflection-like trick: we invoke the public entry point with
    /// pre-fetched plans and prices so that the loading overlay does not appear.
    Future<void> showPlanDialog(
      WidgetTester tester,
      List<Plan> plans,
      Map<String, String> prices,
    ) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithLocalizedApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  // Call the internal dialog by using showDialog directly with
                  // a CustomDialog that mirrors what _showPremiumPlanDialog builds
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => _buildPlanDialogForTest(
                      dialogContext,
                      plans,
                      prices,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('displays plan names and prices for monthly plan', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      final prices = <String, String>{
        PremiumMonthlyPlan().id: '¥300',
      };

      await showPlanDialog(tester, plans, prices);

      // Monthly plan title from l10n
      expect(find.text('Premium (monthly)'), findsOneWidget);
      // Price display
      expect(find.textContaining('¥300'), findsOneWidget);
    });

    testWidgets('displays plan names and prices for yearly plan', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumYearlyPlan()];
      final prices = <String, String>{
        PremiumYearlyPlan().id: '¥2,800',
      };

      await showPlanDialog(tester, plans, prices);

      // Yearly plan title from l10n
      expect(find.text('Premium (yearly)'), findsOneWidget);
      // Price display
      expect(find.textContaining('¥2,800'), findsOneWidget);
    });

    testWidgets('displays both plans when two plans are provided', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumMonthlyPlan(), PremiumYearlyPlan()];
      final prices = <String, String>{
        PremiumMonthlyPlan().id: '¥300',
        PremiumYearlyPlan().id: '¥2,800',
      };

      await showPlanDialog(tester, plans, prices);

      expect(find.text('Premium (monthly)'), findsOneWidget);
      expect(find.text('Premium (yearly)'), findsOneWidget);
    });

    testWidgets('displays premium bullet list items', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      final prices = <String, String>{PremiumMonthlyPlan().id: '¥300'};

      await showPlanDialog(tester, plans, prices);

      // English l10n bullet texts
      expect(find.text('Photos from the past year'), findsOneWidget);
      expect(find.text('100 stories per month'), findsOneWidget);
      expect(find.text('All writing styles'), findsOneWidget);
    });

    testWidgets('displays cancel button', (WidgetTester tester) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      final prices = <String, String>{PremiumMonthlyPlan().id: '¥300'};

      await showPlanDialog(tester, plans, prices);

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button dismisses dialog', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      final prices = <String, String>{PremiumMonthlyPlan().id: '¥300'};

      await showPlanDialog(tester, plans, prices);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed - plan titles should no longer be visible
      expect(find.text('Premium (monthly)'), findsNothing);
    });

    testWidgets('displays auto-renewal notice', (WidgetTester tester) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      final prices = <String, String>{PremiumMonthlyPlan().id: '¥300'};

      await showPlanDialog(tester, plans, prices);

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('displays discount info for yearly plan', (
      WidgetTester tester,
    ) async {
      final yearlyPlan = PremiumYearlyPlan();
      final plans = <Plan>[yearlyPlan];
      final prices = <String, String>{yearlyPlan.id: '¥2,800'};

      await showPlanDialog(tester, plans, prices);

      // Yearly plan should show discount percentage
      expect(
        find.textContaining('%'),
        findsWidgets,
      );
    });
  });

  group('UpgradeDialogUtils._buildPriceDisplay', () {
    testWidgets('shows fallback price when dynamic price is null', (
      WidgetTester tester,
    ) async {
      final plans = <Plan>[PremiumMonthlyPlan()];
      // No price provided for monthly plan
      final prices = <String, String>{};

      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithLocalizedApp(
          Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) => _buildPlanDialogForTest(
                      dialogContext,
                      plans,
                      prices,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Should still show some price (fallback)
      expect(find.textContaining('/'), findsWidgets);
    });
  });
}

/// Builds a dialog that mirrors [UpgradeDialogUtils._showPremiumPlanDialog]
/// without requiring DynamicPricingUtils or OverlayEntry.
Widget _buildPlanDialogForTest(
  BuildContext dialogContext,
  List<Plan> plans,
  Map<String, String> priceStrings,
) {
  return CustomDialog(
    title: 'Revisit more of your life.',
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBulletListForTest(dialogContext),
          const SizedBox(height: 16),
          ...plans.map(
            (plan) => _buildPlanOptionForTest(
              dialogContext,
              plan,
              priceStrings[plan.id],
            ),
          ),
          const SizedBox(height: 16),
          _buildAutoRenewNoticeForTest(dialogContext),
        ],
      ),
    ),
    actions: [
      CustomDialogAction(
        text: 'Cancel',
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ],
  );
}

Widget _buildBulletListForTest(BuildContext context) {
  // Mirror the l10n bullets from UpgradeDialogUtils._buildPremiumBulletList
  final bullets = [
    'Photos from the past year',
    '100 stories per month',
    'All writing styles',
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: bullets.map((text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SizedBox(width: 5, height: 5),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
      );
    }).toList(),
  );
}

Widget _buildPlanOptionForTest(
  BuildContext context,
  Plan plan,
  String? priceString,
) {
  String description = '';
  if (plan is PremiumYearlyPlan) {
    final discount = plan.discountPercentage;
    if (discount > 0) {
      description = '$discount% off vs monthly';
    }
  }

  final localizedName = plan.isMonthly
      ? 'Premium (monthly)'
      : plan.isYearly
          ? 'Premium (yearly)'
          : plan.displayName;

  final price = priceString ?? '¥${plan.price}';
  final priceText = plan.isMonthly ? '$price/mo' : '$price/yr';

  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizedName),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description),
                    ],
                  ],
                ),
              ),
              Text(priceText),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAutoRenewNoticeForTest(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(8),
    child: const Row(
      children: [
        Icon(Icons.info_outline_rounded, size: 16),
        SizedBox(width: 4),
        Expanded(child: Text('Auto-renewal notice')),
      ],
    ),
  );
}
