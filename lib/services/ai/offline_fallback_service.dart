import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import 'ai_service_interface.dart';

/// オフライン時のフォールバック機能を提供するサービス
class OfflineFallbackService {
  /// オフライン時のシンプルな日記生成
  DiaryGenerationResult generateDiary(
    List<String> labels,
    DateTime date,
    String? location,
    List<DateTime>? photoTimes,
  ) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    final timeOfDay = _getTimeOfDayForPhotos(date, photoTimes);

    // シンプルなテンプレートベースの日記
    final locationText = location != null && location.isNotEmpty
        ? '${location}で'
        : '';

    String title;
    String content;

    if (labels.isEmpty) {
      title = '今日の記録';
      content = '$dateStr、${locationText}過ごした一日の記録です。';
    } else if (labels.length == 1) {
      title = '${labels[0]}の$timeOfDay';
      content = '$dateStr、${timeOfDay}に$locationText${labels[0]}について過ごしました。';
    } else {
      title = '${labels.first}と${labels.length - 1}つの出来事';
      content = '$dateStr、${timeOfDay}に$locationText${labels.join('や')}などについて過ごしました。';
    }

    return DiaryGenerationResult(title: title, content: content);
  }

  /// オフライン時の日記生成（写真枚数に応じたバリエーション）
  DiaryGenerationResult generateDiaryWithPhotoCount(
    List<String> labels,
    DateTime date,
    String? location,
    List<DateTime>? photoTimes,
    int photoCount,
  ) {
    final dateStr = DateFormat('yyyy年MM月dd日').format(date);
    final timeOfDay = _getTimeOfDayForPhotos(date, photoTimes);
    
    final locationText = location != null && location.isNotEmpty
        ? '${location}で'
        : '';

    String title;
    String content;

    // 写真枚数に応じたタイトル生成
    if (photoCount == 1) {
      title = labels.isNotEmpty ? '${labels.first}の瞬間' : '今日の一枚';
    } else if (photoCount <= 3) {
      title = labels.isNotEmpty ? '${labels.first}の記録' : '今日の思い出';
    } else {
      title = labels.isNotEmpty ? '${labels.first}な一日' : '充実した一日';
    }

    // 本文生成
    if (labels.isEmpty) {
      if (photoCount == 1) {
        content = '$dateStr、${timeOfDay}に$locationText撮った一枚の写真。この瞬間を記録に残しました。';
      } else {
        content = '$dateStr、${timeOfDay}に$locationText${photoCount}枚の写真を撮影。様々な瞬間を記録に残した一日でした。';
      }
    } else {
      final keywordText = labels.length == 1 
          ? labels.first
          : '${labels.take(2).join('や')}など';
      
      if (photoCount == 1) {
        content = '$dateStr、${timeOfDay}に$locationText$keywordText の瞬間を写真に収めました。';
      } else {
        content = '$dateStr、${timeOfDay}に$locationText$keywordText について${photoCount}枚の写真を撮影。充実した時間を過ごすことができました。';
      }
    }

    return DiaryGenerationResult(title: title, content: content);
  }

  /// 時間帯の文字列を取得
  String _getTimeOfDay(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour && hour < AiConstants.afternoonStartHour) return '朝';
    if (hour >= AiConstants.afternoonStartHour && hour < AiConstants.eveningStartHour) return '昼';
    if (hour >= AiConstants.eveningStartHour && hour < AiConstants.nightStartHour) return '夕方';
    return '夜';
  }

  /// 複数写真の撮影時刻を考慮した時間帯を取得
  String _getTimeOfDayForPhotos(DateTime baseDate, List<DateTime>? photoTimes) {
    if (photoTimes == null || photoTimes.isEmpty) {
      return _getTimeOfDay(baseDate);
    }
    
    if (photoTimes.length == 1) {
      return _getTimeOfDay(photoTimes.first);
    }
    
    // 複数写真の場合、異なる時間帯にまたがっているかチェック
    final timeOfDaySet = <String>{};
    for (final time in photoTimes) {
      timeOfDaySet.add(_getTimeOfDay(time));
    }
    
    if (timeOfDaySet.length == 1) {
      // 全て同じ時間帯
      return timeOfDaySet.first;
    } else {
      // 複数の時間帯にまたがっている場合
      final sortedTimes = timeOfDaySet.toList();
      if (sortedTimes.contains('朝') && sortedTimes.contains('昼')) {
        return '朝から昼にかけて';
      } else if (sortedTimes.contains('昼') && sortedTimes.contains('夕方')) {
        return '昼から夕方にかけて';
      } else if (sortedTimes.contains('夕方') && sortedTimes.contains('夜')) {
        return '夕方から夜にかけて';
      } else {
        return '一日を通して';
      }
    }
  }

  /// オフライン時の基本的なタグ生成
  List<String> generateBasicTags(DateTime date, int photoCount) {
    final tags = <String>[];
    
    // 時間帯タグ
    final timeOfDay = _getTimeOfDay(date);
    tags.add(timeOfDay);
    
    // 写真枚数に応じたタグ
    if (photoCount == 1) {
      tags.add('一枚');
    } else if (photoCount <= 3) {
      tags.add('少数');
    } else {
      tags.add('複数');
    }
    
    // 曜日タグ
    final weekday = _getWeekdayName(date);
    tags.add(weekday);
    
    return tags;
  }

  /// 曜日名を取得
  String _getWeekdayName(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  /// シンプルなキーワードベースの感情分析
  String analyzeEmotionFromKeywords(List<String> labels) {
    final positiveKeywords = ['笑顔', '楽しい', '嬉しい', '美味しい', '綺麗', '素敵', '幸せ'];
    final relaxKeywords = ['リラックス', '癒し', 'のんびり', '静か', '穏やか'];
    final activeKeywords = ['運動', 'スポーツ', '散歩', '活動', 'アクティブ'];
    
    for (final label in labels) {
      if (positiveKeywords.any((keyword) => label.contains(keyword))) {
        return '楽しい';
      }
      if (relaxKeywords.any((keyword) => label.contains(keyword))) {
        return 'リラックス';
      }
      if (activeKeywords.any((keyword) => label.contains(keyword))) {
        return 'アクティブ';
      }
    }
    
    return '日常';
  }

  /// 季節に応じたテンプレート生成
  String getSeasonalTemplate(DateTime date) {
    final month = date.month;
    
    if (month >= 3 && month <= 5) {
      // 春
      return '新緑の季節、';
    } else if (month >= 6 && month <= 8) {
      // 夏
      return '暑い夏の日、';
    } else if (month >= 9 && month <= 11) {
      // 秋
      return '秋の涼しい日、';
    } else {
      // 冬
      return '寒い冬の日、';
    }
  }

  /// 時間帯に応じた挨拶テンプレート
  String getTimeGreeting(DateTime date) {
    final hour = date.hour;
    
    if (hour >= 5 && hour < 12) {
      return '朝から';
    } else if (hour >= 12 && hour < 17) {
      return '昼間に';
    } else if (hour >= 17 && hour < 21) {
      return '夕方から';
    } else {
      return '夜に';
    }
  }
}