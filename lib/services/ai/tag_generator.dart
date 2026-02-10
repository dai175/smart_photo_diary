import 'dart:ui';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import 'gemini_api_client.dart';
import '../interfaces/logging_service_interface.dart';
import '../../core/service_locator.dart';

/// タグ生成を担当するサービス
class TagGenerator {
  final GeminiApiClient _apiClient;
  TagGenerator({GeminiApiClient? apiClient})
    : _apiClient = apiClient ?? GeminiApiClient();

  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// 日記の内容からタグを自動生成
  Future<List<String>> generateTags({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
    required bool isOnline,
    Locale? locale,
  }) async {
    if (!isOnline) {
      return _generateOfflineTags(title, content, date, photoCount, locale);
    }

    try {
      // 時間帯を取得
      final timeOfDay = _getTimeOfDay(date, locale);

      // 言語に応じたプロンプトを生成
      final prompt = _buildTagGenerationPrompt(
        title: title,
        content: content,
        date: date,
        photoCount: photoCount,
        timeOfDay: timeOfDay,
        locale: locale,
      );

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
          final baseTags = _generateBasicTags(date, photoCount, locale);
          final allTags = [...baseTags, ...tags];

          // 似たようなタグを統合
          final filteredTags = _filterSimilarTags(allTags, locale);

          return filteredTags.take(5).toList();
        }
      }

