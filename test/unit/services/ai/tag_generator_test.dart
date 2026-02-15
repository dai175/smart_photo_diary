import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/result/result.dart';
import 'package:smart_photo_diary/services/ai/gemini_api_client.dart';
import 'package:smart_photo_diary/services/ai/tag_generator.dart';

import '../../../../test/integration/mocks/mock_services.dart';

class MockGeminiApiClient extends Mock implements GeminiApiClient {}

void main() {
  late TagGenerator tagGenerator;
  late MockGeminiApiClient mockApiClient;
  late MockILoggingService mockLogger;

  setUpAll(() {
    registerMockFallbacks();
  });

  setUp(() {
    mockApiClient = MockGeminiApiClient();
    mockLogger = TestServiceSetup.getLoggingService();
    tagGenerator = TagGenerator(logger: mockLogger, apiClient: mockApiClient);
  });

  tearDown(() {
    TestServiceSetup.clearAllMocks();
  });

  group('generateTags - オフライン', () {
    test('isOnline=false → Success(オフラインタグ)', () async {
      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, isNotEmpty);
    });

    test('オフライン(ja) + 朝の時間帯 → "朝"タグが含まれる', () async {
      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.value, contains('朝'));
    });

    test('オフライン(en) + 朝の時間帯 → "Morning"タグが含まれる', () async {
      final result = await tagGenerator.generateTags(
        title: 'Test',
        content: 'Test content',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('en'),
      );

      expect(result.value, contains('Morning'));
    });

    test('オフライン(ja) + 食事キーワード → "食事"タグ追加', () async {
      final result = await tagGenerator.generateTags(
        title: '夕食の記録',
        content: '美味しい夕食を食べた',
        date: DateTime(2025, 3, 15, 19),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.value, contains('食事'));
    });

    test('オフライン(en) + 食事キーワード → "Meal"タグ追加', () async {
      final result = await tagGenerator.generateTags(
        title: 'Dinner record',
        content: 'Had a nice dinner',
        date: DateTime(2025, 3, 15, 19),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('en'),
      );

      expect(result.value, contains('Meal'));
    });

    test('オフライン + 外出キーワード → 外出タグ追加', () async {
      final result = await tagGenerator.generateTags(
        title: '散歩の記録',
        content: '公園を散歩した',
        date: DateTime(2025, 3, 15, 14),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.value, contains('外出'));
    });

    test('オフライン + 仕事キーワード → 仕事タグ追加', () async {
      final result = await tagGenerator.generateTags(
        title: '仕事の一日',
        content: '今日も仕事を頑張った',
        date: DateTime(2025, 3, 15, 10),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.value, contains('仕事'));
    });

    test('オフライン + キーワード不一致 → 基本タグのみ', () async {
      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      // 基本タグ（時間帯）のみ
      expect(result.value.length, 1);
      expect(result.value, contains('朝'));
    });

    test('オフライン + 複数カテゴリ一致 → 最大5個', () async {
      final result = await tagGenerator.generateTags(
        title: '食事と散歩と仕事と読書と運動と買い物',
        content: '朝食を食べて散歩して仕事して本を読んでスポーツして買い物した',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      expect(result.value.length, lessThanOrEqualTo(5));
    });
  });

  group('generateTags - オンライン', () {
    test('isOnline=true + API成功 → Success(AIタグ + 基本タグ)', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Tag1,Tag2,Tag3'},
              ],
            },
          },
        ],
      };
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          temperature: any(named: 'temperature'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(
        () => mockApiClient.extractTextFromResponse(any()),
      ).thenReturn('Tag1,Tag2,Tag3');

      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value, isNotEmpty);
    });

    test('isOnline=true + APIレスポンスのテキストが空 → Failure', () async {
      final mockResponse = {'candidates': []};
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          temperature: any(named: 'temperature'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(() => mockApiClient.extractTextFromResponse(any())).thenReturn(null);

      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });

    test('isOnline=true + API失敗 → Failure', () async {
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          temperature: any(named: 'temperature'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer(
        (_) async => const Failure(AiProcessingException('API error')),
      );

      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
    });

    test('例外発生 → Failure(AiProcessingException)', () async {
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          temperature: any(named: 'temperature'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isFailure, isTrue);
      expect(result.error, isA<AiProcessingException>());
    });

    test('タグが5個以内に制限される', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'A,B,C,D,E,F,G'},
              ],
            },
          },
        ],
      };
      when(
        () => mockApiClient.sendTextRequest(
          prompt: any(named: 'prompt'),
          temperature: any(named: 'temperature'),
          maxOutputTokens: any(named: 'maxOutputTokens'),
        ),
      ).thenAnswer((_) async => Success(mockResponse));

      when(
        () => mockApiClient.extractTextFromResponse(any()),
      ).thenReturn('A,B,C,D,E,F,G');

      final result = await tagGenerator.generateTags(
        title: 'テスト',
        content: 'テスト内容',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: true,
        locale: const Locale('ja'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.value.length, lessThanOrEqualTo(5));
    });
  });

  group('generateTags - 類似タグフィルタリング', () {
    test('オフライン + "朝食"キーワード → "食事"に統合', () async {
      final result = await tagGenerator.generateTags(
        title: '朝食の記録',
        content: '美味しい朝食',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('ja'),
      );

      // "朝食"は"食事"グループに統合される
      expect(result.value, contains('食事'));
      expect(result.value, isNot(contains('朝食')));
    });

    test('オフライン(en) + "Breakfast"キーワード → "Meal"に統合', () async {
      final result = await tagGenerator.generateTags(
        title: 'Breakfast record',
        content: 'Had a nice breakfast',
        date: DateTime(2025, 3, 15, 8),
        photoCount: 1,
        isOnline: false,
        locale: const Locale('en'),
      );

      expect(result.value, contains('Meal'));
    });
  });
}
