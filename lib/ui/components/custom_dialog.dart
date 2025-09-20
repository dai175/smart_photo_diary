import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/micro_interactions.dart';
import '../../constants/subscription_constants.dart';
import '../components/animated_button.dart';
import '../../localization/localization_extensions.dart';

/// カスタムダイアログウィジェット
/// Smart Photo Diaryアプリのデザインシステムに合わせたモーダル
class CustomDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final List<CustomDialogAction>? actions;
  final bool barrierDismissible;
  final EdgeInsets? contentPadding;
  final double? maxWidth;

  const CustomDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.actions,
    this.barrierDismissible = true,
    this.contentPadding,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: MicroInteractions.scaleTransition(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 40,
                offset: const Offset(0, 16),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ヘッダー部分
                if (icon != null || title != null) _buildHeader(),

                // コンテンツ部分
                Flexible(child: _buildContent()),

                // アクション部分
                if (actions != null && actions!.isNotEmpty) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.lg),
            topRight: Radius.circular(AppSpacing.lg),
          ),
        ),
        child: Column(
          children: [
            // アイコン
            if (icon != null) ...[
              Builder(
                builder: (context) => Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color:
                        iconColor?.withValues(alpha: 0.2) ??
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon!,
                    size: AppSpacing.iconLg,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // タイトル
            if (title != null)
              Builder(
                builder: (context) => Text(
                  title!,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final effectivePadding =
        contentPadding ?? const EdgeInsets.all(AppSpacing.lg);

    return Container(
      width: double.infinity,
      padding: effectivePadding,
      child:
          content ??
          (message != null
              ? Builder(
                  builder: (context) => Text(
                    message!,
                    style: AppTypography.bodyLarge.copyWith(
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.left,
                  ),
                )
              : const SizedBox.shrink()),
    );
  }

  Widget _buildActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: actions!.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceEvenly,
        children: actions!
            .map(
              (action) => Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: actions!.length > 1 ? AppSpacing.xs : 0,
                  ),
                  child: action,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// カスタムダイアログアクションボタン
class CustomDialogAction extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;

  const CustomDialogAction({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      if (isDestructive) {
        return DangerButton(onPressed: onPressed, text: text, icon: icon);
      } else {
        return PrimaryButton(onPressed: onPressed, text: text, icon: icon);
      }
    } else {
      return SecondaryButton(onPressed: onPressed, text: text, icon: icon);
    }
  }
}

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
    String? cancelText,
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final l10n = context.l10n;
    return CustomDialog(
      icon: Icons.help_rounded,
      iconColor: isDestructive ? AppColors.warning : AppColors.info,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(
          text: cancelText ?? l10n.commonCancel,
          onPressed: onCancel,
        ),
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
          Builder(
            builder: (context) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
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
    required String planName,
    required int limit,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final l10n = context.l10n;
    final resetDateText = l10n.formatMonthDayLong(nextResetDate);

    final actions = <CustomDialogAction>[
      CustomDialogAction(text: l10n.commonLater, onPressed: onDismiss),
    ];

    if (onUpgrade != null) {
      actions.add(
        CustomDialogAction(
          text: l10n.commonUpgrade,
          isPrimary: true,
          icon: Icons.auto_awesome_rounded,
          onPressed: onUpgrade,
        ),
      );
    }

    return CustomDialog(
      icon: Icons.block_rounded,
      iconColor: AppColors.warning,
      title: l10n.usageLimitDialogTitle,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.usageLimitDialogReachedMessage(planName, limit),
              style: AppTypography.bodyMedium.copyWith(height: 1.4),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
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
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.usageLimitDialogPremiumHint(
                SubscriptionConstants.premiumMonthlyAiLimit,
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
      actions: actions,
    );
  }

  /// 使用量カウンター表示ダイアログ
  static CustomDialog usageStatus({
    required BuildContext context,
    required String planName,
    required int used,
    required int limit,
    required int remaining,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final l10n = context.l10n;
    final usagePercentage = limit == 0 ? 0.0 : used / limit;
    final isNearLimit = usagePercentage >= 0.8;
    final resetDateText = l10n.formatMonthDayLong(nextResetDate);

    return CustomDialog(
      icon: Icons.analytics_rounded,
      iconColor: isNearLimit ? AppColors.warning : AppColors.info,
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
            Builder(
              builder: (context) => Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.usageStatusUsageLabel,
                          style: AppTypography.labelMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          l10n.usageStatusUsageValue(used, limit),
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: usagePercentage.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isNearLimit
                                  ? AppColors.warning
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.usageStatusRemainingLabel,
                          style: AppTypography.labelMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          l10n.usageStatusRemainingValue(remaining),
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: remaining > 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) => Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: AppSpacing.iconSm,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.usageStatusResetInfo(resetDateText),
                      style: AppTypography.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (planName == 'Basic') ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.usageStatusPremiumUpsell(
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
      actions: [
        CustomDialogAction(text: l10n.commonClose, onPressed: onDismiss),
        if (planName == 'Basic' && onUpgrade != null)
          CustomDialogAction(
            text: l10n.commonUpgrade,
            isPrimary: true,
            icon: Icons.auto_awesome_rounded,
            onPressed: onUpgrade,
          ),
      ],
    );
  }
}
