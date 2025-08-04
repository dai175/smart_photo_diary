import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/plans/plan.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../core/service_registration.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../services/logging_service.dart';
import '../core/errors/error_handler.dart';

/// 過去の写真カレンダーウィジェット
class PastPhotoCalendarWidget extends StatefulWidget {
  final Plan? currentPlan;
  final DateTime? accessibleDate;
  final Function(List<AssetEntity>) onPhotosSelected;
  final Set<String> usedPhotoIds;
  final Function()? onSelectionCleared;

  const PastPhotoCalendarWidget({
    super.key,
    required this.currentPlan,
    required this.accessibleDate,
    required this.onPhotosSelected,
    required this.usedPhotoIds,
    this.onSelectionCleared,
  });

  @override
  State<PastPhotoCalendarWidget> createState() =>
      _PastPhotoCalendarWidgetState();
}

class _PastPhotoCalendarWidgetState extends State<PastPhotoCalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Map<DateTime, List<AssetEntity>> _photosByDate = {};
  bool _isLoading = false;

  // カレンダーに表示する写真の存在情報
  Map<DateTime, int> _photoCounts = {};

  // 日記が存在する日付
  Set<DateTime> _diaryDates = {};

  /// 選択状態をクリアする
  void clearSelection() {
    setState(() {
      _selectedDay = null;
    });
    // クリアコールバックを呼び出し
    widget.onSelectionCleared?.call();
  }

  @override
  void initState() {
    super.initState();
    // focusedDayを昨日に設定（今日は除外されるため）
    final now = DateTime.now();
    _focusedDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
    _loadPhotoCountsForMonth(_focusedDay);
    _loadDiaryDates();
  }

  @override
  void dispose() {
    // ウィジェット破棄時にメモリクリーンアップ
    _photosByDate.clear();
    _photoCounts.clear();
    _diaryDates.clear();
    super.dispose();
  }

  /// 指定月の写真数を取得
  Future<void> _loadPhotoCountsForMonth(DateTime month) async {
    setState(() => _isLoading = true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();

      // 月の開始と終了を計算
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // 今日の日付を取得（今日は除外）
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 終了日を調整（今日以降は取得しない）
      final adjustedEnd = endOfMonth.isAfter(today)
          ? today.subtract(const Duration(days: 1))
          : endOfMonth;

      if (adjustedEnd.isBefore(startOfMonth)) {
        setState(() {
          _photoCounts.clear();
          _isLoading = false;
        });
        return;
      }

      // 写真を取得
      final photos = await photoService.getPhotosInDateRange(
        startDate: startOfMonth,
        endDate: adjustedEnd.add(const Duration(days: 1)),
        limit: 1000, // 月単位の写真数上限
      );

      // 日付ごとにグループ化して件数を計算
      // タイムゾーン対応: ローカルタイムゾーンで日付を正規化
      final counts = <DateTime, int>{};
      for (final photo in photos) {
        final photoDate = photo.createDateTime;
        // ローカルタイムゾーンで日付を正規化（時刻情報を削除）
        final date = DateTime(photoDate.year, photoDate.month, photoDate.day);
        counts[date] = (counts[date] ?? 0) + 1;
      }

      setState(() {
        _photoCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '写真数読み込み');
      loggingService.error(
        '月単位の写真数読み込みエラー',
        context: 'PastPhotoCalendarWidget._loadPhotoCountsForMonth',
        error: appError,
      );
      setState(() => _isLoading = false);
    }
  }

  /// 選択された日付の写真を取得
  Future<void> _loadPhotosForDate(DateTime date) async {
    setState(() => _isLoading = true);

    try {
      final photoService = ServiceRegistration.get<PhotoServiceInterface>();

      // タイムゾーン対応: 選択日の開始と終了時刻（ローカルタイムゾーン）
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(
        date.year,
        date.month,
        date.day,
        23,
        59,
        59,
        999,
      );

      final photos = await photoService.getPhotosInDateRange(
        startDate: startOfDay,
        endDate: endOfDay,
        limit: 100,
      );

      setState(() {
        _photosByDate[date] = photos;
        _isLoading = false;
      });

      // 写真選択コールバックを呼び出し
      if (photos.isNotEmpty) {
        widget.onPhotosSelected(photos);
      }
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '日付別写真読み込み');
      loggingService.error(
        '選択日付の写真読み込みエラー',
        context: 'PastPhotoCalendarWidget._loadPhotosForDate',
        error: appError,
      );
      setState(() => _isLoading = false);
    }
  }

  /// 日付がアクセス可能かチェック
  bool _isDateAccessible(DateTime date) {
    if (widget.currentPlan == null || widget.accessibleDate == null) {
      return false;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);

    // 今日以降はアクセス不可
    if (!checkDate.isBefore(today)) {
      return false;
    }

    // アクセス可能日以降かチェック
    return !checkDate.isBefore(widget.accessibleDate!);
  }

  /// 日付に写真があるかチェック
  int _getPhotoCount(DateTime date) {
    // タイムゾーン対応: ローカルタイムゾーンで日付を正規化
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _photoCounts[normalizedDate] ?? 0;
  }

  /// 日付に日記が存在するかチェック
  bool _hasDiary(DateTime date) {
    // タイムゾーン対応: ローカルタイムゾーンで日付を正規化
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _diaryDates.contains(normalizedDate);
  }

  /// 日記が存在する日付を読み込み
  Future<void> _loadDiaryDates() async {
    try {
      final diaryService =
          await ServiceRegistration.getAsync<DiaryServiceInterface>();
      final diaries = await diaryService.getSortedDiaryEntries();

      final dates = <DateTime>{};
      for (final diary in diaries) {
        final date = DateTime(
          diary.date.year,
          diary.date.month,
          diary.date.day,
        );
        dates.add(date);
      }

      setState(() {
        _diaryDates = dates;
      });
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '日記日付読み込み');
      loggingService.warning(
        '日記日付の読み込みに失敗しましたが、機能は継続します',
        context: 'PastPhotoCalendarWidget._loadDiaryDates',
        data: appError.toString(),
      );
      // エラーでも機能を継続
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // カレンダー
        SlideInWidget(
          child: CustomCard(
            child: TableCalendar(
              firstDay:
                  widget.accessibleDate ??
                  DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().subtract(const Duration(days: 1)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                final isAccessible = _isDateAccessible(selectedDay);
                final photoCount = _getPhotoCount(selectedDay);

                // アクセス可能で写真がある場合のみ選択可能
                if (!isAccessible || photoCount == 0) {
                  // 何もしない（選択不可）
                  return;
                }

                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                // 選択日の写真を読み込み
                _loadPhotosForDate(selectedDay);
              },
              onPageChanged: (focusedDay) {
                // focusedDayが今日以降の場合は昨日に調整
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final yesterday = today.subtract(const Duration(days: 1));

                if (focusedDay.isAfter(yesterday)) {
                  _focusedDay = yesterday;
                } else {
                  _focusedDay = focusedDay;
                }
                _loadPhotoCountsForMonth(_focusedDay);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final isAccessible = _isDateAccessible(day);
                  final photoCount = _getPhotoCount(day);
                  final hasDiary = _hasDiary(day);
                  final hasPhotoAndAccessible = photoCount > 0 && isAccessible;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasPhotoAndAccessible
                          ? null
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: hasDiary && isAccessible
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
                            ? hasDiary
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface
                            : Colors.grey.withValues(alpha: 0.4),
                        fontWeight: hasDiary && hasPhotoAndAccessible
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  final photoCount = _getPhotoCount(day);
                  final hasPhoto = photoCount > 0;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasPhoto
                          ? Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: hasPhoto
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.grey.withValues(alpha: 0.4),
                        fontWeight: hasPhoto
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                holidayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                cellMargin: const EdgeInsets.all(2),
                cellPadding: const EdgeInsets.all(0),
              ),
              rowHeight: 48,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: AppTypography.titleLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // ローディング表示
        if (_isLoading)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),

        // 選択された日付の情報
        if (_selectedDay != null && !_isLoading)
          SlideInWidget(
            delay: const Duration(milliseconds: 200),
            child: Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: AppSpacing.cardRadius,
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '${_selectedDay!.year}年${_selectedDay!.month}月${_selectedDay!.day}日の写真を選択中',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${_getPhotoCount(_selectedDay!)}枚',
                    style: AppTypography.labelLarge.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
