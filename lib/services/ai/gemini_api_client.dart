import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/environment_config.dart';
import '../../constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../interfaces/logging_service_interface.dart';
import '../../core/service_locator.dart';

/// Gemini APIクライアント - API通信を担当
class GeminiApiClient {
  final http.Client _httpClient;
  final ILoggingService _logger;

  static const int maxRetries = 3;
  static const Duration baseDelay = Duration(seconds: 1);
  static const Duration requestTimeout = Duration(seconds: 30);

  GeminiApiClient({required ILoggingService logger, http.Client? httpClient})
    : _logger = logger,
      _httpClient = httpClient ?? http.Client();

  // Google Gemini APIのエンドポイント
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/${AiConstants.geminiModelName}:generateContent';

  // APIキーをEnvironmentConfigから取得
  static String get _apiKey {
    final key = EnvironmentConfig.geminiApiKey;
    if (key.isEmpty) {
      try {
        serviceLocator.get<ILoggingService>().warning(
          'GEMINI_API_KEY is not configured',
          context: 'GeminiApiClient._apiKey',
        );
      } catch (_) {
        // LoggingService unavailable in test
      }
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
    // APIキーの事前検証
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.error(
        'Gemini API error: No valid API key configured',
        context: 'sendTextRequest',
      );
      EnvironmentConfig.printDebugInfo();
      return const Failure(
        AiProcessingException('No valid API key configured'),
      );
    }

    try {
      final response = await postWithRetry(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
              'role': 'user',
            },
          ],
          'generationConfig': {
            'temperature': temperature ?? AiConstants.defaultTemperature,
            'maxOutputTokens':
                maxOutputTokens ?? AiConstants.defaultMaxOutputTokens,
            'topP': AiConstants.defaultTopP,
            'topK': AiConstants.defaultTopK,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        }),
        requestContext: 'sendTextRequest',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.debug(
          'Gemini API response received successfully',
          context: 'sendTextRequest',
          data: _summarizeResponse(data),
        );
        return Success(data as Map<String, dynamic>);
      } else {
        _logger.error(
          'Gemini API error: ${response.statusCode}',
          context: 'sendTextRequest',
        );
        return Failure(
          AiProcessingException(
            'Gemini API error: ${response.statusCode}',
            details: response.body,
          ),
        );
      }
    } on NetworkException catch (e) {
      return Failure(e);
    } catch (e) {
      _logger.error(
        'Gemini API request error',
        context: 'sendTextRequest',
        error: e,
      );
      return Failure(
        AiProcessingException('Gemini API request failed', originalError: e),
      );
    }
  }

  /// 画像付きのAPIリクエストを送信（Vision API）
  Future<Result<Map<String, dynamic>>> sendVisionRequest({
    required String prompt,
    required Uint8List imageData,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    // APIキーの事前検証
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.error(
        'Gemini Vision API error: No valid API key configured',
        context: 'sendVisionRequest',
      );
      EnvironmentConfig.printDebugInfo();
      return const Failure(
        AiProcessingException('No valid API key configured'),
      );
    }

    try {
      // Base64エンコード
      final base64Image = base64Encode(imageData);

      final response = await postWithRetry(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
                },
              ],
              'role': 'user',
            },
          ],
          'generationConfig': {
            'temperature': temperature ?? AiConstants.defaultTemperature,
            'maxOutputTokens':
                maxOutputTokens ?? AiConstants.defaultMaxOutputTokens,
            'topP': AiConstants.defaultTopP,
            'topK': AiConstants.defaultTopK,
            'thinkingConfig': {'thinkingBudget': 0},
          },
        }),
        requestContext: 'sendVisionRequest',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.debug(
          'Gemini Vision API response received successfully',
          context: 'sendVisionRequest',
          data: _summarizeResponse(data),
        );
        return Success(data as Map<String, dynamic>);
      } else {
        _logger.error(
          'Gemini Vision API error: ${response.statusCode}',
          context: 'sendVisionRequest',
        );
        return Failure(
          AiProcessingException(
            'Gemini Vision API error: ${response.statusCode}',
            details: response.body,
          ),
        );
      }
    } on NetworkException catch (e) {
      return Failure(e);
    } catch (e) {
      _logger.error(
        'Gemini Vision API request error',
        context: 'sendVisionRequest',
        error: e,
      );
      return Failure(
        AiProcessingException(
          'Gemini Vision API request failed',
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
      final candidates = data['candidates'] as List?;
      final candidateCount = candidates?.length ?? 0;
      String? finishReason;
      int? textLength;

      if (candidates != null && candidates.isNotEmpty) {
        final candidate = candidates[0] as Map<String, dynamic>;
        finishReason = candidate['finishReason'] as String?;
        final text = extractTextFromResponse(data);
        textLength = text?.length;
      }

      return 'candidates=$candidateCount, '
          'finishReason=$finishReason, '
          'textLength=$textLength';
    } catch (_) {
      return 'Failed to generate response summary';
    }
  }

  /// APIレスポンスからテキストコンテンツを抽出
  String? extractTextFromResponse(Map<String, dynamic> data) {
    try {
      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final candidate = data['candidates'][0];

        // Gemini 2.5の場合、異なるレスポンス構造の可能性を考慮
        String? content;

        // 通常の構造をチェック
        if (candidate['content'] != null &&
            candidate['content']['parts'] != null &&
            candidate['content']['parts'].isNotEmpty &&
            candidate['content']['parts'][0]['text'] != null) {
          content = candidate['content']['parts'][0]['text'];
        }
        // 代替構造をチェック（直接textフィールド）
        else if (candidate['content'] != null &&
            candidate['content']['text'] != null) {
          content = candidate['content']['text'];
        }
        // 思考プロセス用の構造をチェック
        else if (candidate['text'] != null) {
          content = candidate['text'];
        }

        if (content != null && content.isNotEmpty) {
          return content.trim();
        } else {
          _logger.warning(
            'Text content not found - finishReason: ${candidate['finishReason']}',
            context: 'extractTextFromResponse',
          );
          return null;
        }
      } else {
        _logger.warning(
          'Response structure differs from expected format',
          context: 'extractTextFromResponse',
          data: data.toString(),
        );
        return null;
      }
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
