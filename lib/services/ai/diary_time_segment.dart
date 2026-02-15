import 'dart:ui';
import '../../constants/ai_constants.dart';
import 'diary_locale_utils.dart';

/// 時間帯判定ユーティリティ
class DiaryTimeSegment {
  DiaryTimeSegment._();

  static String timeSegment(DateTime date) {
    final hour = date.hour;
    if (hour >= AiConstants.morningStartHour &&
        hour < AiConstants.afternoonStartHour) {
      return 'morning';
    }
    if (hour >= AiConstants.afternoonStartHour &&
        hour < AiConstants.eveningStartHour) {
      return 'afternoon';
    }
    if (hour >= AiConstants.eveningStartHour &&
        hour < AiConstants.nightStartHour) {
      return 'evening';
    }
    return 'night';
  }

  static String segmentLabel(String segment, Locale locale) {
    final isJapanese = DiaryLocaleUtils.isJapanese(locale);
    switch (segment) {
      case 'morning':
        return isJapanese ? '朝' : 'Morning';
      case 'afternoon':
        return isJapanese ? '昼' : 'Afternoon';
      case 'evening':
        return isJapanese ? '夕方' : 'Evening';
      case 'night':
      default:
        return isJapanese ? '夜' : 'Night';
    }
  }

  static int segmentOrder(String segment) {
    switch (segment) {
      case 'morning':
        return 0;
      case 'afternoon':
        return 1;
      case 'evening':
        return 2;
      case 'night':
      default:
        return 3;
    }
  }

  static String throughoutDay(Locale locale) =>
      DiaryLocaleUtils.isJapanese(locale) ? '一日を通して' : 'Throughout the day';

  static String combineSegments(Set<String> segments, Locale locale) {
    if (segments.isEmpty) {
      return throughoutDay(locale);
    }
    if (segments.length == 1) {
      return segmentLabel(segments.first, locale);
    }
    final sorted = segments.toList()
      ..sort((a, b) => segmentOrder(a).compareTo(segmentOrder(b)));
    if (sorted.length == 2) {
      final first = segmentLabel(sorted.first, locale);
      final second = segmentLabel(sorted.last, locale);
      if (DiaryLocaleUtils.isJapanese(locale)) {
        return '$firstから$secondにかけて';
      }
      return '$first to $second';
    }
    return throughoutDay(locale);
  }

  /// 時間帯の文字列を取得
  static String getTimeOfDay(DateTime date, Locale locale) {
    return segmentLabel(timeSegment(date), locale);
  }

  /// 複数写真の撮影時刻を考慮した時間帯を取得
  static String getTimeOfDayForPhotos(
    DateTime baseDate,
    List<DateTime>? photoTimes,
    Locale locale,
  ) {
    if (photoTimes == null || photoTimes.isEmpty) {
      return getTimeOfDay(baseDate, locale);
    }

    if (photoTimes.length == 1) {
      return getTimeOfDay(photoTimes.first, locale);
    }

    final segments = <String>{};
    for (final time in photoTimes) {
      segments.add(timeSegment(time));
    }

    return combineSegments(segments, locale);
  }
}
