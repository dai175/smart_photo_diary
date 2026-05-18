import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/shared/filter_time_of_day_section.dart';
import 'package:smart_photo_diary/shared/filter_selection_chip.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({
    Set<TimeOfDayPeriod> selectedPeriods = const {},
    ValueChanged<TimeOfDayPeriod>? onPeriodToggled,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: FilterTimeOfDaySection(
          selectedPeriods: selectedPeriods,
          onPeriodToggled: onPeriodToggled ?? (_) {},
        ),
      ),
    );
  }

  group('FilterTimeOfDaySection', () {
    testWidgets('shows all 4 time period chips', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(FilterSelectionChip), findsNWidgets(4));
    });

    testWidgets('shows no check icons when no periods selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(selectedPeriods: {}));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows check icon for selected morning period', (tester) async {
      await tester.pumpWidget(
        buildWidget(selectedPeriods: {TimeOfDayPeriod.morning}),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('shows check icons matching count of selected periods', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(
          selectedPeriods: {TimeOfDayPeriod.morning, TimeOfDayPeriod.night},
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('fires onPeriodToggled with morning when first chip tapped', (
      tester,
    ) async {
      TimeOfDayPeriod? toggled;
      await tester.pumpWidget(buildWidget(onPeriodToggled: (p) => toggled = p));
      await tester.pump();

      await tester.tap(find.byType(FilterSelectionChip).first);
      expect(toggled, TimeOfDayPeriod.morning);
    });

    testWidgets('fires onPeriodToggled with night when last chip tapped', (
      tester,
    ) async {
      TimeOfDayPeriod? toggled;
      await tester.pumpWidget(buildWidget(onPeriodToggled: (p) => toggled = p));
      await tester.pump();

      await tester.tap(find.byType(FilterSelectionChip).last);
      expect(toggled, TimeOfDayPeriod.night);
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithLocalizedApp(
          Scaffold(
            body: FilterTimeOfDaySection(
              selectedPeriods: {TimeOfDayPeriod.evening},
              onPeriodToggled: (_) {},
            ),
          ),
          theme: WidgetTestHelpers.createTestTheme(brightness: Brightness.dark),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
