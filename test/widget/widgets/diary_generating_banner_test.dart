import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/writing_prompt.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_generating_banner.dart';

import '../../test_helpers/widget_test_helpers.dart';

WritingPrompt _makePrompt({PromptCategory category = PromptCategory.emotion}) {
  return WritingPrompt(
    id: 'p1',
    text: 'Test prompt',
    category: category,
    isPremiumOnly: false,
  );
}

void main() {
  Widget buildWidget({
    int photoCount = 1,
    WritingPrompt? selectedPrompt,
    String statusText = 'Generating...',
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: DiaryGeneratingBanner(
          photoCount: photoCount,
          selectedPrompt: selectedPrompt,
          statusText: statusText,
        ),
      ),
    );
  }

  group('DiaryGeneratingBanner', () {
    testWidgets('displays statusText', (tester) async {
      await tester.pumpWidget(buildWidget(statusText: 'AIが日記を作成中...'));
      await tester.pump();

      expect(find.text('AIが日記を作成中...'), findsOneWidget);
    });

    testWidgets('renders LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders pulsing disc icon', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });

    testWidgets('renders with selectedPrompt null without error', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(photoCount: 2, selectedPrompt: null));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with selectedPrompt set without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildWidget(photoCount: 1, selectedPrompt: _makePrompt()),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes animation controller without error', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });
}
