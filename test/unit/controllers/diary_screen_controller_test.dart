import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/controllers/diary_screen_controller.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/diary_filter.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';

class MockDiaryService extends Mock implements IDiaryService {}

/// テスト用の日記エントリーを生成
DiaryEntry _createEntry(String id, {String title = 'Test', DateTime? date}) {
  final d = date ?? DateTime(2025, 1, 1, 10, 0);
  return DiaryEntry(
    id: id,
    date: d,
    title: title,
    content: 'Content for $id',
    photoIds: const ['photo_1'],
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  late MockDiaryService mockDiaryService;

  setUpAll(() {
    registerFallbackValue(DiaryFilter.empty);
  });

  setUp(() {
    ServiceLocator().clear();
    mockDiaryService = MockDiaryService();
    ServiceLocator().registerSingleton<IDiaryService>(mockDiaryService);
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  /// コントローラーを生成（コンストラクタで loadDiaryEntries が呼ばれるため、
  /// モックの設定を先に行う必要がある）
  DiaryScreenController createController() {
    return DiaryScreenController();
  }

  group('DiaryScreenController', () {
    group('初期状態', () {
      test('コンストラクタで loadDiaryEntries が呼ばれる', () async {
        final entries = [_createEntry('1'), _createEntry('2')];
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(entries));

        final controller = createController();
        // loadDiaryEntries は非同期なので待つ
        await Future.delayed(Duration.zero);

        expect(controller.diaryEntries, entries);
        expect(controller.isSearching, false);
        expect(controller.searchQuery, '');
        expect(controller.hasMore, false); // 2 < pageSize(20)

        controller.dispose();
      });

      test('初期フィルターは DiaryFilter.empty', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        expect(controller.currentFilter.isActive, false);

        controller.dispose();
      });
    });

    group('loadDiaryEntries', () {
      test('正常取得時にリストが更新される', () async {
        final entries = List.generate(5, (i) => _createEntry('entry_$i'));
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(entries));

        final controller = createController();
        await Future.delayed(Duration.zero);

        expect(controller.diaryEntries.length, 5);
        expect(controller.isLoading, false);
        expect(controller.hasError, false);

        controller.dispose();
      });

      test('IDiaryServiceエラー時にエラーが設定される', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Failure(ServiceException('DB error')));

        final controller = createController();
        await Future.delayed(Duration.zero);

        expect(controller.hasError, true);
        expect(controller.isLoading, false);

        controller.dispose();
      });

      test('例外スロー時にServiceExceptionが設定される', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('unexpected'));

        final controller = createController();
        await Future.delayed(Duration.zero);

        expect(controller.hasError, true);
        expect(controller.isLoading, false);

        controller.dispose();
      });

      test('ページサイズ分取得時に hasMore が true', () async {
        // pageSize(20)ちょうどの件数を返す → まだ次ページがある
        final entries = List.generate(20, (i) => _createEntry('entry_$i'));
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(entries));

        final controller = createController();
        await Future.delayed(Duration.zero);

        expect(controller.hasMore, true);

        controller.dispose();
      });
    });

    group('loadMore', () {
      test('追加ページが既存リストに追加される', () async {
        // 初回: 20件（hasMore=true）
        final firstPage = List.generate(20, (i) => _createEntry('p1_$i'));
        final secondPage = List.generate(5, (i) => _createEntry('p2_$i'));
        int callCount = 0;

        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? Success(firstPage) : Success(secondPage);
        });

        final controller = createController();
        await Future.delayed(Duration.zero);
        expect(controller.diaryEntries.length, 20);
        expect(controller.hasMore, true);

        // 次ページ読み込み
        await controller.loadMore();

        expect(controller.diaryEntries.length, 25);
        expect(controller.hasMore, false); // 5 < 20
        expect(controller.isLoadingMore, false);

        controller.dispose();
      });

      test('hasMore=false の場合は何もしない', () async {
        final entries = [_createEntry('1')];
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(entries));

        final controller = createController();
        await Future.delayed(Duration.zero);
        expect(controller.hasMore, false);

        await controller.loadMore();
        // getFilteredDiaryEntriesPage はコンストラクタの1回のみ
        verify(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).called(1);

        controller.dispose();
      });
    });

    group('フィルター操作', () {
      test('applyFilter でフィルターが適用されリロードされる', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        final filter = const DiaryFilter(selectedTags: {'旅行'});
        controller.applyFilter(filter);
        await Future.delayed(Duration.zero);

        expect(controller.currentFilter.selectedTags, {'旅行'});

        controller.dispose();
      });

      test('clearAllFilters でフィルターがリセットされる', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.applyFilter(const DiaryFilter(selectedTags: {'旅行'}));
        await Future.delayed(Duration.zero);
        expect(controller.currentFilter.isActive, true);

        controller.clearAllFilters();
        await Future.delayed(Duration.zero);
        expect(controller.currentFilter.isActive, false);

        controller.dispose();
      });

      test('removeTagFilter で特定タグのみ除去される', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.applyFilter(const DiaryFilter(selectedTags: {'旅行', '食事'}));
        await Future.delayed(Duration.zero);

        controller.removeTagFilter('旅行');
        await Future.delayed(Duration.zero);

        expect(controller.currentFilter.selectedTags, {'食事'});

        controller.dispose();
      });
    });

    group('検索機能', () {
      test('startSearch で検索モードになる', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.startSearch();
        expect(controller.isSearching, true);

        controller.dispose();
      });

      test('stopSearch で検索モードが終了しリロードされる', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.startSearch();
        expect(controller.isSearching, true);

        controller.stopSearch();
        // stopSearch 内部で loadDiaryEntries() が非同期で走るので待つ
        await Future.delayed(Duration.zero);

        expect(controller.isSearching, false);
        expect(controller.searchQuery, '');

        controller.dispose();
      });

      test('performSearch で検索クエリが設定される', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.performSearch('テスト');
        await Future.delayed(Duration.zero);

        expect(controller.searchQuery, 'テスト');

        controller.dispose();
      });

      test('clearSearch で検索がクリアされる', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.performSearch('テスト');
        await Future.delayed(Duration.zero);

        controller.clearSearch();
        await Future.delayed(Duration.zero);

        expect(controller.searchQuery, '');

        controller.dispose();
      });
    });

    group('getLocalizedEmptyStateMessage', () {
      test('検索中は検索結果なしメッセージを返す', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.startSearch();

        final message = controller.getLocalizedEmptyStateMessage(
          noDiariesMessage: () => 'No diaries',
          noSearchResultsMessage: (q) => 'No results for "$q"',
          noFilterResultsMessage: () => 'No filter results',
        );

        expect(message, 'No results for ""');

        controller.dispose();
      });

      test('フィルター適用時はフィルター結果なしメッセージを返す', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        controller.applyFilter(const DiaryFilter(selectedTags: {'旅行'}));
        await Future.delayed(Duration.zero);

        final message = controller.getLocalizedEmptyStateMessage(
          noDiariesMessage: () => 'No diaries',
          noSearchResultsMessage: (q) => 'No results for "$q"',
          noFilterResultsMessage: () => 'No filter results',
        );

        expect(message, 'No filter results');

        controller.dispose();
      });

      test('通常時は日記なしメッセージを返す', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        await Future.delayed(Duration.zero);

        final message = controller.getLocalizedEmptyStateMessage(
          noDiariesMessage: () => 'No diaries',
          noSearchResultsMessage: (q) => 'No results for "$q"',
          noFilterResultsMessage: () => 'No filter results',
        );

        expect(message, 'No diaries');

        controller.dispose();
      });
    });

    group('リスナー通知', () {
      test('loadDiaryEntries 完了時にリスナーが通知される', () async {
        when(
          () => mockDiaryService.getFilteredDiaryEntriesPage(
            any(),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Success([]));

        final controller = createController();
        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await Future.delayed(Duration.zero);
        expect(notifyCount, greaterThan(0));

        controller.dispose();
      });
    });
  });
}
