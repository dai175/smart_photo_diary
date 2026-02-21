import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_photo_diary/core/errors/app_exceptions.dart';
import 'package:smart_photo_diary/core/service_locator.dart';
import 'package:smart_photo_diary/services/ai/gemini_api_client.dart';
import 'package:smart_photo_diary/services/interfaces/logging_service_interface.dart';

import '../../../integration/mocks/mock_services.dart';

void main() {
  late MockILoggingService mockLogger;

  setUpAll(() {
    registerMockFallbacks();
    // sendTextRequest/sendVisionRequest/testApiKey が EnvironmentConfig.printDebugInfo() 経由で
    // dotenv.env にアクセスするため、テスト用に空のdotenvを初期化
    dotenv.loadFromString(envString: 'DUMMY_KEY=test');
  });

  setUp(() {
    serviceLocator.clear();
    mockLogger = TestServiceSetup.getLoggingService();
    serviceLocator.registerSingleton<ILoggingService>(mockLogger);
  });

  tearDown(() {
    serviceLocator.clear();
    TestServiceSetup.clearAllMocks();
  });

  String successResponseBody() {
    return '{"candidates":[{"content":{"parts":[{"text":"Hello!"}],'
        '"role":"model"},"finishReason":"STOP"}]}';
  }

  final testUrl = Uri.parse('https://example.com/api');
  const testHeaders = {'Content-Type': 'application/json'};
  const testBody = '{"test": true}';

  group('GeminiApiClient', () {
    group('postWithRetry', () {
      test('returns immediately on HTTP 200 without retry', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 200);
        expect(callCount, 1);
      });

      test('returns immediately on non-retryable HTTP error (400)', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('Bad Request', 400);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 400);
        expect(callCount, 1);
      });

      test('returns immediately on HTTP 401 without retry', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          return http.Response('Unauthorized', 401);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 401);
        expect(callCount, 1);
      });

      test('retries on HTTP 500 and succeeds on second attempt', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Internal Server Error', 500);
          }
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 200);
        expect(callCount, 2);
      });

      test('retries on HTTP 429 and succeeds on third attempt', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount <= 2) {
            return http.Response('Rate Limited', 429);
          }
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 200);
        expect(callCount, 3);
      });

      test(
        'retries on SocketException and succeeds on second attempt',
        () async {
          int callCount = 0;
          final mockClient = MockClient((request) async {
            callCount++;
            if (callCount == 1) {
              throw const SocketException('Connection refused');
            }
            return http.Response(successResponseBody(), 200);
          });

          final apiClient = GeminiApiClient(
            logger: mockLogger,
            httpClient: mockClient,
          );
          final response = await apiClient.postWithRetry(
            testUrl,
            headers: testHeaders,
            body: testBody,
            requestContext: 'test',
          );

          expect(response.statusCode, 200);
          expect(callCount, 2);
        },
      );

      test(
        'throws NetworkException after all retries exhausted on SocketException',
        () async {
          final mockClient = MockClient((request) async {
            throw const SocketException('Connection refused');
          });

          final apiClient = GeminiApiClient(
            logger: mockLogger,
            httpClient: mockClient,
          );

          expect(
            () => apiClient.postWithRetry(
              testUrl,
              headers: testHeaders,
              body: testBody,
              requestContext: 'test',
            ),
            throwsA(isA<NetworkException>()),
          );
        },
      );

      test(
        'throws NetworkException after all retries exhausted on HTTP 500',
        () async {
          final mockClient = MockClient((request) async {
            return http.Response('Server Error', 500);
          });

          final apiClient = GeminiApiClient(
            logger: mockLogger,
            httpClient: mockClient,
          );

          expect(
            () => apiClient.postWithRetry(
              testUrl,
              headers: testHeaders,
              body: testBody,
              requestContext: 'test',
            ),
            throwsA(isA<NetworkException>()),
          );
        },
      );

      test(
        'throws NetworkException after all retries exhausted on ClientException',
        () async {
          final mockClient = MockClient((request) async {
            throw http.ClientException('Connection reset');
          });

          final apiClient = GeminiApiClient(
            logger: mockLogger,
            httpClient: mockClient,
          );

          expect(
            () => apiClient.postWithRetry(
              testUrl,
              headers: testHeaders,
              body: testBody,
              requestContext: 'test',
            ),
            throwsA(isA<NetworkException>()),
          );
        },
      );

      test(
        'retries correct number of times (maxRetries + 1 total attempts)',
        () async {
          int callCount = 0;
          final mockClient = MockClient((request) async {
            callCount++;
            return http.Response('Server Error', 503);
          });

          final apiClient = GeminiApiClient(
            logger: mockLogger,
            httpClient: mockClient,
          );

          try {
            await apiClient.postWithRetry(
              testUrl,
              headers: testHeaders,
              body: testBody,
              requestContext: 'test',
            );
          } on NetworkException {
            // expected
          }

          // 初回 + maxRetries 回のリトライ = 4回
          expect(callCount, GeminiApiClient.maxRetries + 1);
        },
      );

      test('handles mixed errors across retries', () async {
        int callCount = 0;
        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            throw const SocketException('No route to host');
          }
          if (callCount == 2) {
            return http.Response('Bad Gateway', 502);
          }
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final response = await apiClient.postWithRetry(
          testUrl,
          headers: testHeaders,
          body: testBody,
          requestContext: 'test',
        );

        expect(response.statusCode, 200);
        expect(callCount, 3);
      });
    });

    group('isRetryableStatusCode', () {
      test('429 is retryable', () {
        expect(GeminiApiClient.isRetryableStatusCode(429), isTrue);
      });

      test('500, 502, 503, 504 are retryable', () {
        for (final code in [500, 502, 503, 504]) {
          expect(GeminiApiClient.isRetryableStatusCode(code), isTrue);
        }
      });

      test('599 is retryable', () {
        expect(GeminiApiClient.isRetryableStatusCode(599), isTrue);
      });

      test('200 is not retryable', () {
        expect(GeminiApiClient.isRetryableStatusCode(200), isFalse);
      });

      test('400, 401, 403, 404 are not retryable', () {
        for (final code in [400, 401, 403, 404]) {
          expect(GeminiApiClient.isRetryableStatusCode(code), isFalse);
        }
      });
    });

    group('Constructor', () {
      test('creates with default http.Client when none provided', () {
        final apiClient = GeminiApiClient(logger: mockLogger);
        expect(apiClient, isNotNull);
      });

      test('accepts custom http.Client for DI', () {
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });
        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        expect(apiClient, isNotNull);
      });
    });

    group('extractTextFromResponse', () {
      late GeminiApiClient apiClient;

      setUp(() {
        apiClient = GeminiApiClient(logger: mockLogger);
      });

      test('extracts text from standard response format', () {
        final data = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Generated diary content'},
                ],
                'role': 'model',
              },
              'finishReason': 'STOP',
            },
          ],
        };

        expect(
          apiClient.extractTextFromResponse(data),
          'Generated diary content',
        );
      });

      test('extracts text from alternative content.text format', () {
        final data = {
          'candidates': [
            {
              'content': {'text': 'Alt format content'},
              'finishReason': 'STOP',
            },
          ],
        };

        expect(apiClient.extractTextFromResponse(data), 'Alt format content');
      });

      test('extracts text from thinking process format', () {
        final data = {
          'candidates': [
            {'text': 'Thinking format content', 'finishReason': 'STOP'},
          ],
        };

        expect(
          apiClient.extractTextFromResponse(data),
          'Thinking format content',
        );
      });

      test('returns null for empty candidates', () {
        final data = {'candidates': []};
        expect(apiClient.extractTextFromResponse(data), isNull);
      });

      test('returns null for null candidates', () {
        final data = <String, dynamic>{};
        expect(apiClient.extractTextFromResponse(data), isNull);
      });

      test('returns null when text content is empty', () {
        final data = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': ''},
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        expect(apiClient.extractTextFromResponse(data), isNull);
      });

      test('trims whitespace from extracted text', () {
        final data = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': '  trimmed content  '},
                ],
                'role': 'model',
              },
              'finishReason': 'STOP',
            },
          ],
        };

        expect(apiClient.extractTextFromResponse(data), 'trimmed content');
      });
    });

    group('NetworkException', () {
      test('is a subtype of AppException', () {
        const exception = NetworkException('test error');
        expect(exception, isA<AppException>());
      });

      test('preserves original error', () {
        const original = SocketException('Connection refused');
        const exception = NetworkException(
          'Network failed',
          originalError: original,
        );
        expect(exception.originalError, original);
        expect(exception.message, 'Network failed');
      });

      test('includes details when provided', () {
        const exception = NetworkException(
          'Timeout',
          details: 'After 3 retries',
        );
        expect(exception.details, 'After 3 retries');
      });
    });

    group('Constants', () {
      test('maxRetries is 3', () {
        expect(GeminiApiClient.maxRetries, 3);
      });

      test('baseDelay is 1 second', () {
        expect(GeminiApiClient.baseDelay, const Duration(seconds: 1));
      });

      test('requestTimeout is 60 seconds', () {
        expect(GeminiApiClient.requestTimeout, const Duration(seconds: 60));
      });
    });

    group('sendTextRequest', () {
      test('APIキー未設定 → Failure(AiProcessingException)', () async {
        // テスト環境ではEnvironmentConfig未初期化のためhasValidApiKeyがfalse
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final result = await apiClient.sendTextRequest(prompt: 'Test prompt');

        // APIキー未設定のためFailureを返す
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiProcessingException>());
      });

      test('Failure時にエラーログが出力される', () async {
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        await apiClient.sendTextRequest(prompt: 'Test prompt');

        verify(
          () => mockLogger.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('sendVisionRequest', () {
      test('APIキー未設定 → Failure(AiProcessingException)', () async {
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final result = await apiClient.sendVisionRequest(
          prompt: 'Describe this image',
          imageData: imageData,
        );

        expect(result.isFailure, isTrue);
        expect(result.error, isA<AiProcessingException>());
      });

      test('Failure時にエラーログが出力される', () async {
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final imageData = Uint8List.fromList([1, 2, 3]);
        await apiClient.sendVisionRequest(prompt: 'Test', imageData: imageData);

        verify(
          () => mockLogger.error(
            any(),
            context: any(named: 'context'),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });
    });

    group('testApiKey', () {
      test('APIキー未設定 → false', () async {
        final mockClient = MockClient((request) async {
          return http.Response(successResponseBody(), 200);
        });

        final apiClient = GeminiApiClient(
          logger: mockLogger,
          httpClient: mockClient,
        );
        final result = await apiClient.testApiKey();

        // EnvironmentConfig未初期化のためhasValidApiKeyがfalseでfalseを返す
        expect(result, isFalse);
      });
    });
  });
}
