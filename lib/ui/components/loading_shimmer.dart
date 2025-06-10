import 'package:flutter/material.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';

/// スケルトンローディングアニメーションコンポーネント
/// 美しいシマー効果でコンテンツの読み込み状態を表現
class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
    this.direction = ShimmerDirection.ltr,
    this.period = const Duration(milliseconds: 1500),
  });

  /// シマー効果を適用する子ウィジェット
  final Widget child;

  /// ベースカラー
  final Color? baseColor;

  /// ハイライトカラー
  final Color? highlightColor;

  /// シマー効果を有効にするか
  final bool enabled;

  /// シマーの方向
  final ShimmerDirection direction;

  /// アニメーションの周期
  final Duration period;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.period,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(LoadingShimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? AppColors.surfaceVariant;
    final highlightColor = widget.highlightColor ?? Colors.white.withValues(alpha: 0.8);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final gradient = _createShimmerGradient(
              bounds,
              baseColor,
              highlightColor,
            );
            return gradient.createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }

  LinearGradient _createShimmerGradient(
    Rect bounds,
    Color baseColor,
    Color highlightColor,
  ) {
    final double gradientWidth = bounds.width;
    final double gradientCenter = gradientWidth / 2;
    final double animationValue = _animation.value;
    final double shimmerPosition = gradientCenter + (animationValue * gradientCenter);

    List<double> stops;
    List<Color> colors;

    if (shimmerPosition < 0) {
      stops = [0.0, 0.0, 1.0];
      colors = [baseColor, baseColor, baseColor];
    } else if (shimmerPosition > gradientWidth) {
      stops = [0.0, 1.0, 1.0];
      colors = [baseColor, baseColor, baseColor];
    } else {
      final double shimmerStart = (shimmerPosition - gradientCenter * 0.3) / gradientWidth;
      final double shimmerEnd = (shimmerPosition + gradientCenter * 0.3) / gradientWidth;

      stops = [
        (shimmerStart - 0.1).clamp(0.0, 1.0),
        shimmerStart.clamp(0.0, 1.0),
        (shimmerPosition / gradientWidth).clamp(0.0, 1.0),
        shimmerEnd.clamp(0.0, 1.0),
        (shimmerEnd + 0.1).clamp(0.0, 1.0),
      ];

      colors = [
        baseColor,
        baseColor,
        highlightColor,
        baseColor,
        baseColor,
      ];
    }

    return LinearGradient(
      begin: _getGradientBegin(),
      end: _getGradientEnd(),
      colors: colors,
      stops: stops,
    );
  }

  Alignment _getGradientBegin() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment.centerLeft;
      case ShimmerDirection.rtl:
        return Alignment.centerRight;
      case ShimmerDirection.ttb:
        return Alignment.topCenter;
      case ShimmerDirection.btt:
        return Alignment.bottomCenter;
    }
  }

  Alignment _getGradientEnd() {
    switch (widget.direction) {
      case ShimmerDirection.ltr:
        return Alignment.centerRight;
      case ShimmerDirection.rtl:
        return Alignment.centerLeft;
      case ShimmerDirection.ttb:
        return Alignment.bottomCenter;
      case ShimmerDirection.btt:
        return Alignment.topCenter;
    }
  }
}

/// シマーの方向
enum ShimmerDirection {
  /// 左から右
  ltr,
  /// 右から左
  rtl,
  /// 上から下
  ttb,
  /// 下から上
  btt,
}

/// 事前定義されたシマーウィジェット

/// テキスト用シマー
class TextShimmer extends StatelessWidget {
  const TextShimmer({
    super.key,
    this.width = 100,
    this.height = 16,
    this.enabled = true,
  });

  final double width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

/// カード用シマー
class CardShimmer extends StatelessWidget {
  const CardShimmer({
    super.key,
    this.width,
    this.height = 200,
    this.enabled = true,
  });

  final double? width;
  final double height;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        margin: AppSpacing.cardMargin,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppSpacing.cardRadius,
        ),
      ),
    );
  }
}

/// アバター/プロフィール画像用シマー
class AvatarShimmer extends StatelessWidget {
  const AvatarShimmer({
    super.key,
    this.size = 48,
    this.enabled = true,
  });

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 写真/画像用シマー
class ImageShimmer extends StatelessWidget {
  const ImageShimmer({
    super.key,
    this.width = 100,
    this.height = 100,
    this.borderRadius,
    this.enabled = true,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: borderRadius ?? AppSpacing.photoRadius,
        ),
      ),
    );
  }
}

/// リストアイテム用シマー
class ListItemShimmer extends StatelessWidget {
  const ListItemShimmer({
    super.key,
    this.height = 72,
    this.enabled = true,
    this.showAvatar = true,
    this.showTrailing = false,
  });

  final double height;
  final bool enabled;
  final bool showAvatar;
  final bool showTrailing;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        height: height,
        padding: AppSpacing.listItemPadding,
        child: Row(
          children: [
            if (showAvatar) ...[
              AvatarShimmer(enabled: false, size: 40),
              const SizedBox(width: AppSpacing.lg),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextShimmer(
                    enabled: false,
                    width: 150,
                    height: 16,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextShimmer(
                    enabled: false,
                    width: 100,
                    height: 12,
                  ),
                ],
              ),
            ),
            if (showTrailing) ...[
              const SizedBox(width: AppSpacing.lg),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 日記カード用シマー
class DiaryCardShimmer extends StatelessWidget {
  const DiaryCardShimmer({
    super.key,
    this.enabled = true,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LoadingShimmer(
      enabled: enabled,
      child: Container(
        margin: AppSpacing.cardMargin,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppSpacing.cardRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付
            TextShimmer(enabled: false, width: 120, height: 14),
            const SizedBox(height: AppSpacing.sm),
            
            // タイトル
            TextShimmer(enabled: false, width: 200, height: 18),
            const SizedBox(height: AppSpacing.lg),
            
            // 画像
            ImageShimmer(
              enabled: false,
              width: double.infinity,
              height: 150,
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 本文
            TextShimmer(enabled: false, width: double.infinity, height: 14),
            const SizedBox(height: AppSpacing.xs),
            TextShimmer(enabled: false, width: 250, height: 14),
            const SizedBox(height: AppSpacing.xs),
            TextShimmer(enabled: false, width: 180, height: 14),
            const SizedBox(height: AppSpacing.lg),
            
            // タグ
            Row(
              children: [
                Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 80,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}