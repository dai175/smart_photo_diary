import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';

/// アニメーション付きのカスタムボタンコンポーネント
/// グラデーション、シャドウ、タップアニメーションを提供
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.elevation,
    this.shadowColor,
    this.width,
    this.height,
    this.border,
    this.enableSplashEffect = true,
    this.enableScaleAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  /// ボタンが押された時のコールバック
  final VoidCallback? onPressed;

  /// ボタン内のコンテンツ
  final Widget child;

  /// 背景色（グラデーションが設定されている場合は無視）
  final Color? backgroundColor;

  /// 前景色（テキスト・アイコンの色）
  final Color? foregroundColor;

  /// グラデーション背景（非推奨）
  final Gradient? gradient;

  /// 角丸の半径
  final BorderRadius? borderRadius;

  /// ボタン内のパディング
  final EdgeInsetsGeometry? padding;

  /// 影の深さ
  final double? elevation;

  /// 影の色
  final Color? shadowColor;

  /// ボタンの幅
  final double? width;

  /// ボタンの高さ
  final double? height;

  /// ボーダー
  final Border? border;

  /// スプラッシュ効果を有効にするか
  final bool enableSplashEffect;

  /// スケールアニメーションを有効にするか
  final bool enableScaleAnimation;

  /// アニメーションの継続時間
  final Duration animationDuration;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  
  // bool _isPressed = false; // 将来的に使用予定

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? AppSpacing.elevationSm,
      end: (widget.elevation ?? AppSpacing.elevationSm) * 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScaleAnimation) {
      // setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
    }
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.borderRadius ?? AppSpacing.buttonRadius;
    final elevation = widget.elevation ?? AppSpacing.elevationSm;
    final shadowColor = widget.shadowColor ?? AppColors.shadow;
    final backgroundColor = widget.backgroundColor ?? AppColors.primary;
    final foregroundColor = widget.foregroundColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableScaleAnimation ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height ?? AppSpacing.buttonHeightLg,
            decoration: BoxDecoration(
              color: widget.gradient == null ? backgroundColor : null,
              gradient: widget.gradient,
              borderRadius: borderRadius,
              border: widget.border,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: widget.enableScaleAnimation
                      ? _elevationAnimation.value
                      : elevation,
                  offset: Offset(
                    0,
                    widget.enableScaleAnimation
                        ? _elevationAnimation.value / 2
                        : elevation / 2,
                  ),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              child: InkWell(
                onTapDown: widget.onPressed != null ? _handleTapDown : null,
                onTapUp: widget.onPressed != null ? _handleTapUp : null,
                onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
                onTap: null, // ハンドルされているのでnull
                borderRadius: borderRadius,
                splashColor: widget.enableSplashEffect
                    ? foregroundColor.withValues(alpha: 0.2)
                    : Colors.transparent,
                highlightColor: widget.enableSplashEffect
                    ? foregroundColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                child: Container(
                  padding: widget.padding ?? AppSpacing.buttonPaddingSmall,
                  child: DefaultTextStyle(
                    style: AppTypography.withColor(AppTypography.button, foregroundColor),
                    textAlign: TextAlign.center,
                    child: IconTheme(
                      data: IconThemeData(color: foregroundColor),
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

/// ボタンのバリエーション

/// プライマリーボタン
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      width: width,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shadowColor: AppColors.primary.withValues(alpha: 0.3),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconSm),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(text),
              ],
            ),
    );
  }
}

/// セカンダリーボタン
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.primary,
      border: const Border.fromBorderSide(
        BorderSide(color: AppColors.primary, width: 1.5),
      ),
      elevation: 0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

/// アクセントボタン
class AccentButton extends StatelessWidget {
  const AccentButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      shadowColor: AppColors.accent.withValues(alpha: 0.3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// 小さなボタン
class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: AppSpacing.buttonPaddingSmall,
      height: AppSpacing.buttonHeightSm,
      elevation: AppSpacing.elevationXs,
      child: child,
    );
  }
}

/// アイコンボタン（丸型）
class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 48.0,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      borderRadius: BorderRadius.circular(size / 2),
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: size * 0.5),
    );
  }
}