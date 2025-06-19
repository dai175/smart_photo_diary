import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_filter.dart';
import '../services/diary_service.dart';
import '../constants/app_constants.dart';
import '../ui/components/animated_button.dart';

class FilterBottomSheet extends StatefulWidget {
  final DiaryFilter initialFilter;
  final Function(DiaryFilter) onApply;
  final DiaryService? diaryService; // テスト用のオプショナル依存性注入

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
  late DiaryFilter _currentFilter;
  List<String> _availableTags = [];
  bool _isLoadingTags = true;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _loadAvailableTags();
  }

  Future<void> _loadAvailableTags() async {
    try {
      // テスト時は注入されたサービスを使用、本番時は通常のgetInstance
      final diaryService = widget.diaryService ?? await DiaryService.getInstance();
      final popularTags = await diaryService.getPopularTags(limit: 20);
      setState(() {
        _availableTags = popularTags;
        _isLoadingTags = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingTags = false;
      });
      debugPrint('タグ読み込みエラー: $e');
    }
  }

  void _selectDateRange() async {
    try {
      // まず開始日を選択
      final startDate = await showDatePicker(
        context: context,
        initialDate: _currentFilter.dateRange?.start ?? DateTime.now().subtract(const Duration(days: 7)),
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        helpText: '開始日を選択',
        cancelText: 'キャンセル',
        confirmText: '次へ',
      );

      if (startDate == null) return;

      // 次に終了日を選択
      if (!mounted) return;
      final endDate = await showDatePicker(
        context: context,
        initialDate: _currentFilter.dateRange?.end ?? DateTime.now(),
        firstDate: startDate,
        lastDate: DateTime.now(),
        helpText: '終了日を選択',
        cancelText: 'キャンセル',
        confirmText: '選択',
      );

      if (endDate != null) {
        final dateRange = DateTimeRange(start: startDate, end: endDate);
        setState(() {
          _currentFilter = _currentFilter.copyWith(dateRange: dateRange);
        });
      }
    } catch (e) {
      debugPrint('日付範囲選択エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('日付選択でエラーが発生しました'),
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
    final formatter = DateFormat('M/d');
    return '${formatter.format(dateRange.start)} - ${formatter.format(dateRange.end)}';
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * AppConstants.bottomSheetHeightRatio,
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
                  'フィルタ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextOnlyButton(
                  onPressed: _clearAllFilters,
                  text: 'すべてクリア',
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
                  title: '日付範囲',
                  child: Column(
                    children: [
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(_currentFilter.dateRange != null
                              ? _formatDateRange(_currentFilter.dateRange!)
                              : '期間を選択'),
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
                  title: 'タグ',
                  child: _isLoadingTags
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _availableTags.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'タグがありません',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availableTags.map((tag) {
                                final isSelected = _currentFilter.selectedTags.contains(tag);
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
                  title: '時間帯',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['朝', '昼', '夕方', '夜'].map((time) {
                      final isSelected = _currentFilter.timeOfDay.contains(time);
                      return FilterChip(
                        label: Text(time),
                        selected: isSelected,
                        onSelected: (_) => _toggleTimeOfDay(time),
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
                  ? 'フィルタを適用 (${_currentFilter.activeFilterCount})'
                  : 'フィルタを適用',
              icon: Icons.filter_alt,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        child,
        const SizedBox(height: 16),
      ],
    );
  }
}