import 'package:flutter/material.dart';
import '../models/diary_filter.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../constants/app_constants.dart';
import '../ui/components/animated_button.dart';
import '../localization/localization_extensions.dart';

class FilterBottomSheet extends StatefulWidget {
  final DiaryFilter initialFilter;
  final Function(DiaryFilter) onApply;
  final IDiaryService? diaryService; // テスト用のオプショナル依存性注入

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
    this.diaryService, // テスト時に外部からDiaryServiceを注入可能
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late final LoggingService _logger;
  late DiaryFilter _currentFilter;
  List<String> _availableTags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<LoggingService>();
    _currentFilter = widget.initialFilter;
    _loadAvailableTags();
  }

  Future<void> _loadAvailableTags() async {
    try {
      // テスト時は注入されたサービスを使用、本番時はServiceLocator経由
      final diaryService =
          widget.diaryService ??
          await ServiceLocator().getAsync<IDiaryService>();
      final popularTags = await diaryService.getPopularTags(limit: 20);
      setState(() {
        _availableTags = popularTags;
        _isLoadingTags = false;
      });
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
            duration: Duration(seconds: 2),
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

  void _toggleTimeOfDay(String time) {
    final newTimeOfDay = Set<String>.from(_currentFilter.timeOfDay);
    if (newTimeOfDay.contains(time)) {
      newTimeOfDay.remove(time);
    } else {
      newTimeOfDay.add(time);
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
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ヘッダー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _availableTags.isEmpty
                      ? Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            context.l10n.filterNoTags,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
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
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          {
                            'key': '朝',
                            'label': context.l10n.filterTimeSlotMorning,
                          },
                          {
                            'key': '昼',
                            'label': context.l10n.filterTimeSlotNoon,
                          },
                          {
                            'key': '夕方',
                            'label': context.l10n.filterTimeSlotEvening,
                          },
                          {
                            'key': '夜',
                            'label': context.l10n.filterTimeSlotNight,
                          },
                        ].map((timeSlot) {
                          final timeKey = timeSlot['key'] as String;
                          final timeLabel = timeSlot['label'] as String;
                          final isSelected = _currentFilter.timeOfDay.contains(
                            timeKey,
                          );
                          return FilterChip(
                            label: Text(timeLabel),
                            selected: isSelected,
                            onSelected: (_) => _toggleTimeOfDay(timeKey),
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
            padding: const EdgeInsets.all(20),
            child: PrimaryButton(
              onPressed: () {
                widget.onApply(_currentFilter);
                Navigator.pop(context);
              },
              width: double.infinity,
              text: _currentFilter.isActive
                  ? context.l10n.filterApplyWithCount(
                      _currentFilter.activeFilterCount,
                    )
                  : context.l10n.filterApply,
              icon: Icons.filter_list,
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}
