import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../../constants/subscription_constants.dart';
import '../../localization/localization_extensions.dart';
import 'custom_dialog.dart';

/// 特定用途向けのプリセットダイアログ
class PresetDialogs {
  /// 成功ダイアログ
  static CustomDialog success({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    final l10n = context.l10n;
    return CustomDialog(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(
          text: l10n.commonOk,
          isPrimary: true,
          onPressed: onConfirm,
        ),
      ],
    );
  }

  /// エラーダイアログ
  static CustomDialog error({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    final l10n = context.l10n;
    return CustomDialog(
      icon: Icons.error_rounded,
      iconColor: AppColors.error,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(
          text: l10n.commonOk,
          isPrimary: true,
          onPressed: onConfirm,
        ),
      ],
    );
  }

  /// 確認ダイアログ
  static CustomDialog confirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final l10n = context.l10n;
    return CustomDialog(
      icon: isDestructive ? Icons.warning_amber_rounded : Icons.help_rounded,
      iconColor: isDestructive ? AppColors.warning : AppColors.secondary,
      title: title,
      message: message,
      onClose: onCancel,
      actions: [
        CustomDialogAction(
          text: confirmText ?? l10n.commonConfirm,
          isPrimary: true,
          isDestructive: isDestructive,
          onPressed: onConfirm,
        ),
      ],
    );
  }

  /// ローディングダイアログ
  static CustomDialog loading({required String message}) {
    return CustomDialog(
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: AppSpacing.lg),
          Builder(
            builder: (context) => Text(
              message,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 使用量制限エラー専用ダイアログ
  static CustomDialog usageLimitReached({
    required BuildContext context,
    required int limit,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final l10n = context.l10n;
    final resetDateText = l10n.formatMonthDayLong(nextResetDate);

    return CustomDialog(
      icon: Icons.block_rounded,
      iconColor: AppColors.warning,
      title: l10n.usageLimitDialogTitle,
      onClose: onDismiss,
      actions: onUpgrade != null
          ? [
              CustomDialogAction(
                text: l10n.settingsUpgradeToPremium,
                isPrimary: true,
                onPressed: onUpgrade,
              ),
            ]
          : null,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.usageLimitDialogBody(limit),
              style: AppTypography.bodyMedium.copyWith(height: 1.4),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.warningContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 3, color: AppColors.warning),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.usageLimitDialogResetLabel,
                              style: AppTypography.labelSmall,
                            ),
                            Text(
                              l10n.usageLimitDialogResetValue(resetDateText),
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 使用量カウンター表示ダイアログ（「Your current plan」モーダル）
  static CustomDialog usageStatus({
    required BuildContext context,
    required String planName,
    required String planId,
    required int usageCount,
    required int limit,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final l10n = context.l10n;
    final resetDateText = l10n.formatMonthDayLong(nextResetDate);
    final isBasic = planId == SubscriptionConstants.basicPlanId;
    final photosValue = isBasic
        ? l10n.currentPlanPhotosBasicValue
        : l10n.currentPlanPhotosPremiumValue;

    return CustomDialog(
      icon: Icons.data_usage_rounded,
      iconColor: null,
      title: l10n.usageStatusDialogTitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.usageStatusCurrentPlan(planName),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.currentPlanPhotosLabel,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        photosValue,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          l10n.currentPlanStoriesLabel,
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        l10n.currentPlanStoriesValue(usageCount, limit),
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.xs),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: AppSpacing.iconSm,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.usageStatusResetInfo(resetDateText),
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isBasic) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.currentPlanPremiumPitch(
                  SubscriptionConstants.premiumMonthlyAiLimit,
                ),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ],
        ),
      ),
      onClose: onDismiss,
      actions: isBasic && onUpgrade != null
          ? [
              CustomDialogAction(
                text: l10n.settingsUpgradeToPremium,
                isPrimary: true,
                onPressed: onUpgrade,
              ),
            ]
          : null,
    );
  }
}
