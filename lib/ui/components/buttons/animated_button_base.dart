import 'package:flutter/material.dart';
import '../../design_system/app_spacing.dart';
import '../../design_system/app_typography.dart';

/// Smart Photo Diary 統一ボタンシステム
///
/// ## ボタン統一ガイドライン
///
/// このファイルには、アプリ全体で統一されたボタンコンポーネントの基底クラスが
/// 含まれています。全てのボタンは Material Design 3 に準拠し、テーマ認識色を
/// 使用してライト・ダークテーマに完全対応しています。
///
/// ## 設計原則
///
/// - **テーマ認識**: `Theme.of(context).colorScheme` を使用
/// - **ソリッドカラー**: グラデーション廃止、単色のみ使用
/// - **一貫したサイズ**: 標準48dp、小32dp、大56dp
/// - **統一されたアニメーション**: 150ms のスケール・エレベーション
/// - **アクセシビリティ**: 十分なコントラストと最小タッチターゲット
///
/// ## アニメーション付きのカスタムボタンコンポーネント
/// 基底クラス - 他のボタンはこれを継承して実装されています
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
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

  /// 背景色
  final Color? backgroundColor;

  /// 前景色（テキスト・アイコンの色）
  final Color? foregroundColor;

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _elevationAnimation =
        Tween<double>(
          begin: widget.elevation ?? AppSpacing.elevationSm,
          end: (widget.elevation ?? AppSpacing.elevationSm) * 0.5,
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
    if (widget.enableScaleAnimation) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = widget.borderRadius ?? AppSpacing.buttonRadius;
    final elevation = widget.elevation ?? AppSpacing.elevationSm;
    final shadowColor = widget.shadowColor ?? theme.colorScheme.shadow;

    // テーマ認識色を使用
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor =
        widget.foregroundColor ?? theme.colorScheme.onPrimary;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.enableScaleAnimation ? _scaleAnimation.value : 1.0,
          child: Container(
            width: widget.width,
            height: widget.height ?? AppSpacing.buttonHeightLg,
            decoration: BoxDecoration(
              // グラデーション廃止 - ソリッドカラーのみ使用
              color: backgroundColor,
              borderRadius: borderRadius,
              border: widget.border,
              boxShadow: elevation > 0
                  ? [
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
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: borderRadius,
              child: InkWell(
                onTapDown: widget.onPressed != null ? _handleTapDown : null,
                onTapUp: widget.onPressed != null ? _handleTapUp : null,
                onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
                onTap: widget.onPressed, // メインのタップイベント
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
                    style: AppTypography.withColor(
                      AppTypography.button,
                      foregroundColor,
                    ),
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
