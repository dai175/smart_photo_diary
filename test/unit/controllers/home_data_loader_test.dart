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
  var permissionDeniedCalls = 0;

  HomeDataLoader buildLoader() {
    return HomeDataLoader(
      photoService: photoService,
      subscriptionService: subscriptionService,
      logger: logger,
      photoController: photoController,
      homeController: homeController,
      isMounted: () => mounted,
      photoTypeFilter: PhotoTypeFilter.all,
      onPermissionDenied: () async {
        permissionDeniedCalls++;
      },
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
    permissionDeniedCalls = 0;

    when(
      () => logger.info(any(), context: any(named: 'context')),
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

    test('loadTodayPhotos denies permission and notifies UI', () async {
      when(
        () => photoService.requestPermission(),
      ).thenAnswer((_) async => const Success(false));

      await loader.loadTodayPhotos();

      expect(photoController.hasPermission, isFalse);
      expect(photoController.isLoading, isFalse);
      expect(permissionDeniedCalls, 1);
    });

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
  });
}
