import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../../constants/app_constants.dart';
import '../design_system/app_spacing.dart';
import '../animations/tap_scale_mixin.dart';

/// 統一されたデザインのカードコンポーネント
/// 美しいシャドウ、アニメーション、ホバー効果を提供
class CustomCard extends StatefulWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.elevation,
    this.shadowColor,
    this.enableHoverEffect = true,
    this.enableTapAnimation = true,
    this.border,
    this.width,
    this.height,
  });

  /// カード内のコンテンツ
  final Widget child;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// カード内のパディング
  final EdgeInsetsGeometry? padding;

  /// カード外のマージン
  final EdgeInsetsGeometry? margin;

  /// 背景色
  final Color? backgroundColor;

  /// 角丸の半径
  final BorderRadius? borderRadius;

  /// 影の深さ
  final double? elevation;

  /// 影の色
  final Color? shadowColor;

  /// ホバー効果を有効にするか
  final bool enableHoverEffect;

  /// タップアニメーションを有効にするか
  final bool enableTapAnimation;

  /// ボーダー
  final Border? border;

  /// カードの幅
  final double? width;

  /// カードの高さ
  final double? height;

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    initTapScale(
      vsync: this,
      duration: AppConstants.shortAnimationDuration,
      scaleFactor: 0.99,
    );

    _elevationAnimation =
        Tween<double>(
          begin: widget.elevation ?? AppSpacing.elevationXs,
          end: (widget.elevation ?? AppSpacing.elevationXs) + 2,
        ).animate(
          CurvedAnimation(parent: tapScaleController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    disposeTapScale();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableTapAnimation) {
      handleTapScaleDown();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableTapAnimation) {
      handleTapScaleUp();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.enableTapAnimation) {
      handleTapScaleCancel();
    }
  }

  void _handleHoverEnter() {
    if (widget.enableHoverEffect) {
      setState(() => _isHovered = true);
    }
  }

  void _handleHoverExit() {
    if (widget.enableHoverEffect) {
      setState(() => _isHovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? AppSpacing.cardRadius;
    final elevation = widget.elevation ?? AppSpacing.elevationXs;
    final shadowColor = widget.shadowColor ?? AppColors.shadow;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: tapScaleController,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin ?? AppSpacing.cardMargin,
          child: MouseRegion(
            onEnter: (_) => _handleHoverEnter(),
            onExit: (_) => _handleHoverExit(),
            child: GestureDetector(
              onTapDown: widget.onTap != null ? _handleTapDown : null,
              onTapUp: widget.onTap != null ? _handleTapUp : null,
              onTapCancel: widget.onTap != null ? _handleTapCancel : null,
              child: Transform.scale(
                scale: widget.enableTapAnimation
                    ? tapScaleAnimation.value
                    : 1.0,
                child: AnimatedContainer(
                  duration: AppConstants.quickAnimationDuration,
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: borderRadius,
                    border:
                        widget.border ??
                        (isDark
                            ? Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 0.5,
                              )
                            : null),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: _isHovered && widget.enableHoverEffect
                                  ? _elevationAnimation.value
                                  : elevation,
                              offset: Offset(
                                0,
                                _isHovered && widget.enableHoverEffect ? 3 : 2,
                              ),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Container(
                      padding: widget.padding ?? AppSpacing.cardPadding,
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
