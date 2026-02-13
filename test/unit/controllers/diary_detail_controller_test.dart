import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/controllers/diary_detail_controller.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/interfaces/diary_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';

class MockDiaryService extends Mock implements IDiaryService {}

class MockPhotoService extends Mock implements IPhotoService {}

class MockLoggingService extends Mock implements ILoggingService {}

class MockAssetEntity extends Mock implements AssetEntity {}

DiaryEntry _createEntry({
  String id = 'test-id',
  String title = 'Test Title',
  String content = 'Test Content',
}) {
  final d = DateTime(2025, 1, 15);
  return DiaryEntry(
    id: id,
    date: d,
    title: title,
    content: content,
    photoIds: const [],
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  late MockDiaryService mockDiaryService;
  late MockPhotoService mockPhotoService;
  late MockLoggingService mockLoggingService;

  setUpAll(() {
    registerFallbackValue(_createEntry());
  });

  setUp(() {
    ServiceLocator().clear();
    mockDiaryService = MockDiaryService();
    mockPhotoService = MockPhotoService();
    mockLoggingService = MockLoggingService();
    ServiceLocator().registerSingleton<IDiaryService>(mockDiaryService);
    ServiceLocator().registerSingleton<IPhotoService>(mockPhotoService);
    ServiceLocator().registerSingleton<ILoggingService>(mockLoggingService);

    // Default: getAssetsByIds returns empty list
    when(
      () => mockPhotoService.getAssetsByIds(any()),
    ).thenAnswer((_) async => const Success<List<AssetEntity>>([]));
  });

  tearDown(() {
    ServiceLocator().clear();
  });

  group('DiaryDetailController', () {
    group('初期状態', () {
      test('初期状態は正しくセットされている', () {
        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        expect(controller.diaryEntry, isNull);
        expect(controller.photoAssets, isEmpty);
        expect(controller.isEditing, isFalse);
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isFalse);
        expect(controller.errorType, isNull);
        expect(controller.rawErrorDetail, isEmpty);
      });
    });

    group('loadDiaryEntry', () {
      test('エントリーが正常にロードされる', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        expect(controller.diaryEntry, equals(entry));
        expect(controller.isLoading, isFalse);
        expect(controller.hasError, isFalse);
      });

      test('エントリーが null の場合 notFound エラーになる', () async {
        when(
          () => mockDiaryService.getDiaryEntry('nonexistent'),
        ).thenAnswer((_) async => const Success(null));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('nonexistent');

        expect(controller.diaryEntry, isNull);
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryDetailErrorType.notFound);
        expect(controller.isLoading, isFalse);
      });

      test('サービスエラー時は loadFailed エラーになる', () async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => const Failure(DatabaseException('DB error')));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryDetailErrorType.loadFailed);
        expect(controller.rawErrorDetail, contains('DB error'));
        expect(controller.isLoading, isFalse);
      });

      test('ロード中は isLoading が true になる', () async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(_createEntry()));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        bool wasLoadingTrue = false;
        controller.addListener(() {
          if (controller.isLoading) {
            wasLoadingTrue = true;
          }
        });

        await controller.loadDiaryEntry('test-id');
        expect(wasLoadingTrue, isTrue);
      });

      test('写真アセットが正常にロードされる', () async {
        final asset1 = MockAssetEntity();
        final asset2 = MockAssetEntity();
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(
          () => mockPhotoService.getAssetsByIds(any()),
        ).thenAnswer((_) async => Success([asset1, asset2]));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        expect(controller.photoAssets, hasLength(2));
        expect(controller.photoAssets, contains(asset1));
        expect(controller.photoAssets, contains(asset2));
      });

      test('写真アセット取得失敗時は空リストとなりwarningがログに記録される', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(() => mockPhotoService.getAssetsByIds(any())).thenAnswer(
          (_) async => const Failure<List<AssetEntity>>(
            PhotoAccessException('Photo load failed'),
          ),
        );

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        expect(controller.diaryEntry, equals(entry));
        expect(controller.photoAssets, isEmpty);
        expect(controller.hasError, isFalse);
        verify(
          () => mockLoggingService.warning(
            any(that: contains('Failed to load photo assets')),
            context: 'DiaryDetailController.loadDiaryEntry',
            data: any(named: 'data'),
          ),
        ).called(1);
      });

      test('notifyListeners が呼ばれる', () async {
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(_createEntry()));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        await controller.loadDiaryEntry('test-id');
        expect(notifyCount, greaterThan(0));
      });
    });

    group('updateDiary', () {
      test('更新成功時は true を返し isEditing が false になる', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(
          () => mockDiaryService.updateDiaryEntry(any()),
        ).thenAnswer((_) async => const Success(null));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');
        controller.startEditing();
        expect(controller.isEditing, isTrue);

        final result = await controller.updateDiary(
          'test-id',
          title: 'New Title',
          content: 'New Content',
        );

        expect(result, isTrue);
        expect(controller.isEditing, isFalse);
      });

      test('更新失敗時は false を返し updateFailed エラーになる', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(() => mockDiaryService.updateDiaryEntry(any())).thenAnswer(
          (_) async => const Failure(DatabaseException('Update failed')),
        );

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        final result = await controller.updateDiary(
          'test-id',
          title: 'New Title',
          content: 'New Content',
        );

        expect(result, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryDetailErrorType.updateFailed);
      });

      test('diaryEntry が null の場合は false を返す', () async {
        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        final result = await controller.updateDiary(
          'test-id',
          title: 'T',
          content: 'C',
        );

        expect(result, isFalse);
      });
    });

    group('deleteDiary', () {
      test('削除成功時は true を返す', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(
          () => mockDiaryService.deleteDiaryEntry('test-id'),
        ).thenAnswer((_) async => const Success(null));

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        final result = await controller.deleteDiary('test-id');

        expect(result, isTrue);
        expect(controller.isLoading, isFalse);
      });

      test('削除失敗時は false を返し deleteFailed エラーになる', () async {
        final entry = _createEntry();
        when(
          () => mockDiaryService.getDiaryEntry('test-id'),
        ).thenAnswer((_) async => Success(entry));
        when(() => mockDiaryService.deleteDiaryEntry('test-id')).thenAnswer(
          (_) async => const Failure(DatabaseException('Delete failed')),
        );

        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        await controller.loadDiaryEntry('test-id');

        final result = await controller.deleteDiary('test-id');

        expect(result, isFalse);
        expect(controller.hasError, isTrue);
        expect(controller.errorType, DiaryDetailErrorType.deleteFailed);
      });
    });

    group('editing', () {
      test('startEditing で isEditing が true になる', () {
        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.startEditing();
        expect(controller.isEditing, isTrue);
        expect(notifyCount, 1);
      });

      test('cancelEditing で isEditing が false になる', () {
        final controller = DiaryDetailController();
        addTearDown(controller.dispose);

        controller.startEditing();

        int notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.cancelEditing();
        expect(controller.isEditing, isFalse);
        expect(notifyCount, 1);
      });
    });
  });
}
