import 'package:flutter/material.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/micro_interactions.dart';
import '../components/animated_button.dart';

export 'preset_dialogs.dart';

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
            boxShadow: const [
              BoxShadow(
                color: Color(0x14231E1A),
                blurRadius: 16,
                offset: Offset(0, 6),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Color(0x0A231E1A),
                blurRadius: 32,
                offset: Offset(0, 12),
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
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                    fontWeight: FontWeight.w500,
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
      child: actions!.length == 1
          ? actions!.first
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: actions!
                  .map(
                    (action) => Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        bottom: action == actions!.last ? 0 : AppSpacing.sm,
                      ),
                      child: action,
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
