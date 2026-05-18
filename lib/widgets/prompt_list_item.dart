import 'package:flutter/material.dart';
import '../localization/localization_extensions.dart';
import '../models/writing_prompt.dart';
import '../ui/components/modern_chip.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../utils/prompt_category_utils.dart';

class PromptListItem extends StatelessWidget {
  const PromptListItem({
    super.key,
    required this.prompt,
    required this.isSelected,
    required this.isPremium,
    required this.onTap,
  });

  final WritingPrompt prompt;
  final bool isSelected;
  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(14);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.selectedBg : Colors.transparent,
        borderRadius: borderRadius,
        border: Border.all(
          color: isSelected ? AppColors.accent : Colors.transparent,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ModernChip.tonedTag(
                      PromptCategoryUtils.getCategoryDisplayName(
                        prompt.category,
                        locale: Localizations.localeOf(context),
                      ),
                      index: prompt.category.index,
                    ),
                    if (!isPremium && prompt.isPremiumOnly) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const _PremiumBadge(),
                    ],
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  prompt.text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.1,
                    height: 1.4,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (prompt.description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    prompt.description!,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.tagAccentBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 10,
            color: AppColors.tagAccentFg,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            context.l10n.premiumBadgeLabel,
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.tagAccentFg,
            ),
          ),
        ],
      ),
    );
  }
}
