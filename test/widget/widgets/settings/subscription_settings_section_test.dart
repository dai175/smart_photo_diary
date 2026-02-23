import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/subscription_info_v2.dart';
import 'package:smart_photo_diary/models/subscription_status.dart';
import 'package:smart_photo_diary/widgets/settings/subscription_settings_section.dart';

import '../../../test_helpers/mock_platform_channels.dart';
import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  setUpAll(() {
    MockPlatformChannels.setupMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  SubscriptionInfoV2 buildBasicInfo({int usageCount = 3}) {
    final status = SubscriptionStatus(
      planId: 'basic',
      isActive: true,
      startDate: DateTime(2026, 1, 1),
      monthlyUsageCount: usageCount,
      lastResetDate: DateTime(2026, 2, 1),
      autoRenewal: false,
    );
    return SubscriptionInfoV2.fromStatus(status);
  }

  SubscriptionInfoV2 buildPremiumInfo({int usageCount = 5}) {
    final status = SubscriptionStatus(
      planId: 'premium_monthly',
      isActive: true,
      startDate: DateTime(2026, 1, 1),
      expiryDate: DateTime(2026, 7, 1),
      monthlyUsageCount: usageCount,
      lastResetDate: DateTime(2026, 2, 1),
      autoRenewal: true,
      transactionId: 'test-txn-id',
      lastPurchaseDate: DateTime(2026, 1, 1),
    );
    return SubscriptionInfoV2.fromStatus(status);
  }

  Widget buildWidget({
    SubscriptionInfoV2? subscriptionInfo,
    VoidCallback? onStateChanged,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: SingleChildScrollView(
          child: SubscriptionSettingsSection(
            subscriptionInfo: subscriptionInfo,
            onStateChanged: onStateChanged ?? () {},
          ),
        ),
      ),
    );
  }

  group('SubscriptionSettingsSection', () {
    group('loading state', () {
      testWidgets('shows loading text when subscriptionInfo is null', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(buildWidget(subscriptionInfo: null));
        await tester.pumpAndSettle();

        // Section title should be visible
        expect(find.text('Subscription'), findsOneWidget);
        // Loading text
        expect(find.text('Loading...'), findsOneWidget);
        // Membership icon
        expect(find.byIcon(Icons.card_membership_rounded), findsOneWidget);
      });
    });

    group('basic plan header', () {
      testWidgets('shows plan name for basic plan', (
        WidgetTester tester,
      ) async {
        final info = buildBasicInfo();
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Section title
        expect(find.text('Subscription'), findsOneWidget);
        // Plan name should contain Basic
        expect(find.textContaining('Basic'), findsOneWidget);
        // Membership icon for basic plan
        expect(find.byIcon(Icons.card_membership_rounded), findsOneWidget);
      });

      testWidgets('shows star icon for premium plan', (
        WidgetTester tester,
      ) async {
        final info = buildPremiumInfo();
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Star icon for premium
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      });
    });

    group('expanded content', () {
      testWidgets('expands and collapses on tap', (WidgetTester tester) async {
        final info = buildBasicInfo();
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Initially collapsed - should not show upgrade button
        expect(find.text('Unlock Premium'), findsNothing);

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Should show upgrade button after expanding
        expect(find.text('Unlock Premium'), findsOneWidget);

        // Tap again to collapse
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Should hide upgrade button after collapsing
        expect(find.text('Unlock Premium'), findsNothing);
      });

      testWidgets('shows usage info when expanded for basic plan', (
        WidgetTester tester,
      ) async {
        final info = buildBasicInfo(usageCount: 3);
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Photos label
        expect(find.text('Available photos'), findsOneWidget);
        // Stories label
        expect(find.text('This month'), findsOneWidget);
        // Reset label
        expect(find.text('Resets on'), findsOneWidget);
      });

      testWidgets('does not show upgrade button for premium plan', (
        WidgetTester tester,
      ) async {
        final info = buildPremiumInfo();
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Premium plan should NOT show upgrade button
        expect(find.text('Unlock Premium'), findsNothing);
      });

      testWidgets('shows expiry info for premium plan', (
        WidgetTester tester,
      ) async {
        final info = buildPremiumInfo();
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Expiry label should be shown for premium plan
        expect(find.text('Expires on'), findsOneWidget);
      });
    });

    group('warning and recommendation', () {
      testWidgets('shows warning when usage is near limit', (
        WidgetTester tester,
      ) async {
        // 9 out of 10 = 90% usage (near limit)
        final info = buildBasicInfo(usageCount: 9);
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Warning icon should appear
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('shows recommendation for basic plan with moderate usage', (
        WidgetTester tester,
      ) async {
        // 6 out of 10 = 60% usage
        final info = buildBasicInfo(usageCount: 6);
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // Recommendation icon should appear
        expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      });

      testWidgets('no warning for low usage', (WidgetTester tester) async {
        // 2 out of 10 = 20% usage (no warning)
        final info = buildBasicInfo(usageCount: 2);
        await tester.pumpWidget(buildWidget(subscriptionInfo: info));
        await tester.pumpAndSettle();

        // Tap to expand
        await tester.tap(find.text('Subscription'));
        await tester.pumpAndSettle();

        // No warning
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
        // No recommendation
        expect(find.byIcon(Icons.lightbulb_outline_rounded), findsNothing);
      });
    });
  });
}
