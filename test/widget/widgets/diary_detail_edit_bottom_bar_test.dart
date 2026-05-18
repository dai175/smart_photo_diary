import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/screens/diary_detail/diary_detail_edit_bottom_bar.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({
    VoidCallback? onCancel,
    Future<void> Function()? onSave,
    ThemeData? theme,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        bottomNavigationBar: DiaryDetailEditBottomBar(
          onCancel: onCancel ?? () {},
          onSave: onSave ?? () async {},
        ),
        body: const SizedBox(),
      ),
      theme: theme,
    );
  }

  group('DiaryDetailEditBottomBar', () {
    testWidgets('shows Cancel and Save buttons', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('fires onCancel when Cancel tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(buildWidget(onCancel: () => called = true));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('fires onSave when Save tapped', (tester) async {
      var called = false;
      await tester.pumpWidget(
        buildWidget(
          onSave: () async {
            called = true;
          },
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          theme: WidgetTestHelpers.createTestTheme(brightness: Brightness.dark),
        ),
      );
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });
  });
}
