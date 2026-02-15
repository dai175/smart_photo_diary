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
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return _SelectableCard(
      isSelected: isSelected,
      accentColor: accentColor,
      onTap: onTap,
      child: Row(
        children: [
          _CircleIcon(
            isSelected: isSelected,
            accentColor: accentColor,
            icon: Icons.edit_off_rounded,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.promptOptionNone,
                  style: AppTypography.titleSmall.copyWith(
                    color: isSelected ? accentColor : colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.promptOptionNoneDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: accentColor, size: 20),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return _SelectableCard(
      isSelected: isSelected,
      accentColor: accentColor,
      unselectedBackgroundColor: accentColor.withValues(alpha: 0.05),
      onTap: onTap,
      child: Row(
        children: [
          _CircleIcon(
            isSelected: isSelected,
            accentColor: accentColor,
            icon: Icons.shuffle_rounded,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.promptOptionRandom,
                  style: AppTypography.titleSmall.copyWith(
                    color: isSelected ? accentColor : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isLoading
                      ? l10n.promptLoadingMessage
                      : l10n.promptRandomDescription,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: accentColor, size: 20)
          else
            Icon(
              Icons.auto_awesome_rounded,
              color: accentColor.withValues(alpha: 0.7),
              size: 20,
            ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = PromptCategoryUtils.getCategoryColor(prompt.category);

    return _SelectableCard(
      isSelected: isSelected,
      accentColor: accentColor,
      onTap: onTap,
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
                      ? accentColor
                      : accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Text(
                  PromptCategoryUtils.getCategoryDisplayName(
                    prompt.category,
                    locale: Localizations.localeOf(context),
                  ),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected ? colorScheme.onPrimary : accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            prompt.text,
            style: isSelected
                ? AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)
                : AppTypography.bodyMedium,
          ),
          if (prompt.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              prompt.description!,
              style: AppTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 選択可能なカードの共通デコレーション
///
/// 選択状態に応じて背景色・ボーダーを切り替える。
class _SelectableCard extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;
  final Color? unselectedBackgroundColor;
  final VoidCallback? onTap;
  final Widget child;

  const _SelectableCard({
    required this.isSelected,
    required this.accentColor,
    this.unselectedBackgroundColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.cardRadius,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.15)
              : unselectedBackgroundColor,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 円形アイコン（プロンプトなし・ランダム選択で使用）
class _CircleIcon extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;
  final IconData icon;

  const _CircleIcon({
    required this.isSelected,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}
