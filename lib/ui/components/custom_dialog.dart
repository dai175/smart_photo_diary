import 'package:flutter/material.dart';
import '../component_constants.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/micro_interactions.dart';
import '../components/animated_button.dart';

export 'preset_dialogs.dart';

class CustomDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final Color? headerColor;
  final List<Widget>? actions;
  final bool barrierDismissible;
  final EdgeInsets? contentPadding;
  final double? maxWidth;
  final VoidCallback? onClose;

  const CustomDialog({
    super.key,
    this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.headerColor,
    this.actions,
    this.barrierDismissible = true,
    this.contentPadding,
    this.maxWidth,
    this.onClose,
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
            borderRadius: BorderRadius.circular(ModalConstants.radius),
            boxShadow: ModalConstants.shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ModalConstants.radius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null || title != null || onClose != null)
                  _buildHeader(context),
                Flexible(child: _buildContent()),
                if (actions != null && actions!.isNotEmpty) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _closeButtonSize = AppSpacing.minTouchTarget;

  Widget _buildHeader(BuildContext context) {
    final hasClose = onClose != null;

    final iconWidget = icon != null
        ? Container(
            width: ModalConstants.iconSize,
            height: ModalConstants.iconSize,
            decoration: BoxDecoration(
              color:
                  iconColor?.withValues(alpha: 0.12) ??
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(ModalConstants.iconRadius),
            ),
            child: Icon(
              icon!,
              size: AppSpacing.iconMd,
              color: iconColor ?? Theme.of(context).colorScheme.primary,
            ),
          )
        : null;

    final titleWidget = title != null
        ? Text(
            title!,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          )
        : null;

    final centeredColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(height: AppSpacing.md),
        ],
        ?titleWidget,
      ],
    );

    final Widget headerContent;
    if (!hasClose) {
      headerContent = Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          0,
        ),
        child: centeredColumn,
      );
    } else {
      headerContent = Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
          0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: _closeButtonSize),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: centeredColumn,
              ),
            ),
            SizedBox(
              width: _closeButtonSize,
              height: _closeButtonSize,
              child: IconButton(
                onPressed: onClose,
                tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      );
    }

    if (headerColor != null) {
      return Container(
        color: headerColor,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: headerContent,
      );
    }
    return headerContent;
  }

  Widget _buildContent() {
    final effectivePadding =
        contentPadding ??
        const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        );

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
                  ),
                )
              : const SizedBox.shrink()),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: actions!.length == 2
          ? Row(
              children: [
                Expanded(child: actions![0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: actions![1]),
              ],
            )
          : actions!.length == 1
          ? SizedBox(width: double.infinity, child: actions!.first)
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
