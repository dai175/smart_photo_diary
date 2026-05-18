import 'package:flutter/material.dart';
import '../constants/ai_constants.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';

class PromptSearchBar extends StatelessWidget {
  const PromptSearchBar({
    super.key,
    required this.controller,
    required this.contextAnimation,
    required this.isExpanded,
    required this.onToggle,
  });

  final TextEditingController controller;
  final Animation<double> contextAnimation;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentMutedColor = isDark
        ? AppColors.accentLight
        : AppColors.accentMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: AppConstants.quickAnimationDuration,
                    child: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: accentMutedColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.promptContextToggle,
                    style: AppTypography.bodySmall.copyWith(
                      color: accentMutedColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.promptContextInputHelper,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: contextAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: TextField(
                controller: controller,
                maxLines: 2,
                maxLength: AiConstants.contextTextMaxLength,
                decoration: InputDecoration(
                  labelText: l10n.promptContextInputLabel,
                  hintText: l10n.promptContextInputHint,
                  helperText: l10n.promptContextInputHelper,
                  helperMaxLines: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
