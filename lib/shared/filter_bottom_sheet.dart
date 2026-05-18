import 'package:flutter/material.dart';
import '../models/diary_filter.dart';
import '../services/interfaces/diary_tag_service_interface.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../constants/app_constants.dart';
import '../ui/component_constants.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/drag_handle.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../localization/localization_extensions.dart';
import 'filter_date_section.dart';
import 'filter_tag_section.dart';
import 'filter_time_of_day_section.dart';

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
          'Failed to load available tags',
          error: result.error,
          context: 'FilterBottomSheet',
        );
      }
    } catch (e) {
      setState(() => _isLoadingTags = false);
      _logger.error(
        'Failed to load available tags',
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
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Center(child: DragHandle()),
          ),

          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.navigationDiary.toUpperCase(),
                        style: AppTypography.sectionLabel.copyWith(
                          color: AppColors.accentMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.filterTitle,
                        style: AppTypography.detailTitle.copyWith(fontSize: 24),
                      ),
                    ],
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
          const Divider(
            height: 1,
            thickness: 0.5,
            indent: 20,
            endIndent: 20,
            color: AppColors.divider,
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _buildSection(
                  title: l10n.filterDateRange,
                  child: FilterDateSection(
                    startDate: _currentFilter.dateRange?.start,
                    endDate: _currentFilter.dateRange?.end,
                    onStartDateTap: () => _selectSingleDate(true),
                    onEndDateTap: () => _selectSingleDate(false),
                    onClear: _clearDateRange,
                  ),
                ),

                _buildSection(
                  title: l10n.filterTags,
                  child: FilterTagSection(
                    availableTags: _availableTags,
                    selectedTags: _currentFilter.selectedTags,
                    isLoading: _isLoadingTags,
                    onTagToggled: _toggleTag,
                  ),
                ),

                _buildSection(
                  title: l10n.filterTimeOfDay,
                  child: FilterTimeOfDaySection(
                    selectedPeriods: _currentFilter.timeOfDay,
                    onPeriodToggled: _toggleTimeOfDay,
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),

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
