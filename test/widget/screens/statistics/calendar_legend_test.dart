import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/screens/statistics/calendar_legend.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({Brightness brightness = Brightness.light}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      const Scaffold(body: SingleChildScrollView(child: CalendarLegend())),
      theme: WidgetTestHelpers.createTestTheme(brightness: brightness),
    );
  }

  Future<void> pumpLegend(WidgetTester tester) async {
    await tester.pumpWidget(buildWidget());
    await tester.pump();
  }

  group('CalendarLegend', () {
    testWidgets('renders four legend items', (tester) async {
      await pumpLegend(tester);

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows localized Entry label', (tester) async {
      await pumpLegend(tester);
      final l10n = WidgetTestHelpers.getL10n(
        tester,
        find.byType(CalendarLegend),
      );
      expect(
        find.textContaining(
          l10n.statisticsCalendarLegendEntry.toUpperCase(),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows localized Multiple label', (tester) async {
      await pumpLegend(tester);
      final l10n = WidgetTestHelpers.getL10n(
        tester,
        find.byType(CalendarLegend),
      );
      expect(
        find.textContaining(
          l10n.statisticsCalendarLegendMultiple.toUpperCase(),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows localized Today label', (tester) async {
      await pumpLegend(tester);
      final l10n = WidgetTestHelpers.getL10n(
        tester,
        find.byType(CalendarLegend),
      );
      expect(
        find.textContaining(
          l10n.statisticsCalendarLegendToday.toUpperCase(),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows localized Selected label', (tester) async {
      await pumpLegend(tester);
      final l10n = WidgetTestHelpers.getL10n(
        tester,
        find.byType(CalendarLegend),
      );
      expect(
        find.textContaining(
          l10n.statisticsCalendarLegendSelected.toUpperCase(),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(buildWidget(brightness: Brightness.dark));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
