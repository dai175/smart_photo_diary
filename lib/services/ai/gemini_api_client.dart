import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/environment_config.dart';
import '../../constants/ai_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../interfaces/logging_service_interface.dart';

/// OpenRouter APIクライアント - API通信を担当
class GeminiApiClient {
  final http.Client _httpClient;
  final ILoggingService _logger;

  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 60);

  GeminiApiClient({required ILoggingService logger, http.Client? httpClient})
    : _logger = logger,
      _httpClient = httpClient ?? http.Client();

  static Uri get _apiUrl => Uri.parse(AiConstants.openRouterChatCompletionsUrl);

  String get _apiKey {
    final key = EnvironmentConfig.openRouterApiKey;
    if (key.isEmpty) {
      _logger.warning(
        'OPENROUTER_API_KEY is not configured',
        context: 'GeminiApiClient._apiKey',
      );
      EnvironmentConfig.printDebugInfo();
    }
    return key;
  }

  /// テキストベースのAPIリクエストを送信
  Future<Result<Map<String, dynamic>>> sendTextRequest({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    return _executeRequest(
      content: [
        {'type': 'text', 'text': prompt},
      ],
      requestContext: 'sendTextRequest',
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// 画像付きのAPIリクエストを送信（Vision）
  Future<Result<Map<String, dynamic>>> sendVisionRequest({
    required String prompt,
    required Uint8List imageData,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    // APIキー検証を先に行い、無効時に高コストなBase64エンコードを回避
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.error(
        'OpenRouter API error: No valid API key configured',
        context: 'sendVisionRequest',
      );
      EnvironmentConfig.printDebugInfo();
      return const Failure(
        AiProcessingException('No valid API key configured'),
      );
    }

    final base64Image = base64Encode(imageData);

    return _executeRequest(
      content: [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
        },
      ],
      requestContext: 'sendVisionRequest',
      temperature: temperature,
      maxOutputTokens: maxOutputTokens,
    );
  }

  /// API リクエストの共通処理
  Future<Result<Map<String, dynamic>>> _executeRequest({
    required List<Map<String, dynamic>> content,
    required String requestContext,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.error(
        'OpenRouter API error: No valid API key configured',
        context: requestContext,
      );
      EnvironmentConfig.printDebugInfo();
      return const Failure(
        AiProcessingException('No valid API key configured'),
      );
    }

    try {
      final response = await postWithRetry(
        _apiUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': AiConstants.openRouterModelName,
          'messages': [
            {'role': 'user', 'content': content},
          ],
          'temperature': temperature ?? AiConstants.defaultTemperature,
          'max_tokens': maxOutputTokens ?? AiConstants.defaultMaxOutputTokens,
          'top_p': AiConstants.defaultTopP,
        }),
        requestContext: requestContext,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.debug(
          'OpenRouter API response received successfully',
          context: requestContext,
          data: _summarizeResponse(data as Map<String, dynamic>),
        );
        return Success(data);
      } else {
        _logger.error(
          'OpenRouter API error: ${response.statusCode}',
          context: requestContext,
        );
        return Failure(
          AiProcessingException(
            'OpenRouter API error: ${response.statusCode}',
            details: response.body,
          ),
        );
      }
    } on NetworkException catch (e) {
      return Failure(e);
    } catch (e) {
      _logger.error(
        'OpenRouter API request error',
        context: requestContext,
        error: e,
      );
      return Failure(
        AiProcessingException(
          'OpenRouter API request failed',
          originalError: e,
        ),
      );
    }
  }

  /// 指数バックオフ付きリトライでHTTP POSTを実行
  ///
  /// リトライ対象: SocketException, TimeoutException, ClientException,
  /// HTTP 429 (Rate Limit), HTTP 5xx (サーバーエラー)
  ///
  /// 全リトライ耗尽時は常に [NetworkException] をスローする。
  @visibleForTesting
  Future<http.Response> postWithRetry(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    required String requestContext,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _httpClient
            .post(url, headers: headers, body: body)
            .timeout(requestTimeout);

        if (response.statusCode == 200 ||
            !isRetryableStatusCode(response.statusCode)) {
          return response;
        }

        // リトライ対象のステータスコード
        lastError = 'HTTP ${response.statusCode}: ${response.body}';
        await _waitForRetry(
          'Retryable HTTP ${response.statusCode}',
          attempt,
          requestContext,
        );
      } on SocketException catch (e) {
        lastError = e;
        await _waitForRetry(
          'Network error (SocketException)',
          attempt,
          requestContext,
        );
      } on TimeoutException catch (e) {
        lastError = e;
        await _waitForRetry('Request timed out', attempt, requestContext);
      } on http.ClientException catch (e) {
        lastError = e;
        await _waitForRetry('HTTP client error', attempt, requestContext);
      }
    }

    // 全リトライ失敗 — 常に NetworkException をスロー
    _logger.error(
      'All $maxRetries retries exhausted',
      context: 'GeminiApiClient.$requestContext',
      error: lastError,
    );
    throw NetworkException(
      'Network request failed after $maxRetries retries',
      originalError: lastError,
    );
  }

  /// リトライ待機のヘルパー（最終試行では待機しない）
  Future<void> _waitForRetry(
    String message,
    int attempt,
    String requestContext,
  ) async {
    if (attempt < maxRetries) {
      final delay = baseDelay * (1 << attempt);
      _logger.warning(
        '$message, retrying in ${delay.inSeconds}s '
        '(attempt ${attempt + 1}/$maxRetries)',
        context: 'GeminiApiClient.$requestContext',
      );
      await Future<void>.delayed(delay);
    }
  }

  /// ステータスコードがリトライ対象かどうかを判定
  @visibleForTesting
  static bool isRetryableStatusCode(int statusCode) {
    return statusCode == 429 || (statusCode >= 500 && statusCode <= 599);
  }

  /// APIキーの有効性をテスト
  Future<bool> testApiKey() async {
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.warning(
        'API key test: No valid API key configured',
        context: 'testApiKey',
      );
      EnvironmentConfig.printDebugInfo();
      return false;
    }

    final result = await sendTextRequest(prompt: 'Hello, this is a test.');
    final isValid = result.isSuccess;
    _logger.info(
      'API key test',
      context: 'testApiKey',
      data: 'Result: ${isValid ? 'valid' : 'invalid'}',
    );
    return isValid;
  }

  /// APIレスポンスのサマリーを生成（ログ出力用）
  String _summarizeResponse(Map<String, dynamic> data) {
    try {
      final choices = data['choices'] as List?;
      final choiceCount = choices?.length ?? 0;
      String? finishReason;
      int? textLength;

      if (choices != null && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        finishReason = choice['finish_reason'] as String?;
        final text = extractTextFromResponse(data);
        textLength = text?.length;
      }

      return 'choices=$choiceCount, '
          'finishReason=$finishReason, '
          'textLength=$textLength';
    } catch (_) {
      return 'Failed to generate response summary';
    }
  }

  /// APIレスポンスからテキストコンテンツを抽出
  String? extractTextFromResponse(Map<String, dynamic> data) {
    try {
      final choices = data['choices'];
      if (choices is List && choices.isNotEmpty) {
        final choice = choices[0] as Map<String, dynamic>;
        final message = choice['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.isNotEmpty) {
            return content.trim();
          }
          if (content is List && content.isNotEmpty) {
            final buffer = StringBuffer();
            for (final part in content) {
              if (part is Map &&
                  part['type'] == 'text' &&
                  part['text'] is String) {
                buffer.write(part['text']);
              } else if (part is String) {
                buffer.write(part);
              }
            }
            final joined = buffer.toString().trim();
            if (joined.isNotEmpty) return joined;
          }
        }

        _logger.warning(
          'Text content not found - finish_reason: ${choice['finish_reason']}',
          context: 'extractTextFromResponse',
        );
        return null;
      }

      _logger.warning(
        'Response structure differs from expected format',
        context: 'extractTextFromResponse',
        data: data.toString(),
      );
      return null;
    } catch (e) {
      _logger.error(
        'Response parsing error',
        context: 'extractTextFromResponse',
        error: e,
      );
      return null;
    }
  }
}