      _logger.warning(
        'タグ生成 API エラーまたはレスポンスなし',
        context: 'TagGenerator.generateTags',
      );
      return _generateOfflineTags(title, content, date, photoCount, locale);
    } catch (e) {
      _logger.error('タグ生成エラー', context: 'TagGenerator.generateTags', error: e);
      return _generateOfflineTags(title, content, date, photoCount, locale);
    }
  }

  /// オフライン時のタグ生成（基本的な情報のみ）
  List<String> _generateOfflineTags(
    String title,
    String content,
    DateTime date,
    int photoCount,
    Locale? locale,
  ) {
    final tags = _generateBasicTags(date, photoCount, locale);

    // 言語に応じたキーワード検索
    final fullText = '$title $content'.toLowerCase();
    final isEnglish = locale?.languageCode == 'en';

    // 食事関連
    if (_containsAny(
      fullText,
      isEnglish
          ? ['meal', 'breakfast', 'lunch', 'dinner', 'food']
          : ['食事', '朝食', '昼食', '夕食'],
    )) {
      tags.add(isEnglish ? 'Meal' : '食事');
    }

    // 外出関連
    if (_containsAny(
      fullText,
      isEnglish
          ? ['walk', 'outside', 'out', 'outdoor']
          : ['散歩', '歩', '外出', '出かけ'],
    )) {
      tags.add(isEnglish ? 'Outside' : '外出');
    }

    // 仕事関連
    if (_containsAny(
      fullText,
      isEnglish ? ['work', 'office', 'job'] : ['仕事', 'work', '職場'],
    )) {
      tags.add(isEnglish ? 'Work' : '仕事');
    }

    // 自宅関連
    if (_containsAny(
      fullText,
      isEnglish ? ['home', 'house', 'room'] : ['家', '自宅', '部屋'],
    )) {
      tags.add(isEnglish ? 'Home' : '自宅');
    }

    // 買い物関連
    if (_containsAny(
      fullText,
      isEnglish
          ? ['shopping', 'shop', 'buy', 'purchase']
          : ['買い物', 'ショッピング', '購入'],
    )) {
      tags.add(isEnglish ? 'Shopping' : '買い物');
    }

    // 友達関連
    if (_containsAny(
      fullText,
      isEnglish ? ['friend', 'friends', 'buddy'] : ['友達', '友人', '仲間'],
    )) {
      tags.add(isEnglish ? 'Friends' : '友達');
    }

    // 運動関連
    if (_containsAny(
      fullText,
      isEnglish
          ? ['exercise', 'sport', 'fitness', 'workout']
          : ['運動', 'スポーツ', 'トレーニング'],
    )) {
      tags.add(isEnglish ? 'Exercise' : '運動');
    }

    // 読書関連
    if (_containsAny(
      fullText,
      isEnglish ? ['reading', 'book', 'read'] : ['読書', '本', '読む'],
    )) {
      tags.add(isEnglish ? 'Reading' : '読書');
    }

    // 楽しい感情関連
    if (_containsAny(
      fullText,
      isEnglish ? ['fun', 'happy', 'joy', 'enjoy'] : ['楽しい', '嬉しい', '喜び'],
    )) {
      tags.add(isEnglish ? 'Happy' : '楽しい');
    }

    // リラックス関連
    if (_containsAny(
      fullText,
      isEnglish
          ? ['relax', 'calm', 'peaceful', 'rest']
          : ['リラックス', '癒し', 'のんびり', '休憩'],
    )) {
      tags.add(isEnglish ? 'Relax' : 'リラックス');
    }

    // 似たようなタグを統合
    final filteredTags = _filterSimilarTags(tags, locale);

    return filteredTags.take(5).toList();
  }

  /// 基本タグ（時間帯）を生成
  List<String> _generateBasicTags(
    DateTime date,
    int photoCount,
    Locale? locale,
  ) {
    final tags = <String>[];

    // 時間帯タグ
    final timeOfDay = _getTimeOfDay(date, locale);
    tags.add(timeOfDay);

    return tags;
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date, Locale? locale) {
    final hour = date.hour;
    final isEnglish = locale?.languageCode == 'en';

    if (hour >= AiConstants.morningStartHour &&
        hour < AiConstants.afternoonStartHour) {
      return isEnglish ? 'Morning' : '朝';
    }
    if (hour >= AiConstants.afternoonStartHour &&
        hour < AiConstants.eveningStartHour) {
      return isEnglish ? 'Noon' : '昼';
    }
    if (hour >= AiConstants.eveningStartHour &&
        hour < AiConstants.nightStartHour) {
      return isEnglish ? 'Evening' : '夕方';
    }
    return isEnglish ? 'Night' : '夜';
  }

  /// 似たようなタグを統合・フィルタリング
  List<String> _filterSimilarTags(List<String> tags, Locale? locale) {
    final filteredTags = <String>[];
    final isEnglish = locale?.languageCode == 'en';

    // 類似タグのマッピング（言語別）
    final similarTagGroups = isEnglish
        ? {
            'Meal': [
              'Breakfast',
              'Lunch',
              'Dinner',
              'Food',
              'Cooking',
              'Gourmet',
            ],
            'Outside': ['Walk', 'Outdoor', 'Outing', 'Walking'],
            'Home': ['House', 'Room', 'Indoor'],
            'Work': ['Office', 'Job', 'Task'],
            'Exercise': ['Sport', 'Training', 'Fitness', 'Workout'],
            'Reading': ['Book', 'Read', 'Library'],
            'Shopping': ['Purchase', 'Buy', 'Store'],
            'Relax': ['Rest', 'Calm', 'Peaceful', 'Break'],
            'Happy': ['Joy', 'Fun', 'Enjoy', 'Positive'],
            'Friends': ['Friend', 'Buddy', 'Pal'],
            'Study': ['Learning', 'Lesson', 'Class'],
            'Cooking': ['Cook', 'Recipe', 'Kitchen'],
            'Cleaning': ['Tidy', 'Organize', 'Clean'],
            'Movie': ['Video', 'Film', 'Watch'],
            'Music': ['Song', 'Instrument', 'Concert'],
          }
        : {
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

  /// 複数のキーワードのいずれかがテキストに含まれているかチェック
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword.toLowerCase()));
  }

  /// 言語に応じたタグ生成プロンプトを構築
  String _buildTagGenerationPrompt({
    required String title,
    required String content,
    required DateTime date,
    required int photoCount,
    required String timeOfDay,
    Locale? locale,
  }) {
    final isEnglish = locale?.languageCode == 'en';

    if (isEnglish) {
      return '''
Generate 3-5 appropriate tags from the following diary content.
Tags should be short words (1-3 words) that express the content and are useful for categorization.

Date: ${DateFormat('yyyy-MM-dd').format(date)}
Time of day: $timeOfDay
Number of photos: $photoCount

Title: $title
Content: $content

Please output in the following format (tag names only, comma-separated):
Breakfast,Walk,Relax

Notes:
- Please use short English words
- Choose from perspectives like meals, activities, places, emotions, time, etc.
- No "#" symbol needed
- Maximum 5 tags
''';
    } else {
      return '''
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
    }
  }
}
