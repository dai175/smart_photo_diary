import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/screens/diary_detail/diary_detail_action_bar.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({
    bool canShowActions = true,
    VoidCallback? onBack,
    VoidCallback? onShare,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: Stack(
          children: [
            DiaryDetailActionBar(
              canShowActions: canShowActions,
              onBack: onBack ?? () {},
              onShare: onShare ?? () {},
              onEdit: onEdit ?? () {},
              onDelete: onDelete ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  group('DiaryDetailActionBar', () {
    group('Back button', () {
      testWidgets('always shows back button regardless of canShowActions', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(canShowActions: false));
        await tester.pump();
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      });

      testWidgets('fires onBack when back button tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onBack: () => called = true));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        expect(called, isTrue);
      });
    });

    group('Action buttons visibility', () {
      testWidgets('hides share, edit, more when canShowActions is false', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(canShowActions: false));
        await tester.pump();
        expect(find.byIcon(Icons.share_rounded), findsNothing);
        expect(find.byIcon(Icons.edit_rounded), findsNothing);
        expect(find.byIcon(Icons.more_horiz_rounded), findsNothing);
      });

      testWidgets('shows share, edit, more when canShowActions is true', (
        tester,
      ) async {
        await tester.pumpWidget(buildWidget(canShowActions: true));
        await tester.pump();
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);
        expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
        expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
      });
    });

    group('Action button callbacks', () {
      testWidgets('fires onShare when share button tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onShare: () => called = true));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.share_rounded));
        expect(called, isTrue);
      });

      testWidgets('fires onEdit when edit button tapped', (tester) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onEdit: () => called = true));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.edit_rounded));
        expect(called, isTrue);
      });
    });

    group('More menu', () {
      testWidgets('opens bottom sheet showing delete option', (tester) async {
        await tester.pumpWidget(buildWidget());
        await tester.pump();
        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
      });

      testWidgets('fires onDelete when delete tapped in bottom sheet', (
        tester,
      ) async {
        var called = false;
        await tester.pumpWidget(buildWidget(onDelete: () => called = true));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.more_horiz_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.delete_rounded));
        await tester.pumpAndSettle();
        expect(called, isTrue);
      });
    });
  });
}
