import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/ui/components/loading_state_card.dart';

void main() {
  group('LoadingStateCard', () {
    testWidgets('タイトルとサブタイトルを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoadingStateCard(
                title: 'Loading Title',
                subtitle: 'Loading Subtitle',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Loading Title'), findsOneWidget);
      expect(find.text('Loading Subtitle'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('カスタムインジケーターカラーを適用する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoadingStateCard(
                title: 'Title',
                subtitle: 'Subtitle',
                indicatorColor: Colors.red,
              ),
            ),
          ),
        ),
      );

      final container =
          tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (c) =>
            c.decoration is BoxDecoration &&
            (c.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, Colors.red);
    });
  });
}
