import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/screens/statistics/diary_selection_dialog.dart';

import '../../../test_helpers/mock_platform_channels.dart';
import '../../../test_helpers/widget_test_helpers.dart';

void main() {
  final selectedDay = DateTime(2025, 6, 15);

  DiaryEntry makeEntry({
    String id = 'id1',
    String title = 'My Diary',
    String content = 'Some content',
  }) {
    final now = DateTime(2025, 6, 15, 10);
    return DiaryEntry(
      id: id,
      date: now,
      title: title,
      content: content,
      photoIds: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildHost({
    required List<DiaryEntry> diaries,
    Brightness brightness = Brightness.light,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDiarySelectionDialog(context, diaries, selectedDay),
            child: const Text('Open'),
          ),
        ),
      ),
      theme: WidgetTestHelpers.createTestTheme(brightness: brightness),
    );
  }

  setUpAll(() {
    MockPlatformChannels.setupMocks();
  });

  tearDownAll(() {
    MockPlatformChannels.clearMocks();
  });

  group('showDiarySelectionDialog', () {
    testWidgets('shows diary count in dialog message', (tester) async {
      final diaries = [makeEntry(), makeEntry(id: 'id2', title: 'Second')];
      await tester.pumpWidget(buildHost(diaries: diaries));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('displays diary titles', (tester) async {
      final diaries = [
        makeEntry(title: 'Morning Walk'),
        makeEntry(id: 'id2', title: 'Evening Thoughts'),
      ];
      await tester.pumpWidget(buildHost(diaries: diaries));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Morning Walk'), findsOneWidget);
      expect(find.text('Evening Thoughts'), findsOneWidget);
    });

    testWidgets('shows Untitled for diary with empty title', (tester) async {
      final diaries = [makeEntry(title: '')];
      await tester.pumpWidget(buildHost(diaries: diaries));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Untitled'), findsOneWidget);
    });

    testWidgets('displays index numbers for each diary', (tester) async {
      final diaries = [
        makeEntry(title: 'First'),
        makeEntry(id: 'id2', title: 'Second'),
      ];
      await tester.pumpWidget(buildHost(diaries: diaries));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('close button dismisses the dialog', (tester) async {
      await tester.pumpWidget(buildHost(diaries: [makeEntry()]));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('renders without error in dark mode', (tester) async {
      await tester.pumpWidget(
        buildHost(diaries: [makeEntry()], brightness: Brightness.dark),
      );
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
