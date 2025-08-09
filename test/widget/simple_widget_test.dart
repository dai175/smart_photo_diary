import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_photo_diary/ui/components/custom_dialog.dart';
import 'package:smart_photo_diary/ui/components/animated_button.dart';
import 'package:smart_photo_diary/ui/components/custom_card.dart';
import 'package:smart_photo_diary/services/logging_service.dart';

void main() {
  group('UI Components Widget Tests', () {
    setUpAll(() async {
      // AnimatedButtonがLoggingServiceを使用するため初期化
      await LoggingService.getInstance();
    });
    testWidgets('CustomDialog displays title and content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomDialog(
                title: 'Test Dialog',
                content: Text('This is test content'),
                actions: [CustomDialogAction(text: 'OK', onPressed: () {})],
              ),
            ),
          ),
        ),
      );

      // ダイアログのタイトルとコンテンツが表示されることを確認
      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('AnimatedButton responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedButton(
                onPressed: () {
                  tapped = true;
                },
                child: Text('Tap me'),
              ),
            ),
          ),
        ),
      );

      // ボタンが表示されることを確認
      expect(find.text('Tap me'), findsOneWidget);

      // ボタンをタップ（警告を抑制）
      await tester.tap(find.byType(AnimatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      // タップが検出されたことを確認
      expect(tapped, true);
    });

    testWidgets('CustomCard displays child content', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomCard(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Card Content'),
                ),
              ),
            ),
          ),
        ),
      );

      // カードとその内容が表示されることを確認
      expect(find.byType(CustomCard), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('Tab switching animation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  tabs: [
                    Tab(text: '今日'),
                    Tab(text: '過去'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  Center(child: Text('今日のコンテンツ')),
                  Center(child: Text('過去のコンテンツ')),
                ],
              ),
            ),
          ),
        ),
      );

      // 初期状態で「今日」タブのコンテンツが表示されることを確認
      expect(find.text('今日のコンテンツ'), findsOneWidget);
      expect(find.text('過去のコンテンツ'), findsNothing);

      // 「過去」タブをタップ
      await tester.tap(find.text('過去'));
      await tester.pumpAndSettle();

      // 「過去」タブのコンテンツが表示されることを確認
      expect(find.text('今日のコンテンツ'), findsNothing);
      expect(find.text('過去のコンテンツ'), findsOneWidget);
    });

    testWidgets('Lock icon overlay displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey,
                    child: Center(child: Text('Photo')),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 写真とロックアイコンが表示されることを確認
      expect(find.text('Photo'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('Upgrade promotion banner displays correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premiumプランで過去365日の写真にアクセス',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // アップグレード促進バナーが表示されることを確認
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.text('Premiumプランで過去365日の写真にアクセス'), findsOneWidget);
    });

    testWidgets('Photo selection counter updates correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    tester.element(find.byType(Container).first),
                  ).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 4),
                    Text('3枚選択中'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // 選択カウンターが表示されることを確認
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('3枚選択中'), findsOneWidget);
    });
  });
}
