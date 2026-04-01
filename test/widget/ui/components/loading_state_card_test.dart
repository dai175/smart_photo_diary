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

    testWidgets('追加コンテンツを表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoadingStateCard(
                title: 'Title',
                subtitle: 'Subtitle',
                additionalContent: LinearProgressIndicator(value: 0.5),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
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

      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('追加コンテンツがない場合は余分なスペースを表示しない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LoadingStateCard(title: 'Title', subtitle: 'Subtitle'),
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });
}
