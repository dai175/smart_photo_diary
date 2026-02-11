import 'dart:ui';
import 'package:intl/intl.dart';

/// 日記生成に必要なロケール関連ユーティリティ
class DiaryLocaleUtils {
  DiaryLocaleUtils._();

  static bool isJapanese(Locale locale) =>
      locale.languageCode.toLowerCase() == 'ja';

  static String toLocaleTag(Locale locale) {
    final tag = locale.toLanguageTag();
    return tag.isEmpty ? locale.languageCode : tag;
  }

  static String formatDate(DateTime date, Locale locale) {
    return DateFormat.yMMMMd(toLocaleTag(locale)).format(date);
  }

  static String formatTime(DateTime date, Locale locale) {
    final tag = toLocaleTag(locale);
    return isJapanese(locale)
        ? DateFormat.Hm(tag).format(date)
        : DateFormat.jm(tag).format(date);
  }

  static String locationLine(String? location, Locale locale) {
    if (location == null || location.trim().isEmpty) {
      return '';
    }
    return isJapanese(locale) ? '場所: $location\n' : 'Location: $location\n';
  }

  static String analysisFailureMessage(Locale locale) =>
      isJapanese(locale) ? '画像分析に失敗しました' : 'Image analysis failed';
}
