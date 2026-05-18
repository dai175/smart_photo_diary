import 'package:flutter/material.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';

class FilterSelectionChip extends StatelessWidget {
  const FilterSelectionChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static Color unselectedBg(bool isDark) =>
      isDark ? AppColors.surfaceContainerHighestDark : AppColors.glyphBg;

  static Color unselectedBorder(bool isDark) =>
      isDark ? AppColors.outlineDark : AppColors.divider;

  static Color unselectedText(bool isDark) =>
      isDark ? AppColors.onSurfaceVariantDark : AppColors.muted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isSelected ? AppColors.accentMuted : unselectedBg(isDark);
    final chipBorder = isSelected
        ? Colors.transparent
        : unselectedBorder(isDark);
    final textColor = isSelected ? Colors.white : unselectedText(isDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: chipBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 13, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTypography.cardBody.copyWith(
                color: textColor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
