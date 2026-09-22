import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/home_controller.dart';
import 'package:smart_photo_diary/controllers/home_data_loader.dart';
import 'package:smart_photo_diary/controllers/photo_selection_controller.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/models/diary_change.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/models/photo_type_filter.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/subscription_service_interface.dart';

class MockPhotoService extends Mock implements IPhotoService {}

class MockSubscriptionService extends Mock implements ISubscriptionService {}

class MockLoggingService extends Mock implements ILoggingService {}

class MockDiaryService extends Mock implements IDiaryService {}

class MockAssetEntity extends Mock implements AssetEntity {}

MockAssetEntity mockPhoto(String id) {
  final photo = MockAssetEntity();
  when(() => photo.id).thenReturn(id);
  when(() => photo.createDateTime).thenReturn(DateTime.now());
  return photo;
}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2020));
  });
  late MockPhotoService photoService;
  late MockSubscriptionService subscriptionService;
  late MockLoggingService logger;
  late MockDiaryService diaryService;
  late PhotoSelectionController photoController;
  late HomeController homeController;
  late HomeDataLoader loader;
  var mounted = true;

  HomeDataLoader buildLoader() {
    return HomeDataLoader(
      photoService: photoService,
      subscriptionService: subscriptionService,
      logger: logger,
      photoController: photoController,
      homeController: homeController,
      isMounted: () => mounted,
      photoTypeFilter: PhotoTypeFilter.all,
      onLimitedAccess: () async {},
      diaryService: diaryService,
      resolveDiaryService: () async => diaryService,
    );
  }

  setUp(() {
    photoService = MockPhotoService();
    subscriptionService = MockSubscriptionService();
    logger = MockLoggingService();
    diaryService = MockDiaryService();
    photoController = PhotoSelectionController();
    homeController = HomeController();
    mounted = true;

    when(
      () => logger.info(any(), context: any(named: 'context')),
    ).thenReturn(null);
    when(
      () => logger.warning(any(), context: any(named: 'context')),
    ).thenReturn(null);
    when(
      () => logger.error(
        any(),
        context: any(named: 'context'),
        error: any(named: 'error'),
      ),
    ).thenReturn(null);

    when(
      () => subscriptionService.getCurrentPlanClass(),
    ).thenAnswer((_) async => Success(BasicPlan()));
    when(
      () => diaryService.getSortedDiaryEntries(
        descending: any(named: 'descending'),
      ),
    ).thenAnswer((_) async => const Success(<DiaryEntry>[]));
    when(
      () => diaryService.changes,
    ).thenAnswer((_) => const Stream<DiaryChange>.empty());

    loader = buildLoader();
  });

  tearDown(() {
    loader.dispose();
    photoController.dispose();
    homeController.dispose();
  });

  group('HomeDataLoader', () {
    test('syncAccessibleDays applies Basic plan access window', () async {
      final oldPhoto = MockAssetEntity();
      when(() => oldPhoto.id).thenReturn('old');
      when(
        () => oldPhoto.createDateTime,
      ).thenReturn(DateTime.now().subtract(const Duration(days: 30)));

      await loader.syncAccessibleDays();

      expect(photoController.isPhotoLocked(oldPhoto), isTrue);
    });

    test('syncAccessibleDays unlocks 30-day photos on Premium', () async {
      when(
        () => subscriptionService.getCurrentPlanClass(),
      ).thenAnswer((_) async => Success(PremiumMonthlyPlan()));
      final oldPhoto = MockAssetEntity();
      when(() => oldPhoto.id).thenReturn('old');
      when(
        () => oldPhoto.createDateTime,
      ).thenReturn(DateTime.now().subtract(const Duration(days: 30)));

      await loader.syncAccessibleDays();

      expect(photoController.isPhotoLocked(oldPhoto), isFalse);
    });

    test(
      'syncAccessibleDays defaults to 1 day when plan lookup fails',
      () async {
        when(
          () => subscriptionService.getCurrentPlanClass(),
        ).thenThrow(Exception('plan lookup failed'));
        final yesterday = MockAssetEntity();
        when(() => yesterday.id).thenReturn('y');
        when(
          () => yesterday.createDateTime,
        ).thenReturn(DateTime.now().subtract(const Duration(days: 1)));
        final oldPhoto = MockAssetEntity();
        when(() => oldPhoto.id).thenReturn('old');
        when(
          () => oldPhoto.createDateTime,
        ).thenReturn(DateTime.now().subtract(const Duration(days: 30)));

        await loader.syncAccessibleDays();

        expect(photoController.isPhotoLocked(yesterday), isFalse);
        expect(photoController.isPhotoLocked(oldPhoto), isTrue);
      },
    );

    test(
      'loadTodayPhotos denies permission without a Settings callback',
      () async {
        when(
          () => photoService.requestPermission(),
        ).thenAnswer((_) async => const Success(false));

        await loader.loadTodayPhotos();

        expect(photoController.hasPermission, isFalse);
        expect(photoController.isLoading, isFalse);
        expect(photoController.photoAssets, isEmpty);
      },
    );

    test('loadTodayPhotos applies access days then stores photos', () async {
      final photo = MockAssetEntity();
      when(() => photo.id).thenReturn('p1');
      when(() => photo.createDateTime).thenReturn(DateTime.now());
      when(
        () => photoService.requestPermission(),
      ).thenAnswer((_) async => const Success(true));
      when(
        () => photoService.getPhotosInDateRange(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Success([photo]));
      when(
        () => photoService.getPhotosEfficient(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Success([]));

      await loader.loadTodayPhotos();
      await Future<void>.delayed(Duration.zero);

      expect(photoController.hasPermission, isTrue);
      expect(photoController.photoAssets.map((p) => p.id), ['p1']);
      verify(() => subscriptionService.getCurrentPlanClass()).called(1);
    });

    test('loadUsedPhotoIds collects diary photo ids', () async {
      final now = DateTime.now();
      when(
        () => diaryService.getSortedDiaryEntries(
          descending: any(named: 'descending'),
        ),
      ).thenAnswer(
        (_) async => Success([
          DiaryEntry(
            id: 'd1',
            date: now,
            title: 't',
            content: 'c',
            photoIds: const ['a', 'b'],
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );

      await loader.loadUsedPhotoIds();

      expect(photoController.usedPhotoIds, {'a', 'b'});
    });

    test('subscribeDiaryChanges adds used ids on created events', () async {
      final controller = StreamController<DiaryChange>.broadcast();
      addTearDown(controller.close);
      when(() => diaryService.changes).thenAnswer((_) => controller.stream);

      await loader.subscribeDiaryChanges();
      controller.add(
        DiaryChange(
          type: DiaryChangeType.created,
          entryId: 'e1',
          addedPhotoIds: const ['new'],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(photoController.usedPhotoIds, contains('new'));
    });

    test('onDiaryCreated refreshes diary/stats keys', () async {
      final oldDiary = homeController.diaryScreenKey;
      final oldStats = homeController.statsScreenKey;

      await loader.onDiaryCreated();

      expect(homeController.diaryScreenKey, isNot(oldDiary));
      expect(homeController.statsScreenKey, isNot(oldStats));
    });

    test(
      'loadMorePhotos appends a page, advances offset, and keeps selection',
      () async {
        final existing = mockPhoto('p1');
        final nextA = mockPhoto('p2');
        final nextB = mockPhoto('p3');
        photoController.setPhotoAssets([existing]);
        photoController.toggleSelect(0);
        photoController.setHasMorePhotos(true);
        photoController.setLoading(false);

        final offsets = <int>[];
        final inFlight = Completer<Result<List<AssetEntity>>>();
        var callCount = 0;
        when(
          () => photoService.getPhotosEfficient(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((invocation) {
          final offset = invocation.namedArguments[#offset] as int;
          offsets.add(offset);
          callCount++;
          if (callCount == 1) {
            return inFlight.future;
          }
          return Future.value(const Success([]));
        });

        final pending = loader.loadMorePhotos();
        await Future<void>.delayed(Duration.zero);
        expect(photoController.isLoading, isTrue);

        inFlight.complete(Success([nextA, nextB]));
        await pending;

        expect(photoController.isLoading, isFalse);
        expect(photoController.hasMorePhotos, isTrue);
        expect(photoController.photoAssets.map((p) => p.id), [
          'p1',
          'p2',
          'p3',
        ]);
        expect(photoController.selected, [true, false, false]);
        expect(offsets, [0]);

        await loader.loadMorePhotos();
        expect(offsets, [0, 2]);
        expect(photoController.hasMorePhotos, isFalse);
        expect(photoController.photoAssets.map((p) => p.id), [
          'p1',
          'p2',
          'p3',
        ]);
      },
    );

    test(
      'loadMorePhotos empty terminal page clears loading and stops paging',
      () async {
        final existing = mockPhoto('p1');
        photoController.setPhotoAssets([existing]);
        photoController.setHasMorePhotos(true);
        photoController.setLoading(false);

        var fetchCount = 0;
        when(
          () => photoService.getPhotosEfficient(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            offset: any(named: 'offset'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async {
          fetchCount++;
          return const Success([]);
        });

        await loader.loadMorePhotos();

        expect(photoController.isLoading, isFalse);
        expect(photoController.hasMorePhotos, isFalse);
        expect(photoController.photoAssets.map((p) => p.id), ['p1']);
        expect(fetchCount, 1);

        await loader.loadMorePhotos();
        expect(fetchCount, 1);
      },
    );
  });
}
