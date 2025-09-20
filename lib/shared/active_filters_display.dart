import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../models/diary_filter.dart';
import '../ui/components/animated_button.dart';
import '../localization/localization_extensions.dart';

class ActiveFiltersDisplay extends StatelessWidget {
  final DiaryFilter filter;
  final VoidCallback onClear;
  final Function(String)? onRemoveTag;
  final Function(String)? onRemoveTimeOfDay;
  final VoidCallback? onRemoveDateRange;
  final VoidCallback? onRemoveSearch;

  const ActiveFiltersDisplay({
    super.key,
    required this.filter,
    required this.onClear,
    this.onRemoveTag,
    this.onRemoveTimeOfDay,
    this.onRemoveDateRange,
    this.onRemoveSearch,
  });

  @override
  Widget build(BuildContext context) {
    if (!filter.isActive) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.filterActiveTitle(filter.activeFilterCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SmallButton(
                onPressed: onClear,
                child: Text(
                  context.l10n.filterActiveClearAll,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 8, runSpacing: 4, children: _buildFilterChips(context)),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final chips = <Widget>[];

    // 日付範囲チップ
    if (filter.dateRange != null) {
      chips.add(
        _buildChip(
          context: context,
          label: context.l10n.filterActiveDateRange,
          icon: Icons.calendar_today,
          onRemove: onRemoveDateRange,
        ),
      );
    }

    // タグチップ
    for (final tag in filter.selectedTags) {
      chips.add(
        _buildChip(
          context: context,
          label: '#$tag',
          icon: Icons.tag,
          onRemove: () => onRemoveTag?.call(tag),
        ),
      );
    }

    // 時間帯チップ
    for (final time in filter.timeOfDay) {
      chips.add(
        _buildChip(
          context: context,
          label: _getLocalizedTimeLabel(context, time),
          icon: _getTimeIcon(time),
          onRemove: () => onRemoveTimeOfDay?.call(time),
        ),
      );
    }

    // 検索チップ
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      chips.add(
        _buildChip(
          context: context,
          label: context.l10n.filterActiveSearch(filter.searchText!),
          icon: Icons.search,
          onRemove: onRemoveSearch,
        ),
      );
    }

    return chips;
  }

  Widget _buildChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    VoidCallback? onRemove,
  }) {
    return Chip(
      avatar: Icon(
        icon,
        size: AppSpacing.iconXs,
        color: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium),
      ),
      label: Text(label, style: AppTypography.labelSmall),
      deleteIcon: Icon(Icons.close, size: AppSpacing.iconXs),
      onDeleted: onRemove,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer
          .withValues(alpha: AppConstants.opacityLow),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getLocalizedTimeLabel(BuildContext context, String timeKey) {
    switch (timeKey) {
      case '朝':
        return context.l10n.filterTimeSlotMorning;
      case '昼':
        return context.l10n.filterTimeSlotNoon;
      case '夕方':
        return context.l10n.filterTimeSlotEvening;
      case '夜':
        return context.l10n.filterTimeSlotNight;
      default:
        return timeKey;
    }
  }

  IconData _getTimeIcon(String time) {
    switch (time) {
      case '朝':
        return Icons.wb_sunny;
      case '昼':
        return Icons.light_mode;
      case '夕方':
        return Icons.wb_twilight;
      case '夜':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }
}
