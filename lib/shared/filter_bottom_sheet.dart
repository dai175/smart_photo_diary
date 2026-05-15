import 'package:flutter/material.dart';
import '../models/diary_filter.dart';
import '../services/interfaces/diary_tag_service_interface.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../constants/app_constants.dart';
import '../ui/component_constants.dart';
import '../ui/components/animated_button.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../localization/localization_extensions.dart';

class FilterBottomSheet extends StatefulWidget {
  final DiaryFilter initialFilter;
  final Function(DiaryFilter) onApply;
  final IDiaryTagService? tagService;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.tagService,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final ILoggingService _logger;
  late DiaryFilter _currentFilter;
  List<String> _availableTags = [];
  bool _isLoadingTags = true;

  int get _activeFilterCount {
    int count = 0;
    if (_currentFilter.dateRange != null) count++;
    if (_currentFilter.selectedTags.isNotEmpty) count++;
    if (_currentFilter.timeOfDay.isNotEmpty) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _currentFilter = widget.initialFilter;
    _loadAvailableTags();
  }

  Future<void> _loadAvailableTags() async {
    try {
      final tagService =
          widget.tagService ??
          await serviceLocator.getAsync<IDiaryTagService>();
      final result = await tagService.getPopularTags(limit: 20);
      if (!mounted) return;
      if (result.isSuccess) {
        setState(() {
          _availableTags = result.value;
          _isLoadingTags = false;
        });
      } else {
        setState(() => _isLoadingTags = false);
        _logger.error(
          context.l10n.filterTagLoadError,
          error: result.error,
          context: 'FilterBottomSheet',
        );
      }
    } catch (e) {
      setState(() => _isLoadingTags = false);
      _logger.error(
        context.l10n.filterTagLoadError,
        error: e,
        context: 'FilterBottomSheet',
      );
    }
  }

