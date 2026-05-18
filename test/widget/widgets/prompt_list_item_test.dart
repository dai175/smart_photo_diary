import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/widgets/prompt_list_item.dart';

import '../../test_helpers/widget_test_helpers.dart';

WritingPrompt _makePrompt({
  String id = 'p1',
  String text = 'What made you smile today?',
  PromptCategory category = PromptCategory.emotion,
  bool isPremiumOnly = false,
  String? description,
}) {
  return WritingPrompt(
    id: id,
    text: text,
    category: category,
    isPremiumOnly: isPremiumOnly,
    description: description,
  );
}

void main() {
  Widget buildWidget({
    required WritingPrompt prompt,
    bool isSelected = false,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: PromptListItem(
          prompt: prompt,
          isSelected: isSelected,
          isPremium: isPremium,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('PromptListItem', () {
    testWidgets('displays prompt text', (tester) async {
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(text: 'What made you smile today?')),
      );
      await tester.pump();

      expect(find.text('What made you smile today?'), findsOneWidget);
    });

    testWidgets('displays description when present', (tester) async {
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(description: 'A helpful description')),
      );
      await tester.pump();

      expect(find.text('A helpful description'), findsOneWidget);
    });

    testWidgets('shows check icon when selected', (tester) async {
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(), isSelected: true),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides check icon when not selected', (tester) async {
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(), isSelected: false),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets(
      'shows premium badge for premium prompt when not premium user',
      (tester) async {
        await tester.pumpWidget(
          buildWidget(
            prompt: _makePrompt(isPremiumOnly: true),
            isPremium: false,
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      },
    );

    testWidgets('hides premium badge for premium prompt when premium user', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(isPremiumOnly: true), isPremium: true),
      );
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('hides premium badge for non-premium prompt', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          prompt: _makePrompt(isPremiumOnly: false),
          isPremium: false,
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.lock_outline), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        buildWidget(prompt: _makePrompt(), onTap: () => tapped = true),
      );
      await tester.pump();

      await tester.tap(find.byType(PromptListItem));
      expect(tapped, isTrue);
    });
  });
}
