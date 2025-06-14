import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/micro_interactions.dart';

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
                Flexible(
                  child: _buildContent(),
                ),
                
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
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                  color: iconColor?.withValues(alpha: 0.2) ?? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
    final effectivePadding = contentPadding ?? const EdgeInsets.all(AppSpacing.lg);
    
    return Container(
      width: double.infinity,
      padding: effectivePadding,
      child: content ?? (message != null ? 
        Builder(
          builder: (context) => Text(
            message!,
            style: AppTypography.bodyLarge.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ) : const SizedBox.shrink()),
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
        children: actions!.map((action) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: actions!.length > 1 ? AppSpacing.xs : 0,
            ),
            child: action,
          ),
        )).toList(),
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
    final color = isDestructive 
        ? AppColors.error 
        : isPrimary 
            ? AppColors.primary 
            : Theme.of(context).colorScheme.onSurfaceVariant;

    return MicroInteractions.bounceOnTap(
      onTap: onPressed ?? () {},
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: isPrimary ? null : Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon!,
                      size: AppSpacing.iconSm,
                      color: isPrimary ? Colors.white : color,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelLarge.copyWith(
                      color: isPrimary ? Colors.white : color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
        CustomDialogAction(
          text: 'OK',
          isPrimary: true,
          onPressed: onConfirm,
        ),
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
        CustomDialogAction(
          text: 'OK',
          isPrimary: true,
          onPressed: onConfirm,
        ),
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
        CustomDialogAction(
          text: cancelText,
          onPressed: onCancel,
        ),
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
  static CustomDialog loading({
    required String message,
  }) {
    return CustomDialog(
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Builder(
            builder: (context) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
              ),
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
}