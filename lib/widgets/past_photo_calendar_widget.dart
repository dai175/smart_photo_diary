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
import '../localization/localization_extensions.dart';

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
      final photoService = ServiceRegistration.get<IPhotoService>();

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

      // 月単位で写真を取得
      final photos = await photoService.getPhotosInDateRange(
        startDate: startOfMonth,
        endDate: adjustedEnd.add(const Duration(days: 1)),
        limit: 1000, // 月単位の写真数上限
      );

      // 日付別に写真数をカウント
      final counts = <DateTime, int>{};
      for (final photo in photos) {
        final date = DateTime(
          photo.createDateTime.year,
          photo.createDateTime.month,
          photo.createDateTime.day,
        );
        counts[date] = (counts[date] ?? 0) + 1;
      }

      setState(() {
        _photoCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '写真カウント読み込み');
      loggingService.warning(
        '写真数の読み込みに失敗しましたが、機能は継続します',
        context: 'PastPhotoCalendarWidget._loadPhotoCountsForMonth',
        data: appError.toString(),
      );

      setState(() {
        _photoCounts = {};
        _isLoading = false;
      });
    }
  }

  /// 特定日の写真を読み込み
  Future<void> _loadPhotosForDate(DateTime date) async {
    try {
      final photoService = ServiceRegistration.get<IPhotoService>();

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
        limit: 200, // 1日あたりの写真数上限
      );

      // 写真をキャッシュ
      _photosByDate[startOfDay] = photos;

      // 選択された写真を親に通知
      widget.onPhotosSelected(photos);
    } catch (e) {
      final loggingService = await LoggingService.getInstance();
      final appError = ErrorHandler.handleError(e, context: '日付別写真読み込み');
      loggingService.error(
        '選択日の写真読み込みエラー',
        context: 'PastPhotoCalendarWidget._loadPhotosForDate',
        error: appError,
      );

      // エラー時は空のリストを通知
      widget.onPhotosSelected([]);
    }
  }

  /// 日付がアクセス可能かチェック
  bool _isDateAccessible(DateTime date) {
    // 今日以降はアクセス不可
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!date.isBefore(today)) {
      return false;
    }

    // アクセス可能日が設定されていない場合は全てアクセス可能
    if (widget.accessibleDate == null) {
      return true;
    }

    // 正規化された日付で比較
    final checkDate = DateTime(date.year, date.month, date.day);
    if (checkDate.isBefore(widget.accessibleDate!)) {
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
      final diaryService = await ServiceRegistration.getAsync<IDiaryService>();
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
    final l10n = context.l10n;
    return Column(
      children: [
        // カレンダー（固定高さで上部位置を完全固定）
        SizedBox(
          height: 380, // 6週間分の適切な高さに調整
          child: SlideInWidget(
            child: CustomCard(
              child: TableCalendar(
                firstDay:
                    widget.accessibleDate ??
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().subtract(const Duration(days: 1)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                sixWeekMonthsEnforced: true, // 常に6週間表示で高さを統一
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onHeaderTapped: (focusedDay) {
                  // ヘッダータップで当月（昨日）に遷移
                  final now = DateTime.now();
                  final yesterday = DateTime(now.year, now.month, now.day - 1);

                  // 現在表示中の月と異なる場合のみ遷移
                  if (focusedDay.year != yesterday.year ||
                      focusedDay.month != yesterday.month) {
                    setState(() {
                      _focusedDay = yesterday;
                      _selectedDay = null; // 選択をクリア
                    });
                    _loadPhotoCountsForMonth(yesterday);
                  }
                },
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

                    final hasPhoto = photoCount > 0;
                    final hasPhotoAndAccessible = hasPhoto && isAccessible;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
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
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                          fontWeight: hasDiary && hasPhotoAndAccessible
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                  disabledBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.normal,
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
                  outsideBuilder: (context, day, focusedDay) {
                    final hasPhoto = _getPhotoCount(day) > 0;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasPhoto
                            ? Theme.of(
                                context,
                              ).colorScheme.secondary.withValues(alpha: 0.3)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: hasPhoto
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
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
                rowHeight: 42,
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
                    Icons.calendar_today_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.pastPhotoSelectedDateLabel(
                        l10n.formatFullDate(_selectedDay!),
                      ),
                      style: AppTypography.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    l10n.pastPhotoSelectedCount(_getPhotoCount(_selectedDay!)),
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
