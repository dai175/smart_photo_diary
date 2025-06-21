import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/micro_interactions.dart';
import '../../constants/subscription_constants.dart';
import '../components/animated_button.dart';

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
                  textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
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
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    return CustomDialog(
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(text: 'OK', isPrimary: true, onPressed: onConfirm),
      ],
    );
  }

  /// エラーダイアログ
  static CustomDialog error({
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) {
    return CustomDialog(
      icon: Icons.error_rounded,
      iconColor: AppColors.error,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(text: 'OK', isPrimary: true, onPressed: onConfirm),
      ],
    );
  }

  /// 確認ダイアログ
  static CustomDialog confirmation({
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'キャンセル',
    bool isDestructive = false,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return CustomDialog(
      icon: Icons.help_rounded,
      iconColor: isDestructive ? AppColors.warning : AppColors.info,
      title: title,
      message: message,
      actions: [
        CustomDialogAction(text: cancelText, onPressed: onCancel),
        CustomDialogAction(
          text: confirmText,
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

  /// Phase 1.7.2.1: 使用量制限エラー専用ダイアログ
  static CustomDialog usageLimitReached({
    required String planName,
    required int remaining,
    required int limit,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    return CustomDialog(
      icon: Icons.block_rounded,
      iconColor: AppColors.warning,
      title: 'AI生成の制限に達しました',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '現在のプラン（$planName）では、月間$limit回までAI日記生成をご利用いただけます。',
            style: AppTypography.bodyMedium.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '今月の残り回数:',
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$remaining回',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: remaining > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'リセット日:',
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${nextResetDate.month}月${nextResetDate.day}日',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Premiumプランにアップグレードすると、月間${SubscriptionConstants.premiumMonthlyAiLimit}回まで生成できます。',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        CustomDialogAction(text: '後で', onPressed: onDismiss),
        CustomDialogAction(
          text: 'Premiumにアップグレード',
          isPrimary: true,
          icon: Icons.upgrade_rounded,
          onPressed: onUpgrade,
        ),
      ],
    );
  }

  /// Phase 1.7.2.3: 使用量カウンター表示ダイアログ
  static CustomDialog usageStatus({
    required String planName,
    required int used,
    required int limit,
    required int remaining,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    VoidCallback? onDismiss,
  }) {
    final usagePercentage = used / limit;
    final isNearLimit = usagePercentage >= 0.8;

    return CustomDialog(
      icon: Icons.analytics_rounded,
      iconColor: isNearLimit ? AppColors.warning : AppColors.info,
      title: 'AI生成の使用状況',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '現在のプラン: $planName',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 使用量プログレスバー
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
                        '使用量',
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$used / $limit回',
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // プログレスバー
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: usagePercentage.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isNearLimit
                              ? AppColors.warning
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '残り回数:',
                        style: AppTypography.labelMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$remaining回',
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

          // リセット情報
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
                    '${nextResetDate.month}月${nextResetDate.day}日にリセット',
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // アップグレード案内（Basic プランの場合）
          if (planName == 'Basic') ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Premiumプランなら月間${SubscriptionConstants.premiumMonthlyAiLimit}回まで利用できます',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        CustomDialogAction(text: '閉じる', onPressed: onDismiss),
        if (planName == 'Basic')
          CustomDialogAction(
            text: 'アップグレード',
            isPrimary: true,
            icon: Icons.upgrade_rounded,
            onPressed: onUpgrade,
          ),
      ],
    );
  }
}
