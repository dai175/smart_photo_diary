import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../component_constants.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import '../animations/tap_scale_mixin.dart';

/// モダンなデザインのチップ/タグコンポーネント
/// カテゴリー別の色分け、アニメーション効果を提供
class ModernChip extends StatefulWidget {
  const ModernChip({
    super.key,
    required this.label,
    this.onTap,
    this.onDeleted,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.deleteIcon,
    this.enabled = true,
    this.size = ChipSize.medium,
    this.style = ChipStyle.filled,
    this.animationDuration = AppConstants.quickAnimationDuration,
    this.borderRadius,
    this.textStyle,
  }) : _variant = _ChipVariant.normal,
       _toneIndex = null;

  static const _tonedTagBgs = [
    AppColors.tagPrimaryBg,
    AppColors.tagSecondaryBg,
    AppColors.tagAccentBg,
  ];
  static const _tonedTagFgs = [
    AppColors.tagPrimaryFg,
    AppColors.tagSecondaryFg,
    AppColors.tagAccentFg,
  ];
  static const _tonedTagBgsDark = [
    AppColors.tagPrimaryBgDark,
    AppColors.tagSecondaryBgDark,
    AppColors.tagAccentBgDark,
  ];
  static const _tonedTagFgsDark = [
    AppColors.tagPrimaryFgDark,
    AppColors.tagSecondaryFgDark,
    AppColors.tagAccentFgDark,
  ];
  static const _tonedTagTextStyle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
  );

  const ModernChip._tonedTag({
    super.key,
    required this.label,
    required int toneIndex,
  }) : _variant = _ChipVariant.tonedTag,
       _toneIndex = toneIndex,
       onTap = null,
       onDeleted = null,
       backgroundColor = null,
       foregroundColor = null,
       icon = null,
       deleteIcon = null,
       enabled = true,
       size = ChipSize.small,
       style = ChipStyle.filled,
       animationDuration = AppConstants.quickAnimationDuration,
       borderRadius = 8.0,
       textStyle = _tonedTagTextStyle;

  factory ModernChip.tonedTag(String label, {required int index}) =>
      ModernChip._tonedTag(label: label, toneIndex: index % 3);

  /// 日記タグ表示専用コンストラクタ
  /// 全画面で統一されたタグスタイルを提供
  const ModernChip.tag({super.key, required this.label})
    : onTap = null,
      onDeleted = null,
      backgroundColor = null,
      foregroundColor = null,
      icon = null,
      deleteIcon = null,
      enabled = true,
      size = ChipSize.small,
      style = ChipStyle.filled,
      animationDuration = AppConstants.quickAnimationDuration,
      borderRadius = null,
      textStyle = null,
      _variant = _ChipVariant.tag,
      _toneIndex = null;

  /// タグカウントバッジ表示専用コンストラクタ
  /// 日記詳細画面などでタグ数を表示するバッジに使用
  const ModernChip.badge({super.key, required this.label, required this.icon})
    : onTap = null,
      onDeleted = null,
      backgroundColor = null,
      foregroundColor = null,
      deleteIcon = null,
      enabled = true,
      size = ChipSize.small,
      style = ChipStyle.filled,
      animationDuration = AppConstants.quickAnimationDuration,
      borderRadius = null,
      textStyle = null,
      _variant = _ChipVariant.badge,
      _toneIndex = null;

  /// チップのラベルテキスト
  final String label;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// 削除時のコールバック
  final VoidCallback? onDeleted;

  /// 背景色
  final Color? backgroundColor;

  /// 前景色（テキスト・アイコンの色）
  final Color? foregroundColor;

  /// 先頭に表示するアイコン
  final IconData? icon;

  /// 削除アイコン
  final IconData? deleteIcon;

  /// 有効状態
  final bool enabled;

  /// チップのサイズ
  final ChipSize size;

  /// チップのスタイル
  final ChipStyle style;

  /// アニメーションの継続時間
  final Duration animationDuration;

  /// カスタム角丸半径（null時はサイズに応じた pill 形）
  final double? borderRadius;

  final TextStyle? textStyle;

  /// チップのバリアント（内部フラグ）
  final _ChipVariant _variant;

  final int? _toneIndex;

  @override
  State<ModernChip> createState() => _ModernChipState();
}