  Future<void> _selectSingleDate(bool isStart) async {
    try {
      final currentStart = _currentFilter.dateRange?.start;
      final currentEnd = _currentFilter.dateRange?.end;

      if (isStart) {
        final date = await showDatePicker(
          context: context,
          initialDate:
              currentStart ?? DateTime.now().subtract(const Duration(days: 7)),
          firstDate: DateTime(2020),
          lastDate: currentEnd ?? DateTime.now(),
          helpText: context.l10n.filterSelectStartDate,
          cancelText: context.l10n.commonCancel,
          confirmText: context.l10n.commonSelect,
        );
        if (date != null && mounted) {
          setState(() {
            _currentFilter = _currentFilter.copyWith(
              dateRange: DateTimeRange(start: date, end: currentEnd ?? date),
            );
          });
        }
      } else {
        final date = await showDatePicker(
          context: context,
          initialDate: currentEnd ?? DateTime.now(),
          firstDate: currentStart ?? DateTime(2020),
          lastDate: DateTime.now(),
          helpText: context.l10n.filterSelectEndDate,
          cancelText: context.l10n.commonCancel,
          confirmText: context.l10n.commonSelect,
        );
        if (date != null && mounted) {
          setState(() {
            _currentFilter = _currentFilter.copyWith(
              dateRange: DateTimeRange(start: currentStart ?? date, end: date),
            );
          });
        }
      }
    } catch (e) {
      _logger.error(
        'Date selection error',
        error: e,
        context: 'FilterBottomSheet',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.filterDateSelectionError),
            duration: AppConstants.snackBarInfoDuration,
          ),
        );
      }
    }
  }

  void _clearDateRange() {
    setState(() {
      _currentFilter = _currentFilter.copyWith(clearDateRange: true);
    });
  }

  void _toggleTag(String tag) {
    final newTags = Set<String>.from(_currentFilter.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    setState(() {
      _currentFilter = _currentFilter.copyWith(selectedTags: newTags);
    });
  }

  void _toggleTimeOfDay(TimeOfDayPeriod period) {
    final newTimeOfDay = Set<TimeOfDayPeriod>.from(_currentFilter.timeOfDay);
    if (newTimeOfDay.contains(period)) {
      newTimeOfDay.remove(period);
    } else {
      newTimeOfDay.add(period);
    }
    setState(() {
      _currentFilter = _currentFilter.copyWith(timeOfDay: newTimeOfDay);
    });
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilter = DiaryFilter.empty;
    });
  }

  List<MapEntry<TimeOfDayPeriod, String>> _timeOfDayEntries(
    BuildContext context,
  ) {
    final l10n = context.l10n;
    return [
      MapEntry(TimeOfDayPeriod.morning, '🌅 ${l10n.filterTimeSlotMorning}'),
      MapEntry(TimeOfDayPeriod.noon, '☀️ ${l10n.filterTimeSlotNoon}'),
      MapEntry(TimeOfDayPeriod.evening, '🌆 ${l10n.filterTimeSlotEvening}'),
      MapEntry(TimeOfDayPeriod.night, '🌙 ${l10n.filterTimeSlotNight}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height:
          MediaQuery.of(context).size.height *
          AppConstants.bottomSheetHeightRatio,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BottomSheetConstants.radius),
        ),
      ),
      child: Column(
        children: [
          // ドラッグハンドル
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.handle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.filterTitle,
                    style: AppTypography.detailTitle,
                  ),
                ),
                TextOnlyButton(
                  onPressed: _clearAllFilters,
                  text: l10n.filterClearAll,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // フィルタオプション
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                // 日付範囲
                _buildSection(
                  title: l10n.filterDateRange,
                  child: _buildDatePillGrid(context),
                ),

                // タグ
                _buildSection(
                  title: l10n.filterTags,
                  child: _isLoadingTags
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _availableTags.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.filterNoTags,
                            style: AppTypography.cardBody.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: _availableTags
                              .map(
                                (tag) => _buildFilterChip(
                                  '#$tag',
                                  _currentFilter.selectedTags.contains(tag),
                                  () => _toggleTag(tag),
                                ),
                              )
                              .toList(),
                        ),
                ),

                // 時間帯
                _buildSection(
                  title: l10n.filterTimeOfDay,
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _timeOfDayEntries(context).map((entry) {
                      final isSelected = _currentFilter.timeOfDay.contains(
                        entry.key,
                      );
                      return _buildFilterChip(
                        entry.value,
                        isSelected,
                        () => _toggleTimeOfDay(entry.key),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // 適用ボタン
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: ButtonConstants.heightMd,
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed: () {
                      widget.onApply(_currentFilter);
                      Navigator.pop(context);
                    },
                    width: double.infinity,
                    text: l10n.filterApply,
                  ),
                ),
                if (_activeFilterCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: AppColors.accentMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_activeFilterCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePillGrid(BuildContext context) {
    final startDate = _currentFilter.dateRange?.start;
    final endDate = _currentFilter.dateRange?.end;
    return Row(
      children: [
        Expanded(
          child: _buildDatePill(
            label: context.l10n.filterSelectStartDate,
            date: startDate,
            isStart: true,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildDatePill(
            label: context.l10n.filterSelectEndDate,
            date: endDate,
            isStart: false,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePill({
    required String label,
    required DateTime? date,
    required bool isStart,
  }) {
    final hasDate = date != null;
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectSingleDate(isStart),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasDate ? AppColors.selectedBg : AppColors.glyphBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasDate ? AppColors.accentMuted : AppColors.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: AppTypography.sectionLabel.copyWith(
                      color: AppColors.accentMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? l10n.formatMonthDay(date) : '--',
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasDate ? AppColors.accentMuted : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: _clearDateRange,
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.quickAnimationDuration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBg : AppColors.glyphBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.accentMuted : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.cardBody.copyWith(
            color: isSelected ? AppColors.accentMuted : AppColors.muted,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
        ),
        child,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
