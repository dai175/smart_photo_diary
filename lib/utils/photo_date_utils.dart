import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';

/// 写真の日付管理に関するユーティリティクラス
class PhotoDateUtils {
  /// 写真を日付別にグループ化
  static Map<DateTime, List<AssetEntity>> groupPhotosByDate(
    List<AssetEntity> photos,
  ) {
    final grouped = <DateTime, List<AssetEntity>>{};

    for (final photo in photos) {
      final date = photo.createDateTime;
      final dateKey = DateTime(date.year, date.month, date.day);

      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(photo);
    }

    // 各日付の写真を時間順にソート
    grouped.forEach((date, photos) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    });

    return grouped;
  }

  /// 写真を月別にグループ化
  static Map<DateTime, List<AssetEntity>> groupPhotosByMonth(
    List<AssetEntity> photos,
  ) {
    final grouped = <DateTime, List<AssetEntity>>{};

    for (final photo in photos) {
      final date = photo.createDateTime;
      final monthKey = DateTime(date.year, date.month);

      grouped.putIfAbsent(monthKey, () => []);
      grouped[monthKey]!.add(photo);
    }

    // 各月の写真を日付順にソート
    grouped.forEach((month, photos) {
      photos.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
    });

    return grouped;
  }

  /// 日付のリストを取得（新しい順）
  static List<DateTime> getSortedDateKeys(
    Map<DateTime, List<AssetEntity>> groupedPhotos,
  ) {
    final keys = groupedPhotos.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  /// 月のリストを取得（新しい順）
  static List<DateTime> getSortedMonthKeys(
    Map<DateTime, List<AssetEntity>> groupedPhotos,
  ) {
    final keys = groupedPhotos.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  /// 同じ日付かどうかをチェック
  static bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 同じ月かどうかをチェック
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// 日付を月の開始日に正規化
  static DateTime normalizeToMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  /// 日付を日の開始時刻に正規化
  static DateTime normalizeToDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 日付範囲内の写真をフィルタリング
  static List<AssetEntity> filterPhotosByDateRange(
    List<AssetEntity> photos,
    DateTime startDate,
    DateTime endDate,
  ) {
    final normalizedStart = normalizeToDay(startDate);
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    return photos.where((photo) {
      final photoDate = photo.createDateTime;
      return photoDate.isAfter(normalizedStart) &&
          photoDate.isBefore(normalizedEnd);
    }).toList();
  }

  /// 月の最初と最後の日を取得
  static (DateTime, DateTime) getMonthBounds(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    return (firstDay, lastDay);
  }

  /// 日付を読みやすい形式でフォーマット
  static String formatDateForDisplay(DateTime date, {String? locale}) {
    final resolvedLocale = locale ?? Intl.getCurrentLocale();
    return DateFormat.yMMMMd(resolvedLocale).format(date);
  }

  /// 月を読みやすい形式でフォーマット
  static String formatMonthForDisplay(DateTime month, {String? locale}) {
    final resolvedLocale = locale ?? Intl.getCurrentLocale();
    return DateFormat.yMMMM(resolvedLocale).format(month);
  }

  /// 相対的な日付表現を取得
  static String getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = normalizeToDay(now);
    final targetDate = normalizeToDay(date);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '昨日';
    } else if (difference == 2) {
      return '一昨日';
    } else if (difference <= 7) {
      return '$difference日前';
    } else if (difference <= 30) {
      final weeks = (difference / 7).floor();
      return '$weeks週間前';
    } else if (difference <= 365) {
      final months = (difference / 30).floor();
      return '$monthsヶ月前';
    } else {
      final years = (difference / 365).floor();
      return '$years年前';
    }
  }
}