class _ModernChipState extends State<ModernChip>
    with SingleTickerProviderStateMixin, TapScaleMixin {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    initTapScale(vsync: this, duration: widget.animationDuration);
  }

  @override
  void dispose() {
    disposeTapScale();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onTap != null) {
      handleTapScaleDown();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onTap != null) {
      handleTapScaleUp();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.onTap != null) {
      handleTapScaleCancel();
    }
  }

  void _handleHoverEnter() {
    setState(() => _isHovered = true);
  }

  void _handleHoverExit() {
    setState(() => _isHovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final chipData = _getChipSizeData(widget.size);
    final colorData = _getChipColorData(context);

    return AnimatedBuilder(
      animation: tapScaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: (widget.enabled && widget.onTap != null)
              ? tapScaleAnimation.value
              : 1.0,
          child: MouseRegion(
            onEnter: (_) => _handleHoverEnter(),
            onExit: (_) => _handleHoverExit(),
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              child: AnimatedContainer(
                duration: widget.animationDuration,
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: _getBackgroundColor(colorData),
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? chipData.height / 2,
                  ),
                  border: widget.style == ChipStyle.outlined
                      ? Border.all(
                          color: colorData.borderColor,
                          width: ChipConstants.borderWidth,
                        )
                      : null,
                  boxShadow: widget.style == ChipStyle.elevated
                      ? [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: _isHovered
                                ? ChipConstants.blurRadiusHover
                                : ChipConstants.blurRadiusNormal,
                            offset: Offset(
                              0,
                              _isHovered
                                  ? ChipConstants.offsetYHover
                                  : ChipConstants.offsetYNormal,
                            ),
                          ),
                        ]
                      : null,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: chipData.horizontalPadding,
                  vertical: chipData.verticalPadding,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: chipData.iconSize,
                        color: colorData.foregroundColor,
                      ),
                      SizedBox(width: chipData.spacing),
                    ],
                    Text(
                      widget.label,
                      style: (widget.textStyle ?? chipData.textStyle).copyWith(
                        color: colorData.foregroundColor,
                      ),
                    ),
                    if (widget.onDeleted != null) ...[
                      SizedBox(width: chipData.spacing),
                      GestureDetector(
                        onTap: widget.enabled ? widget.onDeleted : null,
                        child: Icon(
                          widget.deleteIcon ?? Icons.close,
                          size: chipData.iconSize,
                          color: colorData.foregroundColor.withValues(
                            alpha: AppConstants.opacityMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(_ChipColorData colorData) {
    if (!widget.enabled) {
      return colorData.backgroundColor.withValues(
        alpha: AppConstants.opacityXLow,
      );
    }

    if (widget.style == ChipStyle.outlined) {
      return _isHovered
          ? colorData.backgroundColor.withValues(
              alpha: AppConstants.opacityXXLow,
            )
          : Colors.transparent;
    }

    if (_isHovered) {
      return colorData.hoverColor;
    }

    return colorData.backgroundColor;
  }

  _ChipSizeData _getChipSizeData(ChipSize size) {
    switch (size) {
      case ChipSize.small:
        return const _ChipSizeData(
          height: ChipConstants.heightSm,
          horizontalPadding: AppSpacing.sm,
          verticalPadding: AppSpacing.xxs,
          iconSize: ChipConstants.iconSm,
          spacing: AppSpacing.xs,
          textStyle: AppTypography.labelSmall,
        );
      case ChipSize.medium:
        return const _ChipSizeData(
          height: ChipConstants.heightMd,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.xs,
          iconSize: ChipConstants.iconMd,
          spacing: AppSpacing.xs,
          textStyle: AppTypography.labelMedium,
        );
      case ChipSize.large:
        return const _ChipSizeData(
          height: ChipConstants.heightLg,
          horizontalPadding: AppSpacing.lg,
          verticalPadding: AppSpacing.sm,
          iconSize: ChipConstants.iconLg,
          spacing: AppSpacing.sm,
          textStyle: AppTypography.labelLarge,
        );
    }
  }

  _ChipColorData _getChipColorData(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget._variant == _ChipVariant.tonedTag) {
      // _toneIndex is always non-null when _variant == tonedTag (set in _tonedTag constructor)
      final tone = widget._toneIndex!;
      final bg = isDark
          ? ModernChip._tonedTagBgsDark[tone]
          : ModernChip._tonedTagBgs[tone];
      final fg = isDark
          ? ModernChip._tonedTagFgsDark[tone]
          : ModernChip._tonedTagFgs[tone];
      return _ChipColorData(
        backgroundColor: bg,
        foregroundColor: fg,
        borderColor: Colors.transparent,
        hoverColor: bg.withValues(alpha: AppConstants.opacityHigh),
      );
    }

    if (widget._variant == _ChipVariant.tag ||
        widget._variant == _ChipVariant.badge) {
      final bg = isDark ? AppColors.tagPrimaryBgDark : AppColors.tagPrimaryBg;
      return _ChipColorData(
        backgroundColor: bg,
        foregroundColor: isDark
            ? AppColors.tagPrimaryFgDark
            : AppColors.tagPrimaryFg,
        borderColor: isDark ? AppColors.outlineDark : AppColors.chipOutline,
        hoverColor: bg.withValues(alpha: AppConstants.opacityHigh),
      );
    }

    return _ChipColorData(
      backgroundColor: widget.backgroundColor ?? AppColors.primaryContainer,
      foregroundColor: widget.foregroundColor ?? AppColors.onPrimaryContainer,
      borderColor:
          widget.backgroundColor ??
          (isDark ? AppColors.outlineDark : AppColors.chipOutline),
      hoverColor: (widget.backgroundColor ?? AppColors.primaryContainer)
          .withValues(alpha: AppConstants.opacityHigh),
    );
  }
}

/// チップのバリアント（内部用）
enum _ChipVariant { normal, tag, badge, tonedTag }

/// チップのサイズ
enum ChipSize { small, medium, large }

/// チップのスタイル
enum ChipStyle { filled, outlined, elevated }

/// チップのサイズデータ
class _ChipSizeData {
  const _ChipSizeData({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.spacing,
    required this.textStyle,
  });

  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double spacing;
  final TextStyle textStyle;
}

/// チップの色データ
class _ChipColorData {
  const _ChipColorData({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.hoverColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Color hoverColor;
}
