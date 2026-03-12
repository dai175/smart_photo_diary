import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/widgets/diary_card_widget.dart';

class MockPhotoCacheService extends Mock implements IPhotoCacheService {}

class MockPhotoService extends Mock implements IPhotoService {}

class MockAssetEntity extends Mock implements AssetEntity {}

/// テスト用の日記エントリーを生成
DiaryEntry _createEntry({
  String id = 'test-1',
  String title = 'Test Title',
  String content = 'Test content for diary card.',
  DateTime? date,
  List<String> photoIds = const [],
  List<String>? tags,
}) {
  final d = date ?? DateTime(2025, 6, 15, 10, 30);
  return DiaryEntry(
    id: id,
    date: d,
    title: title,
    content: content,
    photoIds: photoIds,
    createdAt: d,
    updatedAt: d,
    tags: tags,
  );
}

/// l10n付きMaterialAppでラップ
Widget _wrapWithApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  late MockPhotoCacheService mockPhotoCacheService;
  late MockPhotoService mockPhotoService;

  setUp(() {
    ServiceLocator().clear();
    mockPhotoCacheService = MockPhotoCacheService();
    mockPhotoService = MockPhotoService();
    ServiceLocator().registerSingleton<IPhotoCacheService>(
      mockPhotoCacheService,
    );
    ServiceLocator().registerSingleton<IPhotoService>(mockPhotoService);

    // Default: getAssetsByIds returns empty list
    when(
      () => mockPhotoService.getAssetsByIds(any()),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  group('DiaryCardWidget', () {
    group('表示', () {
      testWidgets('タイトルが表示される', (tester) async {
        final entry = _createEntry(title: 'My Diary', photoIds: []);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Diary'), findsOneWidget);
      });

      testWidgets('コンテンツが表示される', (tester) async {
        final entry = _createEntry(content: 'A beautiful day.', photoIds: []);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('A beautiful day.'), findsOneWidget);
      });

      testWidgets('タイトル空時にUntitledフォールバック', (tester) async {
        final entry = _createEntry(title: '', photoIds: []);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        // English locale: 'Untitled' or similar from l10n
        expect(find.text(''), findsNothing);
        // タイトルテキストウィジェットが存在することを確認
        // （l10nのdiaryCardUntitledの値に依存）
        final titleFinder = find.byType(Text);
        expect(titleFinder, findsWidgets);
      });

      testWidgets('日付が表示される', (tester) async {
        final entry = _createEntry(date: DateTime(2025, 6, 15), photoIds: []);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        // 日付テキストが表示される（バッジからプレーンテキストに変更）
        expect(find.textContaining('6/15'), findsOneWidget);
      });
    });

    group('タップ', () {
      testWidgets('onTapコールバックが呼ばれる', (tester) async {
        bool tapped = false;
        final entry = _createEntry(photoIds: []);

        await tester.pumpWidget(
          _wrapWithApp(
            DiaryCardWidget(entry: entry, onTap: () => tapped = true),
          ),
        );
        await tester.pumpAndSettle();

        // カード全体をタップ
        await tester.tap(find.byType(DiaryCardWidget));
        await tester.pump();

        expect(tapped, true);
      });
    });

    group('タグ', () {
      testWidgets('タグが正しく表示される', (tester) async {
        final entry = _createEntry(photoIds: [], tags: ['Morning', 'Happy']);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('Morning'), findsOneWidget);
        expect(find.text('Happy'), findsOneWidget);
      });

      testWidgets('タグが即表示される（非同期取得なし）', (tester) async {
        final entry = _createEntry(photoIds: [], tags: ['Cached1', 'Cached2']);

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        // pumpWidget直後にアサート（初回フレームでちらつきがないことを検証）

        expect(find.text('Cached1'), findsOneWidget);
        expect(find.text('Cached2'), findsOneWidget);
        // 「Generating tags...」が表示されないことを確認
        expect(find.text('Generating tags...'), findsNothing);
      });

      testWidgets('タグなし日記ではタグチップが表示されない', (tester) async {
        final entry = _createEntry(
          date: DateTime(2025, 6, 15, 10, 0),
          photoIds: [],
        );

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        // スピナーが表示されないことを確認
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Generating tags...'), findsNothing);
      });
    });
  });
}
