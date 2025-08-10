import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../../services/logging_service.dart';

/// Smart Photo Diary 統一ボタンシステム
///
/// ## ボタン統一ガイドライン
///
/// このファイルには、アプリ全体で統一されたボタンコンポーネントが含まれています。
/// 全てのボタンは Material Design 3 に準拠し、テーマ認識色を使用してライト・ダーク
/// テーマに完全対応しています。
///
/// ## 利用可能なボタンタイプ
///
/// ### プライマリーボタン
/// - `PrimaryButton`: メインアクション用（保存、送信など）
/// - `DangerButton`: 危険な操作用（削除、リセットなど）
///
/// ### セカンダリーボタン
/// - `SecondaryButton`: サブアクション用（境界線あり）
/// - `AccentButton`: アクセント色の強調ボタン
/// - `SurfaceButton`: サーフェス色の控えめなボタン
///
/// ### その他のボタン
/// - `TextOnlyButton`: テキストのみボタン（軽量アクション用）
/// - `IconTextButton`: アイコン+テキストボタン
/// - `SmallButton`: 小さいサイズのボタン
/// - `CircularIconButton`: 丸型アイコンボタン
///
/// ## 設計原則
///
/// - **テーマ認識**: `Theme.of(context).colorScheme` を使用
/// - **ソリッドカラー**: グラデーション廃止、単色のみ使用
/// - **一貫したサイズ**: 標準48dp、小32dp、大56dp
/// - **統一されたアニメーション**: 150ms のスケール・エレベーション
/// - **アクセシビリティ**: 十分なコントラストと最小タッチターゲット
///
/// ## 使用例
///
/// ```dart
/// // プライマリーアクション
/// PrimaryButton(
///   onPressed: () => save(),
///   text: '保存',
///   icon: Icons.save,
/// )
///
/// // セカンダリーアクション
/// SecondaryButton(
///   onPressed: () => cancel(),
///   text: 'キャンセル',
/// )
///
/// // 危険な操作
/// DangerButton(
///   onPressed: () => delete(),
///   text: '削除',
///   icon: Icons.delete,
/// )
/// ```
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

  /// グラデーション背景（廃止予定 - 使用非推奨）
  @Deprecated('グラデーションは廃止予定です。代わりにbackgroundColorを使用してください')
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
    if (kDebugMode) {
      final loggingService = LoggingService.getSafely();
      loggingService?.debug(
        '_handleTapDown が呼び出されました',
        context: 'AnimatedButton',
      );
    }
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
    // onPressed?.call()をonTapに移動
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      // setState(() => _isPressed = false);
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
                onTap: widget.onPressed != null
                    ? () {
                        if (kDebugMode) {
                          final loggingService = LoggingService.getSafely();
                          loggingService?.debug(
                            'onTap が呼び出されました',
                            context: 'AnimatedButton',
                          );
                        }
                        widget.onPressed!();
                      }
                    : null, // メインのタップイベント
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: isLoading
          ? null
          : (onPressed != null
                ? () {
                    if (kDebugMode) {
                      final loggingService = LoggingService.getSafely();
                      loggingService?.debug(
                        'onPressed が呼び出されました',
                        context: 'PrimaryButton',
                      );
                    }
                    onPressed!();
                  }
                : null),
      width: width,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.primary,
      border: Border.fromBorderSide(
        BorderSide(color: theme.colorScheme.primary, width: 1.5),
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: theme.colorScheme.secondary,
      foregroundColor: theme.colorScheme.onSecondary,
      shadowColor: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      borderRadius: BorderRadius.circular(size / 2),
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      child: Icon(icon, size: size * 0.5),
    );
  }
}

// ============= ADDITIONAL BUTTON VARIANTS =============

/// サーフェスボタン（Material Design 3 Surface Tint）
class SurfaceButton extends StatelessWidget {
  const SurfaceButton({
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFE8E8E8) // ライトモードでより濃いグレー
          : theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: AppSpacing.elevationXs,
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

/// 危険な操作用ボタン
class DangerButton extends StatelessWidget {
  const DangerButton({
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: isLoading ? null : onPressed,
      width: width,
      backgroundColor: theme.colorScheme.error,
      foregroundColor: theme.colorScheme.onError,
      shadowColor: theme.colorScheme.error.withValues(alpha: 0.3),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onError,
                ),
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

/// テキストのみボタン
class TextOnlyButton extends StatelessWidget {
  const TextOnlyButton({
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
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: Colors.transparent,
      foregroundColor: theme.colorScheme.primary,
      elevation: 0,
      padding: AppSpacing.buttonPaddingSmall,
      enableScaleAnimation: false, // テキストボタンはスケールアニメーションなし
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(text),
        ],
      ),
    );
  }
}

/// アイコンとテキストボタン（横並び）
class IconTextButton extends StatelessWidget {
  const IconTextButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.isCompact = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedButton(
      onPressed: onPressed,
      width: width,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
      padding: isCompact
          ? AppSpacing.buttonPaddingSmall
          : AppSpacing.buttonPadding,
      height: isCompact ? AppSpacing.buttonHeightSm : AppSpacing.buttonHeightMd,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isCompact ? AppSpacing.iconXs : AppSpacing.iconSm),
          SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
