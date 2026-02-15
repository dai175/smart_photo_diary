import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/ai/diary_generator.dart';
import 'package:smart_photo_diary/services/ai/gemini_api_client.dart';

import '../../../../test/integration/mocks/mock_services.dart';

class MockGeminiApiClient extends Mock implements GeminiApiClient {}

void main() {
  late DiaryGenerator diaryGenerator;
  late MockGeminiApiClient mockApiClient;
  late MockILoggingService mockLogger;

  final testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
  final testDate = DateTime(2025, 3, 15, 10, 30);

  setUpAll(() async {
    await initializeDateFormatting('ja');
    await initializeDateFormatting('en');
    registerMockFallbacks();
  });

  setUp(() {
    mockApiClient = MockGeminiApiClient();
    mockLogger = TestServiceSetup.getLoggingService();
    diaryGenerator = DiaryGenerator(
      logger: mockLogger,
      apiClient: mockApiClient,
    );
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('generateFromImage', () {
    test('isOnline=false + ja → Failure(日本語オフラインメッセージ)', () async {
      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('オフライン'));
    });

    test('isOnline=false + en → Failure(英語オフラインメッセージ)', () async {
      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: false,
        locale: const Locale('en'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('offline'));
    });

    test('API成功 + 日本語フォーマット → Success(title, content)', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '【タイトル】\n春の訪れ\n\n【本文】\n暖かい日差しの中で過ごした一日。'},
              ],
            },
          },
        ],
      };

      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(
        () => mockApiClient.extractTextFromResponse(any()),
      ).thenReturn('【タイトル】\n春の訪れ\n\n【本文】\n暖かい日差しの中で過ごした一日。');

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value.title, '春の訪れ');
      expect(result.value.content, '暖かい日差しの中で過ごした一日。');
    });

    test('API成功 + 英語フォーマット → Success(title, content)', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text':
                      '[Title]\nA Warm Day\n\n[Body]\nSpent a lovely day in the sunshine.',
                },
              ],
            },
          },
        ],
      };

      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(() => mockApiClient.extractTextFromResponse(any())).thenReturn(
        '[Title]\nA Warm Day\n\n[Body]\nSpent a lovely day in the sunshine.',
      );

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('en'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value.title, 'A Warm Day');
      expect(result.value.content, 'Spent a lovely day in the sunshine.');
    });

    test('API成功 + extractTextがnull → Failure', () async {
      final mockResponse = {'candidates': []};

      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(() => mockApiClient.extractTextFromResponse(any())).thenReturn(null);

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });

    test('API失敗(Failure) → Failure伝播', () async {
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer(
        (_) async => const Failure(AiProcessingException('API error')),
      );

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });

    test('例外発生 → Failure(AiProcessingException)', () async {
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<AiProcessingException>());
    });
  });

  group('generateFromMultipleImages', () {
    test('空リスト → Failure("画像が提供されていません")', () async {
      final result = await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [],
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('画像が提供されていません'));
    });

    test('空リスト(en) → Failure("No images were provided")', () async {
      final result = await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [],
        isOnline: true,
        locale: const Locale('en'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error.toString(), contains('No images were provided'));
    });

    test('isOnline=false → Failure', () async {
      final result = await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [(imageData: testImageData, time: testDate)],
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });

    test('複数画像 + API成功 → Success(日記生成結果)', () async {
      // _analyzeImage用のモック（Vision API）
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => const Success({'type': 'vision'}));

      // _generateDiaryFromAnalyses用のモック（Text API）
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => const Success({'type': 'text'}));

      // extractTextFromResponse は呼ばれるたびに異なる値を返す
      var extractCallCount = 0;
      when(() => mockApiClient.extractTextFromResponse(any())).thenAnswer((_) {
        extractCallCount++;
        if (extractCallCount <= 2) {
          return 'Scene analysis $extractCallCount';
        }
        return '【タイトル】\n一日の思い出\n\n【本文】\n素晴らしい一日でした。';
      });

      final result = await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [
          (imageData: testImageData, time: DateTime(2025, 3, 15, 8)),
          (imageData: testImageData, time: DateTime(2025, 3, 15, 14)),
        ],
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value.title, '一日の思い出');
    });

    test('onProgressコールバックが正しく呼ばれる', () async {
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => const Success({'type': 'vision'}));

      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => const Success({'type': 'text'}));

      var extractCallCount = 0;
      when(() => mockApiClient.extractTextFromResponse(any())).thenAnswer((_) {
        extractCallCount++;
        if (extractCallCount <= 2) {
          return 'Analysis $extractCallCount';
        }
        return '【タイトル】\nタイトル\n\n【本文】\n本文';
      });

      final progressCalls = <(int, int)>[];

      await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [
          (imageData: testImageData, time: DateTime(2025, 3, 15, 8)),
          (imageData: testImageData, time: DateTime(2025, 3, 15, 14)),
        ],
        onProgress: (current, total) => progressCalls.add((current, total)),
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(progressCalls, [(1, 2), (2, 2)]);
    });

    test('例外発生 → Failure', () async {
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await diaryGenerator.generateFromMultipleImages(
        imagesWithTimes: [(imageData: testImageData, time: testDate)],
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });
  });

  group('_parseGeneratedDiary (generateFromImage経由で間接テスト)', () {
    void setupVisionMock(String responseText) {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': responseText},
              ],
            },
          },
        ],
      };
      when(
        () => mockApiClient.sendVisionRequest(
          prompt: any(named: 'prompt'),
          imageData: any(named: 'imageData'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));
      when(
        () => mockApiClient.extractTextFromResponse(any()),
      ).thenReturn(responseText);
    }

    test('【タイトル】/【本文】形式 → 正しく分割', () async {
      setupVisionMock('【タイトル】\n春の訪れ\n\n【本文】\n暖かい一日でした。');

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.value.title, '春の訪れ');
      expect(result.value.content, '暖かい一日でした。');
    });

    test('[Title]/[Body]形式 → 正しく分割', () async {
      setupVisionMock('[Title]\nSunny Day\n\n[Body]\nA beautiful sunny day.');

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('en'),
      );

      expect(result.value.title, 'Sunny Day');
      expect(result.value.content, 'A beautiful sunny day.');
    });

    test('形式不明 → 最初の行がタイトル、残りが本文', () async {
      setupVisionMock('First Line\nSecond Line\nThird Line');

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.value.title, 'First Line');
      expect(result.value.content, contains('Second Line'));
    });

    test('空レスポンス(1行のみ) → タイトルのみ、本文は全体テキスト', () async {
      setupVisionMock('Only one line here');

      final result = await diaryGenerator.generateFromImage(
        imageData: testImageData,
        date: testDate,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value.title, isNotEmpty);
    });
  });
}
