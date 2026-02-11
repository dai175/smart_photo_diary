import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';
import 'package:smart_photo_diary/widgets/smart_fab_widget.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';

class MockAssetEntity extends Mock implements AssetEntity {}

/// テスト用のモックAssetEntityリストを生成
List<AssetEntity> _createMockAssets(int count) {
  return List.generate(count, (i) {
    final mock = MockAssetEntity();
    when(() => mock.id).thenReturn('photo_$i');
    when(() => mock.createDateTime).thenReturn(DateTime(2025, 1, 1));
    return mock;
  });
}

/// テスト用にl10n付きMaterialAppでラップ
Widget _wrapWithApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: theme ?? ThemeData(useMaterial3: true),
    home: Scaffold(
      // Scaffoldの中にFABとして配置するのではなく、bodyに置く
      body: Center(child: child),
    ),
  );
}

void main() {
  late PhotoSelectionController photoController;

  setUp(() {
    photoController = PhotoSelectionController();
  });

  tearDown(() {
    photoController.dispose();
  });

  group('SmartFABWidget', () {
    group('表示', () {
      testWidgets('FABが表示される', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('visible=false時にFABが非表示', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              visible: false,
              heroTag: 'test_fab_hidden',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FloatingActionButton), findsNothing);
      });
    });

    group('カメラ状態（写真未選択）', () {
      testWidgets('カメラアイコンが表示される', (tester) async {
        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_camera',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
      });

      testWidgets('タップでonCameraPressedが呼ばれる', (tester) async {
        bool cameraCalled = false;

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              onCameraPressed: () => cameraCalled = true,
              heroTag: 'test_fab_camera_tap',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        expect(cameraCalled, true);
      });
    });

    group('日記作成状態（写真選択あり）', () {
      testWidgets('写真選択後にアイコンが変わる', (tester) async {
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_diary',
            ),
          ),
        );
        await tester.pumpAndSettle();

        // まだカメラアイコン
        expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);

        // 写真を選択
        photoController.toggleSelect(0);
        await tester.pumpAndSettle();

        // 日記作成アイコンに変更
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      });

      testWidgets('タップでonCreateDiaryPressedが呼ばれる', (tester) async {
        bool createDiaryCalled = false;
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              onCreateDiaryPressed: () => createDiaryCalled = true,
              heroTag: 'test_fab_diary_tap',
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

        expect(createDiaryCalled, true);
      });
    });

    group('色', () {
      testWidgets('カメラ状態でprimaryカラーが使用される', (tester) async {
        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(),
        );

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_color_camera',
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.backgroundColor, const ColorScheme.light().primary);
      });

      testWidgets('日記作成状態でtertiaryカラーが使用される', (tester) async {
        final theme = ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(),
        );
        final mockAssets = _createMockAssets(3);
        photoController.setPhotoAssets(mockAssets);
        photoController.toggleSelect(0);

        await tester.pumpWidget(
          _wrapWithApp(
            SmartFABWidget(
              photoController: photoController,
              heroTag: 'test_fab_color_diary',
            ),
            theme: theme,
          ),
        );
        await tester.pumpAndSettle();

        final fab = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
        );
        expect(fab.backgroundColor, const ColorScheme.light().tertiary);
      });
    });
  });
}
