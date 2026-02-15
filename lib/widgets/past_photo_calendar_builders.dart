import 'package:flutter/material.dart';

/// 過去の写真カレンダーの日付セルビルダー集
///
/// [PastPhotoCalendarWidget] の calendarBuilders で使用する
/// 各種日付セルの描画ロジックを提供する。
class PastPhotoCalendarBuilders {
  PastPhotoCalendarBuilders._();

  static const _cellMargin = EdgeInsets.all(4);
  static const _cellBorderRadius = BorderRadius.all(Radius.circular(8));

  /// デフォルトの日付セル
  ///
  /// 写真の有無・アクセス可否・日記の有無に応じて表示を変える。
  static Widget buildDefaultDay(
    BuildContext context,
    DateTime day,
    DateTime focusedDay, {
    required bool isAccessible,
    required int photoCount,
    required bool hasDiary,
  }) {
    final hasPhoto = photoCount > 0;
    final hasPhotoAndAccessible = hasPhoto && isAccessible;

    return Container(
      margin: _cellMargin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: _cellBorderRadius,
        border: hasDiary && hasPhotoAndAccessible
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.4),
                width: 2,
              )
            : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: hasPhotoAndAccessible
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          fontWeight: hasDiary && hasPhotoAndAccessible
              ? FontWeight.w600
              : FontWeight.normal,
        ),
      ),
    );
  }

  /// 無効化された日付セル（範囲外の日付）
  static Widget buildDisabledDay(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: _cellMargin,
      alignment: Alignment.center,
      decoration: const BoxDecoration(borderRadius: _cellBorderRadius),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  /// 選択された日付セル
  static Widget buildSelectedDay(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
  ) {
    return Container(
      margin: _cellMargin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: _cellBorderRadius,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
