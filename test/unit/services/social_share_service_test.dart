import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/interfaces/social_share_service_interface.dart';
import 'package:smart_photo_diary/services/social_share_service.dart';
import 'package:smart_photo_diary/services/diary_image_generator.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/photo_service_interface.dart';

class MockSocialShareService extends Mock implements ISocialShareService {}

class MockLoggingService extends Mock implements ILoggingService {}

class MockPhotoService extends Mock implements IPhotoService {}

void main() {
  late ISocialShareService shareService;
  late DiaryEntry diary;

  setUpAll(() {
    registerFallbackValue(ShareFormat.square);

    // DiaryEntryのfallback値を登録
    final now = DateTime.now();
    final fallbackDiary = DiaryEntry(
      id: 'fallback-id',
      date: now,
      title: 'Fallback Title',
      content: 'Fallback Content',
      photoIds: const [],
      createdAt: now,
      updatedAt: now,
    );
    registerFallbackValue(fallbackDiary);
  });

  setUp(() {
    shareService = MockSocialShareService();
    final now = DateTime.now();
    diary = DiaryEntry(
      id: 'test-id',
      date: now,
      title: 'テストタイトル',
      content: 'これはテスト用の日記本文です。全文が入ることを確認します。',
      photoIds: const [],
      createdAt: now,
      updatedAt: now,
    );
  });

  group('ISocialShareService Result<T> contract', () {
    test('generateShareImage returns Success with File on success', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/share.png')
        ..writeAsBytesSync([1, 2, 3]);

      when(
        () => shareService.generateShareImage(
          diary: any(named: 'diary'),
          format: any(named: 'format'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer((_) async => Success<File>(tempFile));

      final result = await shareService.generateShareImage(
        diary: diary,
        format: ShareFormat.square,
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, isA<File>());
      expect(result.value.existsSync(), isTrue);
    });

    test('generateShareImage returns Failure on error', () async {
      when(
        () => shareService.generateShareImage(
          diary: any(named: 'diary'),
          format: any(named: 'format'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => const Failure<File>(SocialShareException('生成に失敗しました')),
      );

      final result = await shareService.generateShareImage(
        diary: diary,
        format: ShareFormat.portrait,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<SocialShareException>());
      expect(result.error.message, contains('失敗'));
    });

    test('shareToSocialMedia returns Success<void> on success', () async {
      when(
        () => shareService.shareToSocialMedia(
          diary: any(named: 'diary'),
          format: any(named: 'format'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer((_) async => const Success<void>(null));

      final result = await shareService.shareToSocialMedia(
        diary: diary,
        format: ShareFormat.portrait,
      );

      expect(result.isSuccess, isTrue);
    });

    test('shareToSocialMedia returns Failure<void> on error', () async {
      when(
        () => shareService.shareToSocialMedia(
          diary: any(named: 'diary'),
          format: any(named: 'format'),
          photos: any(named: 'photos'),
        ),
      ).thenAnswer(
        (_) async => const Failure<void>(SocialShareException('共有に失敗しました')),
      );

      final result = await shareService.shareToSocialMedia(
        diary: diary,
        format: ShareFormat.square,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<SocialShareException>());
    });
  });

  group('SocialShareService Implementation Tests', () {
    late SocialShareService actualService;
    late MockLoggingService mockLoggingService;

    setUp(() {
      // ServiceLocatorをテスト用にセットアップ
      final testServiceLocator = ServiceLocator();

      mockLoggingService = MockLoggingService();

      // LoggingServiceを登録
      testServiceLocator.registerSingleton<ILoggingService>(mockLoggingService);

      // PhotoServiceのモックを作成
      final mockPhotoService = MockPhotoService();

      // DiaryImageGeneratorのモックを作成
      final mockImageGenerator = DiaryImageGenerator(
        logger: mockLoggingService,
      );

      // SocialShareServiceのインスタンスを作成
      actualService = SocialShareService(
        logger: mockLoggingService,
        imageGenerator: mockImageGenerator,
        photoService: mockPhotoService,
      );

      // モックの設定
      when(
        () => mockLoggingService.info(
          any(),
          context: any(named: 'context'),
          data: any(named: 'data'),
        ),
      ).thenReturn(null);

      when(
        () => mockLoggingService.error(
          any(),
          context: any(named: 'context'),
          error: any(named: 'error'),
        ),
      ).thenReturn(null);
    });

    tearDown(() {
      ServiceLocator().clear();
    });

    test('constructor returns new instance', () {
      final imageGen = DiaryImageGenerator(logger: mockLoggingService);
      final photoSvc = MockPhotoService();
      final instance1 = SocialShareService(
        logger: mockLoggingService,
        imageGenerator: imageGen,
        photoService: photoSvc,
      );
      final instance2 = SocialShareService(
        logger: mockLoggingService,
        imageGenerator: imageGen,
        photoService: photoSvc,
      );

      expect(instance1, isA<SocialShareService>());
      expect(instance2, isA<SocialShareService>());
      expect(instance1, isNot(same(instance2)));
    });

    test('getSupportedFormats returns all ShareFormat values', () {
      final formats = actualService.getSupportedFormats();

      expect(formats, equals(ShareFormat.values));
      expect(formats.length, equals(3));
      expect(formats, contains(ShareFormat.portrait));
      expect(formats, contains(ShareFormat.portraitHD));
      expect(formats, contains(ShareFormat.square));
    });

    test('isFormatSupported returns true for all ShareFormat values', () {
      for (final format in ShareFormat.values) {
        expect(actualService.isFormatSupported(format), isTrue);
      }
    });

    test('getRecommendedFormat returns HD version when useHD is true', () {
      final recommended = actualService.getRecommendedFormat(
        ShareFormat.portrait,
        useHD: true,
      );

      expect(recommended, equals(ShareFormat.portraitHD));
    });

    test('getRecommendedFormat returns base format when useHD is false', () {
      final recommended = actualService.getRecommendedFormat(
        ShareFormat.portrait,
        useHD: false,
      );

      expect(recommended, equals(ShareFormat.portrait));
    });

    test(
      'getRecommendedFormat returns same format for non-portrait formats',
      () {
        final recommended = actualService.getRecommendedFormat(
          ShareFormat.square,
          useHD: true,
        );

        expect(recommended, equals(ShareFormat.square));
      },
    );
  });

  group('ShareFormat Tests', () {
    test('portrait format has correct properties', () {
      const format = ShareFormat.portrait;

      expect(format.aspectRatio, equals(0.5625));
      expect(format.width, equals(1080));
      expect(format.height, equals(1920));
      expect(format.name, equals('portrait'));
      expect(format.scale, equals(2.0));
      expect(format.isPortrait, isTrue);
      expect(format.isSquare, isFalse);
      expect(format.isHD, isFalse);
    });

    test('portraitHD format has correct properties', () {
      const format = ShareFormat.portraitHD;

      expect(format.aspectRatio, equals(0.5625));
      expect(format.width, equals(1350));
      expect(format.height, equals(2400));
      expect(format.name, equals('portraitHD'));
      expect(format.scale, equals(2.5));
      expect(format.isPortrait, isTrue);
      expect(format.isSquare, isFalse);
      expect(format.isHD, isTrue);
    });

    test('square format has correct properties', () {
      const format = ShareFormat.square;

      expect(format.aspectRatio, equals(1.0));
      expect(format.width, equals(1080));
      expect(format.height, equals(1080));
      expect(format.name, equals('square'));
      expect(format.scale, equals(2.0));
      expect(format.isPortrait, isFalse);
      expect(format.isSquare, isTrue);
      expect(format.isHD, isFalse);
    });

    test('scaledWidth and scaledHeight return correct values', () {
      const format = ShareFormat.portrait;

      expect(format.scaledWidth, equals(2160));
      expect(format.scaledHeight, equals(3840));
    });
  });

  group('SocialShareException Tests', () {
    test('SocialShareException has correct userMessage', () {
      const exception = SocialShareException('テストエラー');

      expect(exception.message, equals('テストエラー'));
      expect(exception.userMessage, equals('Social sharing error: テストエラー'));
    });

    test('SocialShareException preserves details and originalError', () {
      final originalError = Exception('元のエラー');
      final exception = SocialShareException(
        'テストエラー',
        details: 'エラー詳細',
        originalError: originalError,
      );

      expect(exception.message, equals('テストエラー'));
      expect(exception.details, equals('エラー詳細'));
      expect(exception.originalError, equals(originalError));
    });
  });
}
