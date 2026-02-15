import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../../constants/app_constants.dart';
import '../design_system/app_spacing.dart';

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
    this.gradient,
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

  /// 背景色（グラデーションが設定されている場合は無視）
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

  /// グラデーション背景
  final Gradient? gradient;

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
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isHovered = false;
  // bool _isPressed = false; // 将来的に使用予定

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.shortAnimationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _elevationAnimation =
        Tween<double>(
          begin: widget.elevation ?? AppSpacing.elevationSm,
          end: (widget.elevation ?? AppSpacing.elevationSm) + 2,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableTapAnimation) {
      // setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableTapAnimation) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.enableTapAnimation) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
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
    final elevation = widget.elevation ?? AppSpacing.elevationSm;
    final shadowColor = widget.shadowColor ?? AppColors.shadow;
    final backgroundColor =
        widget.backgroundColor ?? Theme.of(context).colorScheme.surface;

    return AnimatedBuilder(
      animation: _animationController,
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
                scale: widget.enableTapAnimation ? _scaleAnimation.value : 1.0,
                child: AnimatedContainer(
                  duration: AppConstants.quickAnimationDuration,
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: widget.gradient == null ? backgroundColor : null,
                    gradient: widget.gradient,
                    borderRadius: borderRadius,
                    border: widget.border,
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: _isHovered && widget.enableHoverEffect
                            ? _elevationAnimation.value
                            : elevation,
                        offset: Offset(
                          0,
                          _isHovered && widget.enableHoverEffect ? 4 : 2,
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

/// カードのバリエーション

/// 小さなカード
class SmallCard extends StatelessWidget {
  const SmallCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      padding: AppSpacing.cardPaddingSmall,
      elevation: AppSpacing.elevationXs,
      borderRadius: AppSpacing.createRadius(AppSpacing.borderRadiusSm),
      child: child,
    );
  }
}

/// 大きなカード
class LargeCard extends StatelessWidget {
  const LargeCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      gradient: gradient,
      padding: AppSpacing.cardPaddingLarge,
      elevation: AppSpacing.elevationMd,
      borderRadius: AppSpacing.cardRadiusLarge,
      child: child,
    );
  }
}

/// 浮上効果付きカード
class ElevatedCard extends StatelessWidget {
  const ElevatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      elevation: AppSpacing.elevationLg,
      enableHoverEffect: true,
      child: child,
    );
  }
}

/// グラデーション付きカード
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.gradient,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      gradient: gradient,
      elevation: AppSpacing.elevationMd,
      shadowColor: AppColors.primary.withValues(
        alpha: AppConstants.opacityXLow,
      ),
      child: child,
    );
  }
}
