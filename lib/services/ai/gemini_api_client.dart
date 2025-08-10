import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/environment_config.dart';
import '../../constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/result/result.dart';
import '../logging_service.dart';

/// Gemini APIクライアント - API通信を担当
class GeminiApiClient {
  // Google Gemini APIのエンドポイント
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/${AiConstants.geminiModelName}:generateContent';

  // APIキーをEnvironmentConfigから取得
  static String get _apiKey {
    final key = EnvironmentConfig.geminiApiKey;
    if (key.isEmpty && kDebugMode) {
      LoggingService.instance.warning(
        'GEMINI_API_KEYが設定されていません',
        context: 'GeminiApiClient._apiKey',
      );
      EnvironmentConfig.printDebugInfo();
    }
    return key;
  }

  /// テキストベースのAPIリクエストを送信
  Future<Map<String, dynamic>?> sendTextRequest({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    // APIキーの事前検証
    if (!EnvironmentConfig.hasValidApiKey) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'Gemini API エラー: 有効なAPIキーが設定されていません',
          context: 'GeminiApiClient.sendTextRequest',
        );
        EnvironmentConfig.printDebugInfo();
      }
      return null;
    }

    try {
      final response = await http.post(
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          LoggingService.instance.debug(
            'Gemini API レスポンス受信',
            context: 'GeminiApiClient.sendTextRequest',
            data: {'responseSize': response.body.length},
          );
        }
        return data;
      } else {
        if (kDebugMode) {
          LoggingService.instance.error(
            'Gemini API エラー: ${response.statusCode} - ${response.body}',
            context: 'GeminiApiClient.sendTextRequest',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'Gemini API リクエストエラー',
          context: 'GeminiApiClient.sendTextRequest',
          error: e,
        );
      }
      return null;
    }
  }

  /// テキストベースのAPIリクエストを送信（Result<T>パターン）
  Future<Result<Map<String, dynamic>>> sendTextRequestResult({
    required String prompt,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    try {
      // APIキーの事前検証
      if (!EnvironmentConfig.hasValidApiKey) {
        return Failure(
          AiResourceException(
            'Gemini API: 有効なAPIキーが設定されていません',
            details: '環境変数GEMINI_API_KEYを確認してください',
          ),
        );
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          LoggingService.instance.debug(
            'Gemini API レスポンス受信',
            context: 'GeminiApiClient.sendTextRequestResult',
            data: {'responseSize': response.body.length},
          );
        }
        return Success(data);
      } else {
        if (kDebugMode) {
          LoggingService.instance.error(
            'Gemini API エラー: ${response.statusCode} - ${response.body}',
            context: 'GeminiApiClient.sendTextRequestResult',
          );
        }
        return Failure(
          NetworkException(
            'Gemini API リクエストが失敗しました',
            details: 'HTTP ${response.statusCode}: ${response.body}',
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'Gemini API リクエストエラー',
          context: 'GeminiApiClient.sendTextRequestResult',
          error: e,
        );
      }
      return Failure(
        NetworkException(
          'Gemini API通信中にエラーが発生しました',
          details: e.toString(),
          originalError: e,
        ),
      );
    }
  }

  /// 画像付きのAPIリクエストを送信（Vision API）
  Future<Map<String, dynamic>?> sendVisionRequest({
    required String prompt,
    required Uint8List imageData,
    double? temperature,
    int? maxOutputTokens,
  }) async {
    // APIキーの事前検証
    if (!EnvironmentConfig.hasValidApiKey) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'Gemini Vision API エラー: 有効なAPIキーが設定されていません',
          context: 'GeminiApiClient.sendVisionRequest',
        );
        EnvironmentConfig.printDebugInfo();
      }
      return null;
    }

    try {
      // Base64エンコード
      final base64Image = base64Encode(imageData);

      final response = await http.post(
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
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          LoggingService.instance.debug(
            'Gemini Vision API レスポンス受信',
            context: 'GeminiApiClient.sendVisionRequest',
            data: {'responseSize': response.body.length},
          );
        }
        return data;
      } else {
        if (kDebugMode) {
          LoggingService.instance.error(
            'Gemini Vision API エラー: ${response.statusCode} - ${response.body}',
            context: 'GeminiApiClient.sendVisionRequest',
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'Gemini Vision API リクエストエラー',
          context: 'GeminiApiClient.sendVisionRequest',
          error: e,
        );
      }
      return null;
    }
  }

  /// APIキーの有効性をテスト
  Future<bool> testApiKey() async {
    if (!EnvironmentConfig.hasValidApiKey) {
      if (kDebugMode) {
        LoggingService.instance.warning(
          'APIキーテスト: 有効なAPIキーが設定されていません',
          context: 'GeminiApiClient.testApiKey',
        );
        EnvironmentConfig.printDebugInfo();
      }
      return false;
    }

    try {
      final response = await sendTextRequest(prompt: 'Hello, this is a test.');
      final isValid = response != null;
      if (kDebugMode) {
        LoggingService.instance.info(
          'APIキーテスト結果',
          context: 'GeminiApiClient.testApiKey',
          data: {'valid': isValid},
        );
      }
      return isValid;
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'APIキーテストエラー',
          context: 'GeminiApiClient.testApiKey',
          error: e,
        );
      }
      return false;
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
          if (kDebugMode) {
            LoggingService.instance.warning(
              'テキストコンテンツが見つかりません',
              context: 'GeminiApiClient.extractTextFromResponse',
              data: {'finishReason': candidate['finishReason']},
            );
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          LoggingService.instance.warning(
            'レスポンス構造が予期されたものと異なります',
            context: 'GeminiApiClient.extractTextFromResponse',
            data: {'unexpectedData': data.toString()},
          );
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        LoggingService.instance.error(
          'レスポンス解析エラー',
          context: 'GeminiApiClient.extractTextFromResponse',
          error: e,
        );
      }
      return null;
    }
  }
}
