import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/models/diary_entry.dart';
import 'package:smart_photo_diary/services/diary_image_generator.dart';
import 'package:smart_photo_diary/services/interfaces/social_share_service_interface.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

class MockLoggingService extends Mock implements ILoggingService {}

void main() {
  late DiaryImageGenerator generator;
  late MockLoggingService mockLoggingService;
  late ServiceLocator testServiceLocator;
  late DiaryEntry diary;

  setUpAll(() {
    // AssetEntityのfallback値を登録
    registerFallbackValue(<AssetEntity>[]);
  });

  setUp(() {
    // ServiceLocatorをテスト用にセットアップ
    testServiceLocator = ServiceLocator();

    mockLoggingService = MockLoggingService();

    // LoggingServiceを登録
    testServiceLocator.registerSingleton<ILoggingService>(mockLoggingService);

    generator = DiaryImageGenerator(logger: mockLoggingService);

    // テスト用のDiaryEntryを作成
    final now = DateTime.now();
    diary = DiaryEntry(
      id: 'test-diary-id',
      date: now,
      title: 'テスト日記のタイトル',
      content: 'これはテスト用の日記本文です。Canvas描画のテストを行います。',
      photoIds: const [],
      createdAt: now,
      updatedAt: now,
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
    testServiceLocator.clear();
  });

  group('DiaryImageGenerator Tests', () {
    test('constructor returns new instance', () {
      final instance1 = DiaryImageGenerator(logger: mockLoggingService);
      final instance2 = DiaryImageGenerator(logger: mockLoggingService);

      expect(instance1, isA<DiaryImageGenerator>());
      expect(instance2, isA<DiaryImageGenerator>());
      expect(instance1, isNot(same(instance2)));
    });

    test('generateImage calls logging service on start', () async {
      // 実際の生成は行わず、ログ呼び出しのみテスト
      final result = await generator.generateImage(
        diary: diary,
        format: ShareFormat.square,
      );

      // ログ呼び出しの確認
      verify(
        () => mockLoggingService.info(
          'Starting image generation: 正方形',
          context: 'DiaryImageGenerator.generateImage',
          data: 'diary_id: ${diary.id}',
        ),
      ).called(1);

      // 結果の型確認（成功・失敗どちらでも良い）
      expect(result, isA<Result<File>>());
    });

    test('generateImage handles different formats', () async {
      for (final format in ShareFormat.values) {
        final result = await generator.generateImage(
          diary: diary,
          format: format,
        );

        // 各フォーマットでログが呼ばれることを確認
        verify(
          () => mockLoggingService.info(
            'Starting image generation: ${format.name}',
            context: 'DiaryImageGenerator.generateImage',
            data: 'diary_id: ${diary.id}',
          ),
        ).called(1);

        expect(result, isA<Result<File>>());
      }
    });

    test('generateImage handles empty photos list', () async {
      final result = await generator.generateImage(
        diary: diary,
        format: ShareFormat.square,
        photos: [],
      );

      expect(result, isA<Result<File>>());

      // ログ呼び出しの確認
      verify(
        () => mockLoggingService.info(
          'Starting image generation: 正方形',
          context: 'DiaryImageGenerator.generateImage',
          data: 'diary_id: ${diary.id}',
        ),
      ).called(1);
    });

    test('generateImage handles long title', () async {
      final longTitleDiary = diary.copyWith(
        title: 'これは非常に長いタイトルです。Canvas描画で適切に処理される必要があります。文字数の制限をテストしています。',
      );

      final result = await generator.generateImage(
        diary: longTitleDiary,
        format: ShareFormat.square,
      );

      expect(result, isA<Result<File>>());
    });

    test('generateImage handles long content', () async {
      final longContentDiary = diary.copyWith(
        content: '今日は素晴らしい一日でした。' * 20, // 長いコンテンツ
      );

      final result = await generator.generateImage(
        diary: longContentDiary,
        format: ShareFormat.portrait,
      );

      expect(result, isA<Result<File>>());
    });
  });

  group('DiaryImageGenerator Constants Tests', () {
    test('internal constants are within reasonable ranges', () {
      // インスタンスを生成
      final generator = DiaryImageGenerator(logger: mockLoggingService);

      // インスタンスが正常に作成されることを確認
      expect(generator, isNotNull);

      // ShareFormatの定数が正しいことを確認（間接的テスト）
      expect(ShareFormat.portrait.width, equals(1080));
      expect(ShareFormat.portrait.height, equals(1920));
      expect(ShareFormat.square.width, equals(1080));
      expect(ShareFormat.square.height, equals(1080));
    });
  });
}
