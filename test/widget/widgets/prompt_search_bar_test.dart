import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/widgets/prompt_search_bar.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  group('PromptSearchBar', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildWidget({bool isExpanded = false, VoidCallback? onToggle}) {
      return WidgetTestHelpers.wrapWithLocalizedApp(
        Scaffold(
          body: PromptSearchBar(
            controller: controller,
            contextAnimation: AlwaysStoppedAnimation(isExpanded ? 1.0 : 0.0),
            isExpanded: isExpanded,
            onToggle: onToggle ?? () {},
          ),
        ),
      );
    }

    testWidgets('size transition is collapsed when isExpanded is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(isExpanded: false));
      await tester.pump();

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.sizeFactor.value, 0.0);
    });

    testWidgets('size transition is expanded when isExpanded is true', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(isExpanded: true));
      await tester.pump();

      final sizeTransition = tester.widget<SizeTransition>(
        find.byType(SizeTransition),
      );
      expect(sizeTransition.sizeFactor.value, 1.0);
    });

    testWidgets('text field is present in widget tree', (tester) async {
      await tester.pumpWidget(buildWidget(isExpanded: true));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('calls onToggle when toggle row is tapped', (tester) async {
      var toggled = false;
      await tester.pumpWidget(buildWidget(onToggle: () => toggled = true));
      await tester.pump();

      await tester.tap(find.byKey(const Key('prompt_search_bar_toggle')));
      expect(toggled, isTrue);
    });

    testWidgets('text input is reflected in controller', (tester) async {
      await tester.pumpWidget(buildWidget(isExpanded: true));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello context');
      expect(controller.text, 'Hello context');
    });

    testWidgets('chevron icon rotates when expanded', (tester) async {
      await tester.pumpWidget(buildWidget(isExpanded: true));
      await tester.pump();

      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.25);
    });

    testWidgets('chevron icon not rotated when collapsed', (tester) async {
      await tester.pumpWidget(buildWidget(isExpanded: false));
      await tester.pump();

      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0.0);
    });
  });
}
