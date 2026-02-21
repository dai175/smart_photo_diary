import 'package:flutter/material.dart';
import '../models/diary_filter.dart';
import '../services/interfaces/diary_tag_service_interface.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../constants/app_constants.dart';
import '../constants/theme_constants.dart';
import '../ui/components/animated_button.dart';
import '../ui/design_system/app_spacing.dart';
import '../localization/localization_extensions.dart';

class FilterBottomSheet extends StatefulWidget {
  final DiaryFilter initialFilter;
  final Function(DiaryFilter) onApply;
  final IDiaryTagService? tagService; // テスト用のオプショナル依存性注入

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.tagService, // テスト時に外部からタグサービスを注入可能
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final ILoggingService _logger;
  late DiaryFilter _currentFilter;
  List<String> _availableTags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<ILoggingService>();
    _currentFilter = widget.initialFilter;
    _loadAvailableTags();
  }

  Future<void> _loadAvailableTags() async {
    try {
      // テスト時は注入されたサービスを使用、本番時はServiceLocator経由
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
        setState(() {
          _isLoadingTags = false;
        });
        _logger.error(
          context.l10n.filterTagLoadError,
          error: result.error,
          context: 'FilterBottomSheet',
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      _logger.error(
        context.l10n.filterTagLoadError,
        error: e,
        context: 'FilterBottomSheet',
      );
    }
  }

  void _selectDateRange() async {
    try {
      // まず開始日を選択
      final startDate = await showDatePicker(
        context: context,
        initialDate:
            _currentFilter.dateRange?.start ??
            DateTime.now().subtract(const Duration(days: 7)),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: context.l10n.filterSelectStartDate,
        cancelText: context.l10n.commonCancel,
        confirmText: context.l10n.commonNext,
      );

      if (startDate == null) return;

      // 次に終了日を選択
      if (!mounted) return;
      final endDate = await showDatePicker(
        context: context,
        initialDate: _currentFilter.dateRange?.end ?? DateTime.now(),
        firstDate: startDate,
        lastDate: DateTime.now(),
        helpText: context.l10n.filterSelectEndDate,
        cancelText: context.l10n.commonCancel,
        confirmText: context.l10n.commonSelect,
      );

      if (endDate != null) {
        final dateRange = DateTimeRange(start: startDate, end: endDate);
        setState(() {
          _currentFilter = _currentFilter.copyWith(dateRange: dateRange);
        });
      }
    } catch (e) {
      _logger.error(
        'Date range selection error',
        error: e,
        context: 'FilterBottomSheet',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.filterDateSelectionError),
            duration: const Duration(seconds: 2),
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
    return [
      MapEntry(TimeOfDayPeriod.morning, context.l10n.filterTimeSlotMorning),
      MapEntry(TimeOfDayPeriod.noon, context.l10n.filterTimeSlotNoon),
      MapEntry(TimeOfDayPeriod.evening, context.l10n.filterTimeSlotEvening),
      MapEntry(TimeOfDayPeriod.night, context.l10n.filterTimeSlotNight),
    ];
  }

  String _formatDateRange(DateTimeRange dateRange) {
    final l10n = context.l10n;
    final start = l10n.formatMonthDay(dateRange.start);
    final end = l10n.formatMonthDay(dateRange.end);
    return '$start - $end';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          AppConstants.bottomSheetHeightRatio,
      decoration: const BoxDecoration(borderRadius: AppSpacing.modalRadius),
      child: Column(
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(AppSpacing.xxs),
            ),
          ),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.filterTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextOnlyButton(
                  onPressed: _clearAllFilters,
                  text: context.l10n.filterClearAll,
                ),
              ],
            ),
          ),

          const Divider(),

          // フィルタオプション
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
              ),
              children: [
                // 日付範囲
                _buildSection(
                  title: context.l10n.filterDateRange,
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            _currentFilter.dateRange != null
                                ? _formatDateRange(_currentFilter.dateRange!)
                                : context.l10n.filterSelectPeriod,
                          ),
                          trailing: _currentFilter.dateRange != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _clearDateRange,
                                )
                              : const Icon(Icons.arrow_forward_ios),
                          onTap: _selectDateRange,
                        ),
                      ),
                    ],
                  ),
                ),

                // タグ
                _buildSection(
                  title: context.l10n.filterTags,
                  child: _isLoadingTags
                      ? const Padding(
                          padding: ThemeConstants.defaultCardPadding,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _availableTags.isEmpty
                      ? Padding(
                          padding: ThemeConstants.defaultCardPadding,
                          child: Text(
                            context.l10n.filterNoTags,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: _availableTags.map((tag) {
                            final isSelected = _currentFilter.selectedTags
                                .contains(tag);
                            return FilterChip(
                              label: Text('#$tag'),
                              selected: isSelected,
                              onSelected: (_) => _toggleTag(tag),
                            );
                          }).toList(),
                        ),
                ),

                // 時間帯
                _buildSection(
                  title: context.l10n.filterTimeOfDay,
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _timeOfDayEntries(context).map((entry) {
                      final isSelected = _currentFilter.timeOfDay.contains(
                        entry.key,
                      );
                      return FilterChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (_) => _toggleTimeOfDay(entry.key),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 100), // ボタンのためのスペース
              ],
            ),
          ),

          // 適用ボタン
          Container(
            padding: ThemeConstants.defaultCardPadding,
            child: PrimaryButton(
              onPressed: () {
                widget.onApply(_currentFilter);
                Navigator.pop(context);
              },
              width: double.infinity,
              text: context.l10n.filterApply,
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
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        child,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
