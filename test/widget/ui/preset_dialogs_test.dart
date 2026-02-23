import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/ui/components/preset_dialogs.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('PresetDialogs', () {
    group('success', () {
      testWidgets('renders with correct icon, color, title, and message', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.success(
                        context: context,
                        title: 'Success Title',
                        message: 'Operation completed successfully.',
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Success Title'), findsOneWidget);
        expect(find.text('Operation completed successfully.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('calls onConfirm when OK button is tapped', (
        WidgetTester tester,
      ) async {
        var confirmed = false;

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.success(
                        context: context,
                        title: 'Title',
                        message: 'Message',
                        onConfirm: () {
                          confirmed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(confirmed, isTrue);
      });
    });

    group('error', () {
      testWidgets('renders with error icon and color', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.error(
                        context: context,
                        title: 'Error Title',
                        message: 'Something went wrong.',
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Error Title'), findsOneWidget);
        expect(find.text('Something went wrong.'), findsOneWidget);
        expect(find.byIcon(Icons.error_rounded), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('calls onConfirm when OK button is tapped', (
        WidgetTester tester,
      ) async {
        var confirmed = false;

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.error(
                        context: context,
                        title: 'Error',
                        message: 'Error message',
                        onConfirm: () {
                          confirmed = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        expect(confirmed, isTrue);
      });
    });

    group('confirmation', () {
      testWidgets('renders with default confirm and cancel buttons', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.confirmation(
                        context: context,
                        title: 'Confirm Action',
                        message: 'Are you sure?',
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Confirm Action'), findsOneWidget);
        expect(find.text('Are you sure?'), findsOneWidget);
        expect(find.byIcon(Icons.help_rounded), findsOneWidget);
        // Default button labels from l10n
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
      });

      testWidgets('uses custom confirm and cancel text', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.confirmation(
                        context: context,
                        title: 'Delete?',
                        message: 'This cannot be undone.',
                        confirmText: 'Delete',
                        cancelText: 'Keep',
                        isDestructive: true,
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Keep'), findsOneWidget);
      });

      testWidgets('calls onConfirm and onCancel callbacks', (
        WidgetTester tester,
      ) async {
        var confirmed = false;
        var cancelled = false;

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.confirmation(
                        context: context,
                        title: 'Confirm Action',
                        message: 'Message',
                        onConfirm: () {
                          confirmed = true;
                          Navigator.of(context).pop();
                        },
                        onCancel: () {
                          cancelled = true;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Test confirm
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(confirmed, isTrue);

        // Test cancel
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(cancelled, isTrue);
      });
    });

    group('loading', () {
      testWidgets('renders with progress indicator and message', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          PresetDialogs.loading(message: 'Loading...'),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Loading...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('usageLimitReached', () {
      testWidgets('renders with limit info and reset date', (
        WidgetTester tester,
      ) async {
        final nextReset = DateTime(2026, 3, 1);

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.usageLimitReached(
                        context: context,
                        limit: 10,
                        nextResetDate: nextReset,
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.block_rounded), findsOneWidget);
        // "Not now" button
        expect(find.text('Not now'), findsOneWidget);
      });

      testWidgets('shows upgrade button when onUpgrade is provided', (
        WidgetTester tester,
      ) async {
        var upgradePressed = false;
        final nextReset = DateTime(2026, 3, 1);

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.usageLimitReached(
                        context: context,
                        limit: 10,
                        nextResetDate: nextReset,
                        onUpgrade: () {
                          upgradePressed = true;
                        },
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        // Upgrade CTA button should be present (lockedPhotoDialogCta)
        expect(find.text('Unlock Premium'), findsOneWidget);

        await tester.tap(find.text('Unlock Premium'));
        await tester.pumpAndSettle();

        expect(upgradePressed, isTrue);
      });

      testWidgets('hides upgrade button when onUpgrade is null', (
        WidgetTester tester,
      ) async {
        final nextReset = DateTime(2026, 3, 1);

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.usageLimitReached(
                        context: context,
                        limit: 10,
                        nextResetDate: nextReset,
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        // Only "Not now" button, no upgrade CTA
        expect(find.text('Unlock Premium'), findsNothing);
      });
    });

    group('usageStatus', () {
      testWidgets('renders basic plan status with upgrade button', (
        WidgetTester tester,
      ) async {
        final nextReset = DateTime(2026, 3, 1);

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.usageStatus(
                        context: context,
                        planName: 'Basic',
                        planId: 'basic',
                        usageCount: 3,
                        limit: 10,
                        nextResetDate: nextReset,
                        onUpgrade: () {},
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
        // Upgrade to Premium button should be shown for basic plan
        expect(find.text('Unlock Premium'), findsOneWidget);
      });

      testWidgets('renders premium plan status without upgrade button', (
        WidgetTester tester,
      ) async {
        final nextReset = DateTime(2026, 3, 1);

        await tester.pumpWidget(
          WidgetTestHelpers.wrapWithLocalizedApp(
            Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => PresetDialogs.usageStatus(
                        context: context,
                        planName: 'Premium',
                        planId: 'premium_monthly',
                        usageCount: 5,
                        limit: 100,
                        nextResetDate: nextReset,
                      ),
                    );
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        // Premium plan should show Close, not upgrade
        expect(find.text('Unlock Premium'), findsNothing);
        expect(find.text('Close'), findsOneWidget);
      });
    });
  });
}
