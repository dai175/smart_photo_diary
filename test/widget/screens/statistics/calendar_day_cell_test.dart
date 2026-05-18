import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/screens/statistics/calendar_day_cell.dart';
import 'package:smart_photo_diary/ui/design_system/app_colors.dart';

import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  final testDay = DateTime(2025, 6, 15);

  Widget buildWidget({DateTime? day}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: Center(child: CalendarDayCell(day: day ?? testDay)),
      ),
    );
  }

  group('CalendarDayCell', () {
    testWidgets('displays the day number', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('${testDay.day}'), findsOneWidget);
    });

    testWidgets('uses calEntryBg color as background decoration', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(CalendarDayCell),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppColors.calEntryBg);
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('uses onSurface theme color for day text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final text = tester.widget<Text>(find.text('${testDay.day}'));
      expect(text.style?.color, isNotNull);
    });

    testWidgets('renders day 1 correctly', (tester) async {
      await tester.pumpWidget(buildWidget(day: DateTime(2025, 1, 1)));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithLocalizedApp(
          Scaffold(
            body: Center(child: CalendarDayCell(day: testDay)),
          ),
          theme: WidgetTestHelpers.createTestTheme(brightness: Brightness.dark),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('${testDay.day}'), findsOneWidget);
    });
  });
}
