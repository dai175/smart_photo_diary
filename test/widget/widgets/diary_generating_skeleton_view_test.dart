import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/screens/diary_preview/diary_generating_skeleton_view.dart';
import 'package:smart_photo_diary/ui/components/loading_shimmer.dart';

import '../../test_helpers/widget_test_helpers.dart';

void main() {
  Widget buildWidget({DateTime? date}) {
    return WidgetTestHelpers.wrapWithLocalizedApp(
      Scaffold(
        body: DiaryGeneratingSkeletonView(date: date ?? DateTime(2024, 3, 15)),
      ),
    );
  }

  group('DiaryGeneratingSkeletonView', () {
    testWidgets('renders LoadingShimmer', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('renders at least one FractionallySizedBox skeleton bar', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    testWidgets('renders hairline separator between skeleton bars', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is Container && w.constraints?.maxHeight == 0.5,
        ),
        findsOneWidget,
      );
    });

    testWidgets('does not throw when pumped with any valid date', (
      tester,
    ) async {
      await tester.pumpWidget(buildWidget(date: DateTime(2000, 1, 1)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
