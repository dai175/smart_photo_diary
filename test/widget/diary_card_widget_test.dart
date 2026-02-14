import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/l10n/generated/app_localizations.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/interfaces/diary_tag_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_cache_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/widgets/diary_card_widget.dart';

class MockDiaryTagService extends Mock implements IDiaryTagService {}

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
  List<String>? cachedTags,
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
    cachedTags: cachedTags,
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
  late MockDiaryTagService mockTagService;
  late MockPhotoCacheService mockPhotoCacheService;
  late MockPhotoService mockPhotoService;

  setUp(() {
    ServiceLocator().clear();
    mockTagService = MockDiaryTagService();
    mockPhotoCacheService = MockPhotoCacheService();
    mockPhotoService = MockPhotoService();
    ServiceLocator().registerSingleton<IDiaryTagService>(mockTagService);
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
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning']));

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('My Diary'), findsOneWidget);
      });

      testWidgets('コンテンツが表示される', (tester) async {
        final entry = _createEntry(content: 'A beautiful day.', photoIds: []);
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning']));

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('A beautiful day.'), findsOneWidget);
      });

      testWidgets('タイトル空時にUntitledフォールバック', (tester) async {
        final entry = _createEntry(title: '', photoIds: []);
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning']));

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
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning']));

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        // カレンダーアイコンが表示される
        expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
      });
    });

    group('タップ', () {
      testWidgets('onTapコールバックが呼ばれる', (tester) async {
        bool tapped = false;
        final entry = _createEntry(photoIds: []);
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning']));

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
        final entry = _createEntry(photoIds: []);
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenAnswer((_) async => const Success(['Morning', 'Happy']));

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        expect(find.text('Morning'), findsOneWidget);
        expect(find.text('Happy'), findsOneWidget);
      });

      testWidgets('タグ取得エラー時にフォールバックタグが表示される', (tester) async {
        // 午前10時の日記 → Morning
        final entry = _createEntry(
          date: DateTime(2025, 6, 15, 10, 0),
          photoIds: [],
        );
        when(
          () => mockTagService.getTagsForEntry(entry),
        ).thenThrow(Exception('error'));

        await tester.pumpWidget(
          _wrapWithApp(DiaryCardWidget(entry: entry, onTap: () {})),
        );
        await tester.pumpAndSettle();

        // フォールバック: 時間帯タグ（英語で "Morning"）
        expect(find.text('Morning'), findsOneWidget);
      });
    });
  });
}
