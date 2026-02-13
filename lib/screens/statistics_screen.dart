import 'package:flutter/material.dart';
import '../controllers/statistics_controller.dart';
import 'diary_detail_screen.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../localization/localization_extensions.dart';
import 'statistics/statistics_cards.dart';
import 'statistics/statistics_calendar.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final StatisticsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StatisticsController();
    _controller.loadStatistics();
    _controller.subscribeDiaryChanges();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
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
          body: _controller.isLoading
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
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                            ),
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
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : MicroInteractions.pullToRefresh(
                  onRefresh: _controller.loadStatistics,
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
                            totalEntries: _controller.stats.totalEntries,
                            currentStreak: _controller.stats.currentStreak,
                            longestStreak: _controller.stats.longestStreak,
                            monthlyCount: _controller.stats.monthlyCount,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // カレンダーセクション
                        SlideInWidget(
                          delay: const Duration(milliseconds: 200),
                          child: StatisticsCalendar(
                            diaryMap: _controller.stats.diaryMap,
                            focusedDay: _controller.focusedDay,
                            selectedDay: _controller.selectedDay,
                            onDaySelected: _onDaySelected,
                            onPageChanged: _controller.onPageChanged,
                            onHeaderTapped: _onHeaderTapped,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final diaries = _controller.onDaySelected(selectedDay, focusedDay);
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

  void _onHeaderTapped(DateTime focusedDay) {
    _controller.onHeaderTapped(focusedDay);
  }
}
