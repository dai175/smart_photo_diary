import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_typography.dart';

/// グラデーション対応のカスタムアプリバー
/// 美しいグラデーション背景、カスタムアニメーション、シャドウ効果を提供
class GradientAppBar extends StatefulWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.shadowColor,
    this.centerTitle = false,
    this.titleSpacing,
    this.leadingWidth,
    this.toolbarHeight,
    this.flexibleSpace,
    this.bottom,
    this.shape,
    this.systemOverlayStyle,
    this.enableGradientAnimation = false,
    this.animationDuration = const Duration(seconds: 3),
  });

  /// タイトルウィジェット
  final Widget? title;

  /// 先頭のウィジェット（通常は戻るボタン）
  final Widget? leading;

  /// 末尾のアクションウィジェット
  final List<Widget>? actions;

  /// グラデーション背景
  final Gradient? gradient;

  /// 単色背景（グラデーションが設定されている場合は無視）
  final Color? backgroundColor;

  /// 前景色（タイトル・アイコンの色）
  final Color? foregroundColor;

  /// 影の深さ
  final double? elevation;

  /// 影の色
  final Color? shadowColor;

  /// タイトルを中央に配置するか
  final bool centerTitle;

  /// タイトルのスペーシング
  final double? titleSpacing;

  /// 先頭ウィジェットの幅
  final double? leadingWidth;

  /// ツールバーの高さ
  final double? toolbarHeight;

  /// フレキシブルスペース
  final Widget? flexibleSpace;

  /// ボトムウィジェット
  final PreferredSizeWidget? bottom;

  /// アプリバーの形状
  final ShapeBorder? shape;

  /// システムオーバーレイスタイル
  final SystemUiOverlayStyle? systemOverlayStyle;

  /// グラデーションアニメーションを有効にするか
  final bool enableGradientAnimation;

  /// アニメーションの継続時間
  final Duration animationDuration;

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  State<GradientAppBar> createState() => _GradientAppBarState();
}

class _GradientAppBarState extends State<GradientAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.enableGradientAnimation) {
      _animationController = AnimationController(
        duration: widget.animationDuration,
        vsync: this,
      );

      _gradientAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );

      _animationController.repeat(reverse: true);
    } else {
      _animationController = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
      _gradientAnimation = const AlwaysStoppedAnimation(0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.gradient ?? AppColors.primaryGradient;
    final foregroundColor = widget.foregroundColor ?? Colors.white;
    final elevation = widget.elevation ?? 0.0;
    final shadowColor = widget.shadowColor ?? AppColors.shadow;

    return AnimatedBuilder(
      animation: _gradientAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: widget.enableGradientAnimation
                ? _createAnimatedGradient(gradient)
                : gradient,
            color: widget.gradient == null ? widget.backgroundColor : null,
            boxShadow: elevation > 0
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: elevation,
                      offset: Offset(0, elevation / 2),
                    ),
                  ]
                : null,
          ),
          child: AppBar(
            title: widget.title,
            leading: widget.leading,
            actions: widget.actions,
            backgroundColor: Colors.transparent,
            foregroundColor: foregroundColor,
            elevation: 0,
            centerTitle: widget.centerTitle,
            titleSpacing: widget.titleSpacing,
            leadingWidth: widget.leadingWidth,
            toolbarHeight: widget.toolbarHeight,
            flexibleSpace: widget.flexibleSpace,
            bottom: widget.bottom,
            shape: widget.shape,
            systemOverlayStyle:
                widget.systemOverlayStyle ??
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: _getStatusBarIconBrightness(),
                ),
            titleTextStyle: AppTypography.withColor(
              AppTypography.appTitle,
              foregroundColor,
            ),
          ),
        );
      },
    );
  }

  Gradient _createAnimatedGradient(Gradient baseGradient) {
    if (baseGradient is LinearGradient) {
      // グラデーションの角度をアニメーション
      final animatedBegin = Alignment.lerp(
        baseGradient.begin as Alignment,
        baseGradient.end as Alignment,
        _gradientAnimation.value,
      )!;

      final animatedEnd = Alignment.lerp(
        baseGradient.end as Alignment,
        baseGradient.begin as Alignment,
        _gradientAnimation.value,
      )!;

      return LinearGradient(
        begin: animatedBegin,
        end: animatedEnd,
        colors: baseGradient.colors,
        stops: baseGradient.stops,
      );
    }

    return baseGradient;
  }

  Brightness _getStatusBarIconBrightness() {
    // グラデーションの明度を計算して適切なアイコンの明度を決定
    if (widget.foregroundColor == Colors.white) {
      return Brightness.light;
    } else {
      return Brightness.dark;
    }
  }
}

/// アプリバーのバリエーション

/// ホーム画面用のグラデーションアプリバー
class HomeGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HomeGradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.enableAnimation = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool enableAnimation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      title: Text(title),
      actions: actions,
      gradient: AppColors.modernHomeGradient,
      enableGradientAnimation: enableAnimation,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }
}

/// 標準的なプライマリーカラーのアプリバー
class PrimaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PrimaryAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.elevation,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final double? elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      gradient: AppColors.primaryGradient,
      elevation: elevation,
    );
  }
}

/// トランスペアレントなアプリバー
class TransparentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TransparentAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.foregroundColor,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return GradientAppBar(
      title: title,
      leading: leading,
      actions: actions,
      backgroundColor: Colors.transparent,
      foregroundColor: foregroundColor ?? AppColors.onBackground,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: foregroundColor == Colors.white
            ? Brightness.light
            : Brightness.dark,
      ),
    );
  }
}

/// カスタムFlexibleSpaceを持つアプリバー
class FlexibleGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const FlexibleGradientAppBar({
    super.key,
    required this.title,
    required this.backgroundWidget,
    this.actions,
    this.expandedHeight = 200.0,
  });

  final String title;
  final Widget backgroundWidget;
  final List<Widget>? actions;
  final double expandedHeight;

  @override
  Size get preferredSize => Size.fromHeight(expandedHeight);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Text(title),
      actions: actions,
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.modernHomeGradient,
          ),
          child: backgroundWidget,
        ),
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }
}
