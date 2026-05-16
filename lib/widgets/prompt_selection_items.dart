import 'package:flutter/material.dart';
import '../models/writing_prompt.dart';
import '../ui/components/modern_chip.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../utils/prompt_category_utils.dart';

class PromptSelectionItems {
  PromptSelectionItems._();

  /// プロンプトカード
  static Widget buildPromptCard(
    BuildContext context, {
    required WritingPrompt prompt,
    required bool isSelected,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.transparent,
          ),
        ),
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (prompt.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                prompt.description!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// プレミアムプロンプトのバッジ（ロックアイコン + "PREMIUM" ラベル）
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
            'PREMIUM',
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.tagAccentFg,
            ),
          ),
        ],
      ),
    );
  }
}
