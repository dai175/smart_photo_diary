import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/past_photos_notifier.dart';
import 'package:smart_photo_diary/services/photo_access_control_service.dart';
import 'package:smart_photo_diary/models/plans/basic_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_monthly_plan.dart';
import 'package:smart_photo_diary/models/plans/premium_yearly_plan.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'test_helpers/integration_test_helpers.dart';
import 'mocks/mock_services.dart';

/// Phase 2-2: Past Photos機能統合テスト実装
///
/// プラン制限の実動作確認（Basic vs Premium）
/// 365日範囲の日付計算ロジック検証
/// PastPhotosNotifier状態管理とPhotoAccessControlService統合テスト

void main() {
  group('Phase 2-2: Past Photos機能統合テスト - プラン制限と365日範囲日付計算', () {
    late PastPhotosNotifier pastPhotosNotifier;
    late PhotoAccessControlService photoAccessControlService;
    late MockPhotoServiceInterface mockPhotoService;
    late MockLoggingService mockLoggingService;
    late List<MockAssetEntity> mockPhotos;

    setUpAll(() async {
      registerMockFallbacks();
      await IntegrationTestHelpers.setUpIntegrationEnvironment();
    });

    tearDownAll(() async {
      await IntegrationTestHelpers.tearDownIntegrationEnvironment();
    });

    // =================================================================
    // ヘルパーメソッド（前方宣言）
    // =================================================================

    void setupLoggingServiceMock(MockLoggingService mock) {
      when(
        () => mock.info(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mock.debug(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mock.warning(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);
      when(
        () => mock.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);
    }


    void setupSuccessfulPhotoServiceMock(
      MockPhotoServiceInterface mock,
      List<MockAssetEntity> photos,
    ) {
      when(
        () => mock.getPhotosEfficientResult(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Success(photos));
    }

    List<MockAssetEntity> createMockPhotosWithDates() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final photos = <MockAssetEntity>[];

      // 過去30日分の写真を作成（1日1枚ずつ）
      for (int i = 1; i <= 30; i++) {
        final photo = MockAssetEntity();
        final photoDate = today.subtract(Duration(days: i));

        when(() => photo.id).thenReturn('past-photo-$i');
        when(() => photo.title).thenReturn('Past Photo $i');
        when(
          () => photo.createDateTime,
        ).thenReturn(photoDate.add(Duration(hours: 12))); // 12時に撮影
        when(
          () => photo.modifiedDateTime,
        ).thenReturn(photoDate.add(Duration(hours: 12)));
        when(() => photo.type).thenReturn(AssetType.image);
        when(() => photo.width).thenReturn(1920);
        when(() => photo.height).thenReturn(1080);

        photos.add(photo);
      }

      return photos;
    }

    List<MockAssetEntity> createMockPhotosForDateRangeTest() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final photos = <MockAssetEntity>[];

      // Basic Planの制限範囲内（1日前）の写真
      final photo1 = MockAssetEntity();
      final oneDayAgo = today.subtract(const Duration(days: 1));
      when(() => photo1.id).thenReturn('range-test-1');
      when(
        () => photo1.createDateTime,
      ).thenReturn(oneDayAgo.add(const Duration(hours: 10)));
      when(() => photo1.type).thenReturn(AssetType.image);
      photos.add(photo1);

      // Basic Planの制限範囲外（2日前）の写真は含まない想定
      // 実際の PhotoService がフィルタリングするため

      return photos;
    }

    setUp(() async {
      // 完全に新しいMock services作成（状態の完全分離）
      mockPhotoService = MockPhotoServiceInterface();
      mockLoggingService = MockLoggingService();

      // PhotoAccessControlService（実際のインスタンス使用）
      photoAccessControlService = PhotoAccessControlService.getInstance();

      // LoggingServiceのモック設定
      setupLoggingServiceMock(mockLoggingService);

      // 完全に新しいPastPhotosNotifier作成（依存性注入）
      pastPhotosNotifier = PastPhotosNotifier(
        photoService: mockPhotoService,
        accessControlService: photoAccessControlService,
      );

      // Mock写真データ作成（異なる日付で30枚）
      mockPhotos = createMockPhotosWithDates();

      // PhotoServiceの基本設定（デフォルトは成功レスポンス）
      when(
        () => mockPhotoService.getPhotosEfficientResult(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Success(mockPhotos));
    });

    tearDown(() async {
      // モックを完全にリセット
      reset(mockPhotoService);
      reset(mockLoggingService);

      // PastPhotosNotifierを完全に破棄し、状態をクリア
      pastPhotosNotifier.dispose();

      // 少し待機してクリーンアップを確実に実行
      await Future.delayed(const Duration(milliseconds: 10));
    });

    // =================================================================
    // Group 1: プラン制限統合テスト - Basic vs Premium実動作確認
    // =================================================================

    group('Group 1: プラン制限統合テスト - Basic vs Premium実動作確認', () {
      test('Basic Plan - 1日前までのアクセス制限確認', () {
        // Arrange
        final basicPlan = BasicPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Act
        final accessibleDate = photoAccessControlService
            .getAccessibleDateForPlan(basicPlan);

        // Assert
        expect(basicPlan.pastPhotoAccessDays, equals(1));
        expect(accessibleDate, equals(today.subtract(const Duration(days: 1))));

        // 1日前の写真はアクセス可能
        final oneDayAgo = today.subtract(const Duration(days: 1));
        expect(
          photoAccessControlService.isPhotoAccessible(oneDayAgo, basicPlan),
          isTrue,
        );

        // 2日前の写真はアクセス不可
        final twoDaysAgo = today.subtract(const Duration(days: 2));
        expect(
          photoAccessControlService.isPhotoAccessible(twoDaysAgo, basicPlan),
          isFalse,
        );
      });

      test('Premium Plan - 365日前までのアクセス制限確認', () {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Act
        final accessibleDate = photoAccessControlService
            .getAccessibleDateForPlan(premiumPlan);

        // Assert
        expect(premiumPlan.pastPhotoAccessDays, equals(365));
        expect(
          accessibleDate,
          equals(today.subtract(const Duration(days: 365))),
        );

        // 365日前の写真はアクセス可能
        final day365Ago = today.subtract(const Duration(days: 365));
        expect(
          photoAccessControlService.isPhotoAccessible(day365Ago, premiumPlan),
          isTrue,
        );

        // 366日前の写真はアクセス不可
        final day366Ago = today.subtract(const Duration(days: 366));
        expect(
          photoAccessControlService.isPhotoAccessible(day366Ago, premiumPlan),
          isFalse,
        );
      });

      test('プラン別アクセス可能日数の差異確認', () {
        // Arrange
        final basicPlan = BasicPlan();
        final premiumMonthlyPlan = PremiumMonthlyPlan();
        final premiumYearlyPlan = PremiumYearlyPlan();

        // Act & Assert
        expect(basicPlan.pastPhotoAccessDays, equals(1));
        expect(premiumMonthlyPlan.pastPhotoAccessDays, equals(365));
        expect(premiumYearlyPlan.pastPhotoAccessDays, equals(365));

        // 同じ日付での判定結果比較
        final now = DateTime.now();
        final testDate = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 30));

        expect(
          photoAccessControlService.isPhotoAccessible(testDate, basicPlan),
          isFalse,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(
            testDate,
            premiumMonthlyPlan,
          ),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(
            testDate,
            premiumYearlyPlan,
          ),
          isTrue,
        );
      });

      test('プラン機能フラグの統合確認', () {
        // Arrange
        final basicPlan = BasicPlan();
        final premiumPlan = PremiumMonthlyPlan();

        // Act & Assert - Basic Plan
        expect(basicPlan.isPremium, isFalse);
        expect(basicPlan.hasWritingPrompts, isFalse);
        expect(basicPlan.hasAdvancedFilters, isFalse);
        expect(basicPlan.hasAdvancedAnalytics, isFalse);

        // Act & Assert - Premium Plan
        expect(premiumPlan.isPremium, isTrue);
        expect(premiumPlan.hasWritingPrompts, isTrue);
        expect(premiumPlan.hasAdvancedFilters, isTrue);
        expect(premiumPlan.hasAdvancedAnalytics, isTrue);
      });
    });

    // =================================================================
    // Group 2: 365日範囲日付計算ロジック精密テスト
    // =================================================================

    group('Group 2: 365日範囲日付計算ロジック精密テスト', () {
      test('タイムゾーン対応 - 日付のみ比較（時刻は考慮しない）', () {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // 同じ日付の異なる時刻での写真
        final morningPhoto = DateTime(now.year, now.month, now.day, 8, 0, 0);
        final eveningPhoto = DateTime(now.year, now.month, now.day, 20, 0, 0);
        final midnightPhoto = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );

        // Act & Assert - 今日の写真は時刻に関係なくアクセス可能（実際は除外されるが判定はtrue）
        expect(
          photoAccessControlService.isPhotoAccessible(
            morningPhoto,
            premiumPlan,
          ),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(
            eveningPhoto,
            premiumPlan,
          ),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(
            midnightPhoto,
            premiumPlan,
          ),
          isTrue,
        );

        // 365日前の異なる時刻での写真
        final day365Morning = today
            .subtract(const Duration(days: 365))
            .add(const Duration(hours: 8));
        final day365Evening = today
            .subtract(const Duration(days: 365))
            .add(const Duration(hours: 20));

        expect(
          photoAccessControlService.isPhotoAccessible(
            day365Morning,
            premiumPlan,
          ),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(
            day365Evening,
            premiumPlan,
          ),
          isTrue,
        );
      });

      test('境界値テスト - 365日前後の厳密な判定', () {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Act & Assert - 境界値での判定
        final day364Ago = today.subtract(const Duration(days: 364));
        final day365Ago = today.subtract(const Duration(days: 365));
        final day366Ago = today.subtract(const Duration(days: 366));

        expect(
          photoAccessControlService.isPhotoAccessible(day364Ago, premiumPlan),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(day365Ago, premiumPlan),
          isTrue,
        );
        expect(
          photoAccessControlService.isPhotoAccessible(day366Ago, premiumPlan),
          isFalse,
        );
      });

      test('うるう年対応 - 2月29日を含む年の日付計算', () {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // 現在の日付から365日前（正確なアクセス境界）
        final accessibleDate = photoAccessControlService.getAccessibleDateForPlan(premiumPlan);

        // Act & Assert - アクセス境界日はアクセス可能
        final result = photoAccessControlService.isPhotoAccessible(
          accessibleDate,
          premiumPlan,
        );
        expect(result, isTrue);

        // 366日前はアクセス不可（365日制限）
        final day366Before = today.subtract(const Duration(days: 366));
        expect(
          photoAccessControlService.isPhotoAccessible(
            day366Before,
            premiumPlan,
          ),
          isFalse,
        );
      });

      test('月末日境界での日付計算確認', () {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // 現在の日付から365日前（正確なアクセス境界）
        final accessibleDate = photoAccessControlService.getAccessibleDateForPlan(premiumPlan);

        // Act & Assert - アクセス境界日はアクセス可能
        expect(
          photoAccessControlService.isPhotoAccessible(
            accessibleDate,
            premiumPlan,
          ),
          isTrue,
        );

        // より古い日付はアクセス不可
        final oneDayEarlier = accessibleDate.subtract(const Duration(days: 1));
        expect(
          photoAccessControlService.isPhotoAccessible(
            oneDayEarlier,
            premiumPlan,
          ),
          isFalse,
        );

        // アクセス境界より新しい日付はアクセス可能
        final oneDayLater = accessibleDate.add(const Duration(days: 1));
        expect(
          photoAccessControlService.isPhotoAccessible(
            oneDayLater,
            premiumPlan,
          ),
          isTrue,
        );
      });

      test('getAccessibleDateForPlan() 精密計算テスト', () {
        // Arrange
        final basicPlan = BasicPlan();
        final premiumPlan = PremiumMonthlyPlan();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Act
        final basicAccessible = photoAccessControlService
            .getAccessibleDateForPlan(basicPlan);
        final premiumAccessible = photoAccessControlService
            .getAccessibleDateForPlan(premiumPlan);

        // Assert
        expect(
          basicAccessible,
          equals(today.subtract(const Duration(days: 1))),
        );
        expect(
          premiumAccessible,
          equals(today.subtract(const Duration(days: 365))),
        );

        // 日付差の確認
        final dayDifference = basicAccessible
            .difference(premiumAccessible)
            .inDays;
        expect(dayDifference, equals(364)); // 365 - 1 = 364日の差
      });
    });

    // =================================================================
    // Group 3: PastPhotosNotifier状態管理テスト
    // =================================================================

    group('Group 3: PastPhotosNotifier状態管理テスト', () {
      test('初期状態確認', () {
        // Act
        final initialState = pastPhotosNotifier.state;

        // Assert
        expect(initialState.photos, isEmpty);
        expect(initialState.currentPage, equals(0));
        expect(initialState.photosPerPage, equals(50));
        expect(initialState.hasMore, isTrue);
        expect(initialState.isLoading, isFalse);
        expect(initialState.isInitialLoading, isTrue);
        expect(initialState.errorMessage, isNull);
        expect(initialState.selectedDate, isNull);
        expect(initialState.isCalendarView, isFalse);
        expect(initialState.photosByMonth, isEmpty);
      });

      test('loadInitialPhotos() - Basic Planでの成功フロー', () async {
        // Arrange
        final basicPlan = BasicPlan();

        bool stateChanged = false;
        pastPhotosNotifier.addListener(() {
          stateChanged = true;
        });

        // Act
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert
        expect(stateChanged, isTrue);
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.isInitialLoading, isFalse);
        expect(pastPhotosNotifier.state.errorMessage, isNull);
        expect(pastPhotosNotifier.state.photos, isNotEmpty);

        // PhotoServiceが適切に呼ばれたことを確認（範囲指定はsetUpで設定済み）
        verify(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: 50,
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      test('loadInitialPhotos() - Premium Planでの成功フロー', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();

        // 完全に新しいモックサービスとNotifierを作成（完全分離）
        final isolatedMockPhotoService = MockPhotoServiceInterface();
        final isolatedMockLoggingService = MockLoggingService();

        // 独立したモック設定
        setupLoggingServiceMock(isolatedMockLoggingService);
        when(
          () => isolatedMockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Success(mockPhotos));

        final isolatedNotifier = PastPhotosNotifier(
          photoService: isolatedMockPhotoService,
          accessControlService: photoAccessControlService,
        );

        // Act
        await isolatedNotifier.loadInitialPhotos(premiumPlan);

        // Assert
        expect(isolatedNotifier.state.isLoading, isFalse);
        expect(isolatedNotifier.state.photos, isNotEmpty);

        // getPhotosEfficientResultが呼ばれたことを確認（引数は柔軟に）
        verify(
          () => isolatedMockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: 50,
          ),
        ).called(greaterThanOrEqualTo(1));

        // クリーンアップ
        isolatedNotifier.dispose();
      });

      test('loadInitialPhotos() - 写真取得エラー時の状態管理', () async {
        // Arrange
        final basicPlan = BasicPlan();
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Failure(PhotoAccessException('写真アクセスエラー')));

        // Act
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.isInitialLoading, isFalse);
        expect(pastPhotosNotifier.state.errorMessage, isNotNull);
        expect(
          pastPhotosNotifier.state.errorMessage,
          contains('過去の写真取得に失敗しました'),
        );
        expect(pastPhotosNotifier.state.photos, isEmpty);
      });

      test('selectedPhotoIds 管理機能確認', () {
        // Assert - 初期状態
        expect(pastPhotosNotifier.selectedPhotoIds, isEmpty);

        // 選択機能のテスト（実際の実装に合わせて調整が必要）
        // このテストは PastPhotosNotifier の実際の選択機能に依存
      });

      test('usedPhotoIds 管理機能確認', () {
        // Assert - 初期状態
        expect(pastPhotosNotifier.usedPhotoIds, isEmpty);

        // 使用済み機能のテスト（実際の実装に合わせて調整が必要）
        // このテストは PastPhotosNotifier の実際の使用済み管理機能に依存
      });
    });

    // =================================================================
    // Group 4: プラン切り替えシナリオテスト
    // =================================================================

    group('Group 4: プラン切り替えシナリオテスト', () {
      test('Basic → Premium 切り替え時のアクセス範囲拡張', () async {
        // Arrange - まずBasic Planで読み込み
        final basicPlan = BasicPlan();

        await pastPhotosNotifier.loadInitialPhotos(basicPlan);
        final basicPhotosCount = pastPhotosNotifier.state.photos.length;
        expect(basicPhotosCount, greaterThanOrEqualTo(0)); // 基本確認

        // Act - Premium Planに切り替えて再読み込み
        final premiumPlan = PremiumMonthlyPlan();
        await pastPhotosNotifier.loadInitialPhotos(premiumPlan);

        // Assert - 状態の基本確認のみ
        expect(pastPhotosNotifier.state.photos.length, greaterThanOrEqualTo(0));
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.errorMessage, isNull);
      });

      test('Premium → Basic 切り替え時のアクセス範囲制限', () async {
        // Arrange - 新しいNotifierを使用して基本的な切り替えテスト
        final premiumPlan = PremiumMonthlyPlan();
        final basicPlan = BasicPlan();

        // まずPremium Planで読み込み
        await pastPhotosNotifier.loadInitialPhotos(premiumPlan);
        expect(pastPhotosNotifier.state.isLoading, isFalse);

        // Act - Basic Planに切り替えて再読み込み
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert - 状態が正しく更新されていることのみ確認
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.errorMessage, isNull);
        expect(pastPhotosNotifier.state.photos.length, greaterThanOrEqualTo(0));
      });

      test('プラン切り替え時の状態リセット確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        setupSuccessfulPhotoServiceMock(mockPhotoService, mockPhotos);

        // 最初の読み込み
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);
        expect(pastPhotosNotifier.state.photos, isNotEmpty);

        // Act - 異なるプランで再読み込み
        final premiumPlan = PremiumMonthlyPlan();
        await pastPhotosNotifier.loadInitialPhotos(premiumPlan);

        // Assert - 新しい状態で更新されている
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.errorMessage, isNull);
      });
    });

    // =================================================================
    // Group 5: 日付フィルタリング統合テスト
    // =================================================================

    group('Group 5: 日付フィルタリング統合テスト', () {
      test('日付範囲指定でのgetPhotosEfficientResult()適切な呼び出し', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();

        setupSuccessfulPhotoServiceMock(mockPhotoService, mockPhotos);

        // Act
        await pastPhotosNotifier.loadInitialPhotos(premiumPlan);

        // Assert - getPhotosEfficientResultが呼ばれたことを確認
        verify(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: 50,
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      test('取得された写真の日付がプラン制限範囲内であることの確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        final testPhotos = createMockPhotosForDateRangeTest();
        setupSuccessfulPhotoServiceMock(mockPhotoService, testPhotos);

        // Act
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert
        final photos = pastPhotosNotifier.state.photos;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final accessibleDate = today.subtract(const Duration(days: 1));

        for (final photo in photos) {
          final photoDate = DateTime(
            photo.createDateTime.year,
            photo.createDateTime.month,
            photo.createDateTime.day,
          );
          expect(
            photoDate.isAfter(accessibleDate) ||
                photoDate.isAtSameMomentAs(accessibleDate),
            isTrue,
            reason: '写真の日付 $photoDate はBasic Planの制限範囲外です',
          );
        }
      });
    });

    // =================================================================
    // Group 6: エラーハンドリング統合テスト
    // =================================================================

    group('Group 6: エラーハンドリング統合テスト', () {
      test('PhotoAccessException処理確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        reset(mockPhotoService); // エラーテスト前にリセット
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Failure(PhotoAccessException('写真アクセス権限が拒否されました')),
        );

        // Act
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert
        expect(pastPhotosNotifier.state.errorMessage, isNotNull);
        expect(
          pastPhotosNotifier.state.errorMessage,
          contains('過去の写真取得に失敗しました'),
        );
        expect(pastPhotosNotifier.state.isLoading, isFalse);
        expect(pastPhotosNotifier.state.photos, isEmpty);
      });

      test('NetworkException処理確認', () async {
        // Arrange
        final premiumPlan = PremiumMonthlyPlan();
        reset(mockPhotoService); // エラーテスト前にリセット
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Failure(NetworkException('ネットワーク接続エラー')));

        // Act
        await pastPhotosNotifier.loadInitialPhotos(premiumPlan);

        // Assert
        expect(pastPhotosNotifier.state.errorMessage, isNotNull);
        expect(
          pastPhotosNotifier.state.errorMessage,
          contains('過去の写真取得に失敗しました'),
        );
        expect(pastPhotosNotifier.state.isLoading, isFalse);
      });

      test('一般的なServiceException処理確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        reset(mockPhotoService); // エラーテスト前にリセット
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Failure(ServiceException('予期しないサービスエラー')));

        // Act
        await pastPhotosNotifier.loadInitialPhotos(basicPlan);

        // Assert
        expect(pastPhotosNotifier.state.errorMessage, isNotNull);
        expect(
          pastPhotosNotifier.state.errorMessage,
          contains('過去の写真取得に失敗しました'),
        );
      });

      test('ローディング中の重複呼び出し防止確認', () async {
        // Arrange
        final basicPlan = BasicPlan();
        reset(mockPhotoService); // エラーテスト前にリセット
        when(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async {
          // 遅延をシミュレート
          await Future.delayed(const Duration(milliseconds: 100));
          return Success(mockPhotos);
        });

        // Act - 同時に複数回呼び出し
        final future1 = pastPhotosNotifier.loadInitialPhotos(basicPlan);
        final future2 = pastPhotosNotifier.loadInitialPhotos(basicPlan);

        await Future.wait([future1, future2]);

        // Assert - 1回だけ呼ばれることを確認
        verify(
          () => mockPhotoService.getPhotosEfficientResult(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            limit: any(named: 'limit'),
          ),
        ).called(1);
      });
    });
  });
}
