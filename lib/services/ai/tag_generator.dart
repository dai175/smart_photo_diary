import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import 'gemini_api_client.dart';
import '../logging_service.dart';

/// タグ生成を担当するサービス
class TagGenerator {
  final GeminiApiClient _apiClient;

  TagGenerator({GeminiApiClient? apiClient})
    : _apiClient = apiClient ?? GeminiApiClient();

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

  /// 日記の内容からタグを自動生成
  Future<List<String>> generateTags({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
    required bool isOnline,
  }) async {
    if (!isOnline) {
      return _generateOfflineTags(title, content, date, photoCount);
    }

    try {
      // 時間帯を取得
      final timeOfDay = _getTimeOfDay(date);

      // タグ生成用プロンプト
      final prompt =
          '''
以下の日記の内容から、適切なタグを3-5個生成してください。
タグは日記の内容を表現する短い単語（1-3文字程度）で、カテゴリ分けに役立つものにしてください。

日付: ${DateFormat('yyyy年MM月dd日').format(date)}
時間帯: $timeOfDay
写真枚数: $photoCount枚

タイトル: $title
本文: $content

以下の形式で出力してください（タグ名のみをカンマ区切りで）：
朝食,散歩,リラックス

注意事項：
- 日本語の短い単語でお願いします
- 食事、活動、場所、感情、時間などの観点から選んでください
- 「#」記号は不要です
- 最大5個まで
''';

      final response = await _apiClient.sendTextRequest(
        prompt: prompt,
        temperature: AiConstants.tagGenerationTemperature,
        maxOutputTokens: 100,
      );

      if (response != null) {
        final tagText = _apiClient.extractTextFromResponse(response);

        if (tagText != null && tagText.isNotEmpty) {
          // カンマ区切りでタグを分割
          final tags = tagText
              .trim()
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .take(5)
              .toList();

          // 基本タグ（時間帯）を追加
          final baseTags = _generateBasicTags(date, photoCount);
          final allTags = [...baseTags, ...tags];

          // 似たようなタグを統合
          final filteredTags = _filterSimilarTags(allTags);

          return filteredTags.take(5).toList();
        }
      }

      _log(
        'タグ生成 API エラーまたはレスポンスなし',
        level: LogLevel.warning,
        context: 'generateTags',
      );
      return _generateOfflineTags(title, content, date, photoCount);
    } catch (e) {
      _log('タグ生成エラー', level: LogLevel.error, context: 'generateTags', error: e);
      return _generateOfflineTags(title, content, date, photoCount);
    }
  }

  /// オフライン時のタグ生成（基本的な情報のみ）
  List<String> _generateOfflineTags(
    String title,
    String content,
    DateTime date,
    int photoCount,
  ) {
    final tags = _generateBasicTags(date, photoCount);

    // シンプルなキーワード検索
    final fullText = '$title $content'.toLowerCase();

    if (fullText.contains('食事') ||
        fullText.contains('朝食') ||
        fullText.contains('昼食') ||
        fullText.contains('夕食')) {
      tags.add('食事');
    }
    if (fullText.contains('散歩') || fullText.contains('歩')) {
      tags.add('外出');
    }
    if (fullText.contains('仕事') || fullText.contains('work')) {
      tags.add('仕事');
    }
    if (fullText.contains('家') || fullText.contains('自宅')) {
      tags.add('自宅');
    }
    if (fullText.contains('買い物') || fullText.contains('ショッピング')) {
      tags.add('買い物');
    }
    if (fullText.contains('友達') || fullText.contains('友人')) {
      tags.add('友達');
    }
    if (fullText.contains('運動') || fullText.contains('スポーツ')) {
      tags.add('運動');
    }
    if (fullText.contains('読書') || fullText.contains('本')) {
      tags.add('読書');
    }
    if (fullText.contains('楽しい') || fullText.contains('嬉しい')) {
      tags.add('楽しい');
    }
    if (fullText.contains('リラックス') || fullText.contains('癒し')) {
      tags.add('リラックス');
    }

    // 似たようなタグを統合
    final filteredTags = _filterSimilarTags(tags);

    return filteredTags.take(5).toList();
  }

  /// 基本タグ（時間帯）を生成
  List<String> _generateBasicTags(DateTime date, int photoCount) {
    final tags = <String>[];

    // 時間帯タグ
    final timeOfDay = _getTimeOfDay(date);
    tags.add(timeOfDay);

    return tags;
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour &&
        hour < AiConstants.afternoonStartHour)
      return '朝';
    if (hour >= AiConstants.afternoonStartHour &&
        hour < AiConstants.eveningStartHour)
      return '昼';
    if (hour >= AiConstants.eveningStartHour &&
        hour < AiConstants.nightStartHour)
      return '夕方';
    return '夜';
  }

  /// 似たようなタグを統合・フィルタリング
  List<String> _filterSimilarTags(List<String> tags) {
    final filteredTags = <String>[];

    // 類似タグのマッピング
    final similarTagGroups = {
      '食事': ['朝食', '昼食', '夕食', 'ご飯', '食べ物', '料理', 'グルメ'],
      '外出': ['散歩', 'お出かけ', '外', '屋外', 'ウォーキング'],
      '自宅': ['家', '部屋', '室内', 'おうち'],
      '仕事': ['作業', 'お仕事', 'ワーク'],
      '運動': ['スポーツ', 'トレーニング', 'エクササイズ', '筋トレ'],
      '読書': ['本', '読み物', '図書'],
      '買い物': ['ショッピング', '購入', 'お買い物'],
      'リラックス': ['癒し', 'のんびり', 'ゆっくり', '休憩'],
      '楽しい': ['嬉しい', 'ハッピー', '喜び', 'ポジティブ'],
      '友達': ['友人', '友だち', '仲間'],
      '勉強': ['学習', '学び', '勉強会'],
      '料理': ['調理', 'クッキング', '手料理'],
      '掃除': ['片付け', '整理', '清掃'],
      '映画': ['動画', 'ムービー', '視聴'],
      '音楽': ['歌', '楽器', 'ライブ'],
    };

    final usedGroups = <String>{};

    for (final tag in tags) {
      bool grouped = false;

      // 各グループをチェック
      for (final entry in similarTagGroups.entries) {
        final groupName = entry.key;
        final groupTags = entry.value;

        // このタグがグループに属するかチェック
        if (groupTags.contains(tag) || tag == groupName) {
          if (!usedGroups.contains(groupName)) {
            filteredTags.add(groupName); // グループの代表名を使用
            usedGroups.add(groupName);
          }
          grouped = true;
          break;
        }
      }

      // どのグループにも属さない場合はそのまま追加
      if (!grouped && !filteredTags.contains(tag)) {
        filteredTags.add(tag);
      }
    }

    return filteredTags;
  }
}
