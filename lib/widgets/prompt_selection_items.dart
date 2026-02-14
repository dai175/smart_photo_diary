import 'package:flutter/material.dart';
import '../models/writing_prompt.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../utils/prompt_category_utils.dart';
import '../localization/localization_extensions.dart';

/// プロンプト選択モーダル内のアイテムウィジェット
///
/// 「プロンプトなし」オプション、ランダム選択ボタン、
/// 個別プロンプトカードの描画ロジックを提供する。
class PromptSelectionItems {
  PromptSelectionItems._();

  /// 「プロンプトなし」オプション
  static Widget buildNoPromptOption(
    BuildContext context, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : null,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_off_rounded,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.promptOptionNone,
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.promptOptionNoneDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// 「ランダム選択」ボタン
  static Widget buildRandomButton(
    BuildContext context, {
    required bool isSelected,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shuffle_rounded,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.promptOptionRandom,
                    style: AppTypography.titleSmall.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isLoading
                        ? l10n.promptLoadingMessage
                        : l10n.promptRandomDescription,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              )
            else
              Icon(
                Icons.auto_awesome_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  /// プロンプトカード
  static Widget buildPromptCard(
    BuildContext context, {
    required WritingPrompt prompt,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? PromptCategoryUtils.getCategoryColor(
                  prompt.category,
                ).withValues(alpha: 0.15)
              : null,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? PromptCategoryUtils.getCategoryColor(
                    prompt.category,
                  ).withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PromptCategoryUtils.getCategoryColor(prompt.category)
                        : PromptCategoryUtils.getCategoryColor(
                            prompt.category,
                          ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                  ),
                  child: Text(
                    PromptCategoryUtils.getCategoryDisplayName(
                      prompt.category,
                      locale: Localizations.localeOf(context),
                    ),
                    style: AppTypography.labelSmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : PromptCategoryUtils.getCategoryColor(
                              prompt.category,
                            ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: PromptCategoryUtils.getCategoryColor(
                      prompt.category,
                    ),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              prompt.text,
              style: isSelected
                  ? AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    )
                  : AppTypography.bodyMedium,
            ),
            if (prompt.description != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                prompt.description!,
                style: AppTypography.bodySmall.copyWith(
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
