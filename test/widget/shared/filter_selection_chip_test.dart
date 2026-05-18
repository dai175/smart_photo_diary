import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/shared/filter_selection_chip.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({
    String label = 'Test',
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: FilterSelectionChip(
          label: label,
          isSelected: isSelected,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('FilterSelectionChip', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(buildWidget(label: 'flutter'));
      await tester.pump();

      expect(find.text('flutter'), findsOneWidget);
    });

    testWidgets('hides check icon when not selected', (tester) async {
      await tester.pumpWidget(buildWidget(isSelected: false));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(buildWidget(isSelected: true));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('fires onTap when tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(onTap: () => called = true));
      await tester.pump();

      await tester.tap(find.byType(FilterSelectionChip));
      expect(called, isTrue);
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(
        WidgetTestHelpers.wrapWithLocalizedApp(
          Scaffold(
            body: FilterSelectionChip(
              label: 'dark',
              isSelected: false,
              onTap: () {},
            ),
          ),
          theme: WidgetTestHelpers.createTestTheme(brightness: Brightness.dark),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('selected chip has different decoration than unselected', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(isSelected: true));
      await tester.pump();

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(FilterSelectionChip),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });
  });
}
