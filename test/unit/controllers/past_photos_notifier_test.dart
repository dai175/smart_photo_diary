import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/past_photos_notifier.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_access_control_service_interface.dart';
import 'package:smart_photo_diary/core/result/result.dart';

// モック
class MockPhotoService extends Mock implements PhotoServiceInterface {}

class MockPhotoAccessControlService extends Mock
    implements PhotoAccessControlServiceInterface {}

class MockAssetEntity extends Mock implements AssetEntity {}

void main() {
  late PastPhotosNotifier notifier;
  late MockPhotoService mockPhotoService;
  late MockPhotoAccessControlService mockAccessControlService;

  setUp(() {
    mockPhotoService = MockPhotoService();
    mockAccessControlService = MockPhotoAccessControlService();

    notifier = PastPhotosNotifier(
      photoService: mockPhotoService,
      accessControlService: mockAccessControlService,
    );
  });

  tearDown(() {
    notifier.dispose();
  });

  group('PastPhotosNotifier', () {
    group('loadInitialPhotos', () {
      test('Basicプランで昨日の写真を読み込む', () async {
        // Arrange
        final plan = BasicPlan();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final photos = List.generate(10, (index) => MockAssetEntity());

        when(
          () => mockAccessControlService.getAccessibleDateForPlan(plan),
        ).thenReturn(yesterday);
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(photos));

        for (var i = 0; i < photos.length; i++) {
          when(
            () => photos[i].createDateTime,
          ).thenReturn(yesterday.add(Duration(hours: i)));
        }

        // Act
        await notifier.loadInitialPhotos(plan);

        // Assert
        expect(notifier.state.photos.length, 10);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.isInitialLoading, false);
        expect(notifier.state.errorMessage, isNull);
      });

      test('Premiumプランで過去1年分の写真を読み込む', () async {
        // Arrange
        final plan = PremiumMonthlyPlan();
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        final photos = List.generate(50, (index) => MockAssetEntity());

        when(
          () => mockAccessControlService.getAccessibleDateForPlan(plan),
        ).thenReturn(oneYearAgo);
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(photos));

        for (var i = 0; i < photos.length; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          when(() => photos[i].createDateTime).thenReturn(date);
        }

        // Act
        await notifier.loadInitialPhotos(plan);

        // Assert
        expect(notifier.state.photos.length, 50);
        expect(notifier.state.hasMore, true); // 50件取得したのでさらにある可能性
        expect(notifier.state.photosByMonth.isNotEmpty, true);
      });

      test('エラー時の処理', () async {
        // Arrange
        final plan = BasicPlan();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        when(
          () => mockAccessControlService.getAccessibleDateForPlan(plan),
        ).thenReturn(yesterday);
        when(
          () => mockPhotoService.getPhotosEfficient(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('写真読み込みエラー'));

        // Act
        await notifier.loadInitialPhotos(plan);

        // Assert
        expect(notifier.state.photos, isEmpty);
        expect(notifier.state.isLoading, false);
        expect(notifier.state.errorMessage, isNotNull);
      });
    });

    group('loadMorePhotos', () {
      test('追加の写真を読み込む', () async {
        // Arrange
        final plan = PremiumMonthlyPlan();
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        final initialPhotos = List.generate(50, (index) => MockAssetEntity());
        final morePhotos = List.generate(30, (index) => MockAssetEntity());

        // 初期読み込みをシミュレート
        when(
          () => mockAccessControlService.getAccessibleDateForPlan(plan),
        ).thenReturn(oneYearAgo);
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
            offset: 0,
          ),
        ).thenAnswer((_) async => Success(initialPhotos));

        for (var i = 0; i < initialPhotos.length; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          when(() => initialPhotos[i].createDateTime).thenReturn(date);
        }

        await notifier.loadInitialPhotos(plan);

        // 追加読み込みの設定
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
            offset: 50,
          ),
        ).thenAnswer((_) async => Success(morePhotos));

        for (var i = 0; i < morePhotos.length; i++) {
          final date = DateTime.now().subtract(Duration(days: 50 + i));
          when(() => morePhotos[i].createDateTime).thenReturn(date);
        }

        // Act
        await notifier.loadMorePhotos(plan);

        // Assert
        expect(notifier.state.photos.length, 80); // 50 + 30
        expect(notifier.state.currentPage, 1);
        expect(notifier.state.hasMore, false); // 30件なので次はない
      });
    });

    group('loadPhotosForDate', () {
      test('特定の日付の写真を読み込む', () async {
        // Arrange
        final targetDate = DateTime(2025, 7, 15);
        final photos = List.generate(20, (index) => MockAssetEntity());

        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(photos));

        for (var i = 0; i < photos.length; i++) {
          final date = targetDate.add(Duration(hours: i));
          when(() => photos[i].createDateTime).thenReturn(date);
        }

        // Act
        await notifier.loadPhotosForDate(targetDate);

        // Assert
        expect(notifier.state.photos.length, 20);
        expect(notifier.state.selectedDate, targetDate);
        expect(notifier.state.hasMore, false); // 特定日付なのでページネーション不要
      });
    });

    group('状態管理', () {
      test('カレンダー表示を切り替える', () {
        // Arrange
        expect(notifier.state.isCalendarView, false);

        // Act
        notifier.toggleCalendarView();

        // Assert
        expect(notifier.state.isCalendarView, true);

        // Act again
        notifier.toggleCalendarView();

        // Assert
        expect(notifier.state.isCalendarView, false);
      });

      test('写真の選択状態を管理する', () {
        // Arrange
        const photoId1 = 'photo1';
        const photoId2 = 'photo2';

        // Act & Assert
        expect(notifier.selectedPhotoIds.contains(photoId1), false);

        notifier.togglePhotoSelection(photoId1);
        expect(notifier.selectedPhotoIds.contains(photoId1), true);

        notifier.togglePhotoSelection(photoId2);
        expect(notifier.selectedPhotoIds.length, 2);

        notifier.togglePhotoSelection(photoId1);
        expect(notifier.selectedPhotoIds.contains(photoId1), false);
        expect(notifier.selectedPhotoIds.length, 1);

        notifier.clearSelection();
        expect(notifier.selectedPhotoIds, isEmpty);
      });

      test('使用済み写真IDを管理する', () {
        // Arrange
        final usedIds = {'used1', 'used2', 'used3'};

        // Act
        notifier.setUsedPhotoIds(usedIds);

        // Assert
        expect(notifier.isPhotoUsed('used1'), true);
        expect(notifier.isPhotoUsed('used2'), true);
        expect(notifier.isPhotoUsed('used3'), true);
        expect(notifier.isPhotoUsed('notused'), false);
      });

      test('エラーをクリアする', () async {
        // Arrange - エラー状態を作成
        final plan = BasicPlan();
        when(
          () => mockAccessControlService.getAccessibleDateForPlan(plan),
        ).thenReturn(DateTime.now().subtract(const Duration(days: 1)));
        when(
          () => mockPhotoService.getPhotosEfficient(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenThrow(Exception('エラー'));

        await notifier.loadInitialPhotos(plan);
        expect(notifier.state.errorMessage, isNotNull);

        // Act
        notifier.clearError();

        // Assert
        expect(notifier.state.errorMessage, isNull);
      });
    });
  });
}
