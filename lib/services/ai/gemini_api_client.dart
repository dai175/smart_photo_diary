import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../config/environment_config.dart';
import '../../constants/app_constants.dart';
import '../logging_service.dart';
import '../../core/service_locator.dart';

/// Gemini APIクライアント - API通信を担当
class GeminiApiClient {
  LoggingService get _logger => serviceLocator.get<LoggingService>();

  // Google Gemini APIのエンドポイント
  static String get _apiUrl =>
      'https://generativelanguage.googleapis.com/v1beta/models/${AiConstants.geminiModelName}:generateContent';

  // APIキーをEnvironmentConfigから取得
  static String get _apiKey {
    final key = EnvironmentConfig.geminiApiKey;
    if (key.isEmpty) {
      final client = GeminiApiClient();
      client._logger.warning(
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
      _logger.error(
        'Gemini API エラー: 有効なAPIキーが設定されていません',
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
        _logger.debug(
          'Gemini API レスポンス受信成功',
          context: 'sendTextRequest',
          data: data.toString(),
        );
        return data;
      } else {
        _logger.error(
          'Gemini API エラー: ${response.statusCode}',
          context: 'sendTextRequest',
        );
        return null;
      }
    } catch (e) {
      _logger.error(
        'Gemini API リクエストエラー',
        context: 'sendTextRequest',
        error: e,
      );
      _logger.debug(
        'API接続情報: apiKeyPrefix=${_apiKey.isNotEmpty ? '${_apiKey.substring(0, 8)}...' : '空'}',
        context: 'sendTextRequest',
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
      _logger.error(
        'Gemini Vision API エラー: 有効なAPIキーが設定されていません',
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
        _logger.debug(
          'Gemini Vision API レスポンス受信成功',
          context: 'sendVisionRequest',
          data: data.toString(),
        );
        return data;
      } else {
        _logger.error(
          'Gemini Vision API エラー: ${response.statusCode}',
          context: 'sendVisionRequest',
        );
        return null;
      }
    } catch (e) {
      _logger.error(
        'Gemini Vision API リクエストエラー',
        context: 'sendVisionRequest',
        error: e,
      );
      _logger.debug(
        'Vision API接続情報: apiKeyPrefix=${_apiKey.isNotEmpty ? '${_apiKey.substring(0, 8)}...' : '空'}',
        context: 'sendVisionRequest',
      );
      return null;
    }
  }

  /// APIキーの有効性をテスト
  Future<bool> testApiKey() async {
    if (!EnvironmentConfig.hasValidApiKey) {
      _logger.warning('APIキーテスト: 有効なAPIキーが設定されていません', context: 'testApiKey');
      EnvironmentConfig.printDebugInfo();
      return false;
    }

    try {
      final response = await sendTextRequest(prompt: 'Hello, this is a test.');
      final isValid = response != null;
      _logger.info(
        'APIキーテスト',
        context: 'testApiKey',
        data: '結果: ${isValid ? '有効' : '無効'}',
      );
      return isValid;
    } catch (e) {
      _logger.error('APIキーテストエラー', context: 'testApiKey', error: e);
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
          _logger.warning(
            'テキストコンテンツが見つかりません - finishReason: ${candidate['finishReason']}',
            context: 'extractTextFromResponse',
          );
          return null;
        }
      } else {
        _logger.warning(
          'レスポンス構造が予期されたものと異なります',
          context: 'extractTextFromResponse',
          data: data.toString(),
        );
        return null;
      }
    } catch (e) {
      _logger.error('レスポンス解析エラー', context: 'extractTextFromResponse', error: e);
      return null;
    }
  }
}
