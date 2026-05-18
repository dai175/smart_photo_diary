import 'package:flutter/material.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../localization/localization_extensions.dart';
import 'filter_selection_chip.dart';

class FilterTagSection extends StatelessWidget {
  const FilterTagSection({
    super.key,
    required this.availableTags,
    required this.selectedTags,
    required this.isLoading,
    required this.onTagToggled,
  });

  final List<String> availableTags;
  final Set<String> selectedTags;
  final bool isLoading;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (availableTags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          context.l10n.filterNoTags,
          style: AppTypography.cardBody.copyWith(color: AppColors.muted),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: availableTags.map((tag) {
        return FilterSelectionChip(
          key: ValueKey(tag),
          label: '#$tag',
          isSelected: selectedTags.contains(tag),
          onTap: () => onTagToggled(tag),
        );
      }).toList(),
    );
  }
}
