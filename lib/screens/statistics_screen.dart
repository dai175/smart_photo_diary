import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../models/diary_entry.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../models/diary_change.dart';
import 'dart:async';
import '../localization/localization_extensions.dart';
import 'statistics/statistics_calculator.dart';
import 'statistics/statistics_cards.dart';
import 'statistics/statistics_calendar.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final ILoggingService _logger;
  late IDiaryService _diaryService;
  List<DiaryEntry> _allDiaries = [];
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  StreamSubscription<DiaryChange>? _diarySub;
  Timer? _debounce;

  // 統計データ
  StatisticsData _stats = const StatisticsData(
    totalEntries: 0,
    currentStreak: 0,
    longestStreak: 0,
    monthlyCount: 0,
    diaryMap: {},
  );

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _loadStatistics();
    _subscribeDiaryChanges();
  }

  void _subscribeDiaryChanges() async {
    try {
      _diaryService = await ServiceLocator().getAsync<IDiaryService>();
      _diarySub = _diaryService.changes.listen((_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          _loadStatistics();
        });
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _diarySub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _diaryService = await ServiceLocator().getAsync<IDiaryService>();
      final result = await _diaryService.getSortedDiaryEntries();

      if (result.isSuccess) {
        _allDiaries = result.value;
        _stats = StatisticsCalculator.calculate(_allDiaries);
        setState(() {
          _isLoading = false;
        });
      } else {
        _logger.error(
          '統計データの読み込みエラー',
          error: result.error,
          context: 'StatisticsScreen',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.error(
        '統計データの読み込み中に予期しないエラー',
        error: e,
        context: 'StatisticsScreen',
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.navigationStatistics),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        elevation: 2,
      ),
      body: _isLoading
          ? Center(
              child: FadeInWidget(
                child: CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: AppSpacing.cardPadding,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.3,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        l10n.statisticsLoadingTitle,
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.statisticsLoadingSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : MicroInteractions.pullToRefresh(
              onRefresh: _loadStatistics,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 統計カード群
                    FadeInWidget(
                      child: StatisticsCards(
                        totalEntries: _stats.totalEntries,
                        currentStreak: _stats.currentStreak,
                        longestStreak: _stats.longestStreak,
                        monthlyCount: _stats.monthlyCount,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // カレンダーセクション
                    SlideInWidget(
                      delay: const Duration(milliseconds: 200),
                      child: StatisticsCalendar(
                        diaryMap: _stats.diaryMap,
                        focusedDay: _focusedDay,
                        selectedDay: _selectedDay,
                        onDaySelected: _onDaySelected,
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        onHeaderTapped: _onHeaderTapped,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      final diaries =
          _stats.diaryMap[DateTime(
            selectedDay.year,
            selectedDay.month,
            selectedDay.day,
          )];
      if (diaries != null && diaries.isNotEmpty) {
        if (diaries.length == 1) {
          Navigator.push(
            context,
            DiaryDetailScreen(diaryId: diaries.first.id).customRoute(),
          );
        } else {
          StatisticsCalendar.showDiarySelectionDialog(
            context,
            diaries,
            selectedDay,
          );
        }
      }
    }
  }

  void _onHeaderTapped(DateTime focusedDay) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, now.day);
    if (focusedDay.year != currentMonth.year ||
        focusedDay.month != currentMonth.month) {
      setState(() {
        _focusedDay = currentMonth;
        _selectedDay = null;
      });
    }
  }
}
