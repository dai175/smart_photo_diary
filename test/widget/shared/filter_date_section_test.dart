import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/shared/filter_date_section.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  final testStart = DateTime(2025, 3, 1);
  final testEnd = DateTime(2025, 3, 15);

  Widget buildWidget({
    DateTime? startDate,
    DateTime? endDate,
    VoidCallback? onStartDateTap,
    VoidCallback? onEndDateTap,
    VoidCallback? onClear,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: FilterDateSection(
          startDate: startDate,
          endDate: endDate,
          onStartDateTap: onStartDateTap ?? () {},
          onEndDateTap: onEndDateTap ?? () {},
          onClear: onClear ?? () {},
        ),
      ),
    );
  }

  group('FilterDateSection', () {
    group('no date selected', () {
      testWidgets('shows -- placeholder for both pills', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.text('--'), findsNWidgets(2));
      });

      testWidgets('hides close icon when no dates set', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();

        expect(find.byIcon(Icons.close), findsNothing);
      });
    });

    group('dates set', () {
      testWidgets('hides -- placeholder when both dates set', (tester) async {
        await tester.pumpWidget(
          buildWidget(startDate: testStart, endDate: testEnd),
        );
        await tester.pump();

        expect(find.text('--'), findsNothing);
      });

      testWidgets('shows close icon for each pill when dates set', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildWidget(startDate: testStart, endDate: testEnd),
        );
        await tester.pump();

        expect(find.byIcon(Icons.close), findsNWidgets(2));
      });

      testWidgets('shows close icon only for start pill when only start set', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(startDate: testStart));
        await tester.pump();

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.text('--'), findsOneWidget);
      });
    });

    group('callbacks', () {
      testWidgets('fires onStartDateTap when start pill tapped', (
        tester,
      ) async {
        var called = false;
        await tester.pumpWidget(
          buildWidget(onStartDateTap: () => called = true),
        );
        await tester.pump();

        await tester.tap(find.byKey(const Key('start_date_pill')));
        expect(called, isTrue);
      });

      testWidgets('fires onEndDateTap when end pill tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onEndDateTap: () => called = true));
        await tester.pump();

        await tester.tap(find.byKey(const Key('end_date_pill')));
        expect(called, isTrue);
      });

      testWidgets('fires onClear when close icon tapped', (tester) async {
        var called = false;
        var startTapped = false;
        var endTapped = false;
        await tester.pumpWidget(
          buildWidget(
            startDate: testStart,
            endDate: testEnd,
            onClear: () => called = true,
            onStartDateTap: () => startTapped = true,
            onEndDateTap: () => endTapped = true,
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.close).first);
        expect(called, isTrue);
        expect(startTapped, isFalse);
        expect(endTapped, isFalse);
      });
    });
  });
}
