import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/environment_config.dart';
import '../../constants/app_constants.dart';
import '../logging_service.dart';

/// Gemini APIクライアント - API通信を担当
class GeminiApiClient {
  /// ログ出力メソッド
  void _log(
    String message, {
    LogLevel level = LogLevel.info,
    String? context,
    dynamic data,
    dynamic error,
  }) {
    try {
      final loggingService = LoggingService.instance;
      switch (level) {
        case LogLevel.debug:
          loggingService.debug(message, context: context, data: data);
          break;
        case LogLevel.info:
          loggingService.info(message, context: context, data: data);
          break;
        case LogLevel.warning:
          loggingService.warning(message, context: context, data: data);
          break;
        case LogLevel.error:
          loggingService.error(message, context: context, error: error);
          break;
      }
    } catch (e) {
      // LoggingServiceが初期化されていない場合はフォールバック
      debugPrint('[$level] $message');
    }
  }

  // Google Gemini APIのエンドポイント
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/${AiConstants.geminiModelName}:generateContent';

  // APIキーをEnvironmentConfigから取得
  static String get _apiKey {
    final key = EnvironmentConfig.geminiApiKey;
    if (key.isEmpty) {
      final client = GeminiApiClient();
      client._log(
        'GEMINI_API_KEYが設定されていません',
        level: LogLevel.warning,
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
      _log(
        'Gemini API エラー: 有効なAPIキーが設定されていません',
        level: LogLevel.error,
        context: 'sendTextRequest',
      );
      EnvironmentConfig.printDebugInfo();
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
        _log(
          'Gemini API レスポンス受信成功',
          level: LogLevel.debug,
          context: 'sendTextRequest',
          data: data,
        );
        return data;
      } else {
        _log(
          'Gemini API エラー',
          level: LogLevel.error,
          context: 'sendTextRequest',
          data: {
            'statusCode': response.statusCode,
            'body': response.body,
            'apiKeyPrefix': _apiKey.isNotEmpty
                ? '${_apiKey.substring(0, 8)}...'
                : '空',
          },
        );
        return null;
      }
    } catch (e) {
      _log(
        'Gemini API リクエストエラー',
        level: LogLevel.error,
        context: 'sendTextRequest',
        error: e,
      );
      _log(
        'API接続情報',
        level: LogLevel.debug,
        context: 'sendTextRequest',
        data: {
          'apiKeyPrefix': _apiKey.isNotEmpty
              ? '${_apiKey.substring(0, 8)}...'
              : '空',
        },
      );
      return null;
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
      _log(
        'Gemini Vision API エラー: 有効なAPIキーが設定されていません',
        level: LogLevel.error,
        context: 'sendVisionRequest',
      );
      EnvironmentConfig.printDebugInfo();
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
        _log(
          'Gemini Vision API レスポンス受信成功',
          level: LogLevel.debug,
          context: 'sendVisionRequest',
          data: data,
        );
        return data;
      } else {
        _log(
          'Gemini Vision API エラー',
          level: LogLevel.error,
          context: 'sendVisionRequest',
          data: {
            'statusCode': response.statusCode,
            'body': response.body,
            'apiKeyPrefix': _apiKey.isNotEmpty
                ? '${_apiKey.substring(0, 8)}...'
                : '空',
          },
        );
        return null;
      }
    } catch (e) {
      _log(
        'Gemini Vision API リクエストエラー',
        level: LogLevel.error,
        context: 'sendVisionRequest',
        error: e,
      );
      _log(
        'Vision API接続情報',
        level: LogLevel.debug,
        context: 'sendVisionRequest',
        data: {
          'apiKeyPrefix': _apiKey.isNotEmpty
              ? '${_apiKey.substring(0, 8)}...'
              : '空',
        },
      );
      return null;
    }
  }

  /// APIキーの有効性をテスト
  Future<bool> testApiKey() async {
    if (!EnvironmentConfig.hasValidApiKey) {
      _log(
        'APIキーテスト: 有効なAPIキーが設定されていません',
        level: LogLevel.warning,
        context: 'testApiKey',
      );
      EnvironmentConfig.printDebugInfo();
      return false;
    }

    try {
      final response = await sendTextRequest(prompt: 'Hello, this is a test.');
      final isValid = response != null;
      _log(
        'APIキーテスト',
        level: LogLevel.info,
        context: 'testApiKey',
        data: {'結果': isValid ? '有効' : '無効'},
      );
      return isValid;
    } catch (e) {
      _log(
        'APIキーテストエラー',
        level: LogLevel.error,
        context: 'testApiKey',
        error: e,
      );
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
          _log(
            'テキストコンテンツが見つかりません',
            level: LogLevel.warning,
            context: 'extractTextFromResponse',
            data: {'finishReason': candidate['finishReason']},
          );
          return null;
        }
      } else {
        _log(
          'レスポンス構造が予期されたものと異なります',
          level: LogLevel.warning,
          context: 'extractTextFromResponse',
          data: data,
        );
        return null;
      }
    } catch (e) {
      _log(
        'レスポンス解析エラー',
        level: LogLevel.error,
        context: 'extractTextFromResponse',
        error: e,
      );
      return null;
    }
  }
}
