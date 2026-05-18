import 'package:flutter/material.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../localization/localization_extensions.dart';
import 'filter_selection_chip.dart';

class FilterDateSection extends StatelessWidget {
  const FilterDateSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  /// 開始・終了両日付をクリアする（片方のみのクリアは現行仕様にない）
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DatePill(
            label: context.l10n.filterSelectStartDate,
            date: startDate,
            onTap: onStartDateTap,
            onClear: onClear,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _DatePill(
            label: context.l10n.filterSelectEndDate,
            date: endDate,
            onTap: onEndDateTap,
            onClear: onClear,
          ),
        ),
      ],
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = hasDate
        ? AppColors.selectedBg
        : FilterSelectionChip.unselectedBg(isDark);
    final borderColor = hasDate
        ? AppColors.accentMuted
        : FilterSelectionChip.unselectedBorder(isDark);
    final dateTextColor = hasDate
        ? (isDark ? AppColors.onSurfaceVariantDark : AppColors.accentMuted)
        : FilterSelectionChip.unselectedText(isDark);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
                      color: isDark
                          ? AppColors.onSurfaceVariantDark
                          : AppColors.accentMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDate ? context.l10n.formatMonthDay(date!) : '--',
                    style: AppTypography.bodyMedium.copyWith(
                      color: dateTextColor,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
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
}
