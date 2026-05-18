import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../ui/component_constants.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// カレンダーの凡例セクション（エントリ・複数・本日・選択）
class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          _buildItem(
            _buildCircle(color: AppColors.calEntryBg),
            l10n.statisticsCalendarLegendEntry,
          ),
          _buildItem(_buildBadge(), l10n.statisticsCalendarLegendMultiple),
          _buildItem(_buildRing(), l10n.statisticsCalendarLegendToday),
          _buildItem(
            _buildCircle(color: AppColors.calSelected),
            l10n.statisticsCalendarLegendSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Widget indicator, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: AppTypography.sectionLabel.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _buildCircle({required Color color, Widget? child}) {
    return Container(
      width: CalendarMarkerConstants.legendIndicatorSize,
      height: CalendarMarkerConstants.legendIndicatorSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child,
    );
  }

  Widget _buildBadge() {
    return _buildCircle(
      color: AppColors.calCountBg,
      child: const Center(
        child: Text(
          '2',
          style: TextStyle(
            color: AppColors.calCountFg,
            fontSize: 6,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildRing() {
    return Container(
      width: CalendarMarkerConstants.legendIndicatorSize,
      height: CalendarMarkerConstants.legendIndicatorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.calToday,
          width: CalendarMarkerConstants.todayBorderWidth,
        ),
      ),
    );
  }
}
