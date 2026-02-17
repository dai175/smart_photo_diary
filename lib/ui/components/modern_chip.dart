import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../component_constants.dart';
import '../design_system/app_colors.dart';
import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';

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
    this.selected = false,
    this.enabled = true,
    this.size = ChipSize.medium,
    this.style = ChipStyle.filled,
    this.animationDuration = const Duration(milliseconds: 200),
  });

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

  /// 選択状態
  final bool selected;

  /// 有効状態
  final bool enabled;

  /// チップのサイズ
  final ChipSize size;

  /// チップのスタイル
  final ChipStyle style;

  /// アニメーションの継続時間
  final Duration animationDuration;

  @override
  State<ModernChip> createState() => _ModernChipState();
}

class _ModernChipState extends State<ModernChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _isHovered = false;
  // bool _isPressed = false; // 将来的に使用予定

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled && widget.onTap != null) {
      // setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled && widget.onTap != null) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
      widget.onTap?.call();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled && widget.onTap != null) {
      // setState(() => _isPressed = false);
      _animationController.reverse();
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
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.onTap != null ? _scaleAnimation.value : 1.0,
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
                  borderRadius: BorderRadius.circular(chipData.height / 2),
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
                      style: chipData.textStyle.copyWith(
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
    if (widget.selected) {
      return _ChipColorData(
        backgroundColor: widget.backgroundColor ?? AppColors.primary,
        foregroundColor: widget.foregroundColor ?? Colors.white,
        borderColor: widget.backgroundColor ?? AppColors.primary,
        hoverColor: (widget.backgroundColor ?? AppColors.primary).withValues(
          alpha: AppConstants.opacityHigh,
        ),
      );
    }

    // final theme = Theme.of(context); // 将来的に使用予定
    return _ChipColorData(
      backgroundColor: widget.backgroundColor ?? AppColors.primaryContainer,
      foregroundColor: widget.foregroundColor ?? AppColors.onPrimaryContainer,
      borderColor: widget.backgroundColor ?? AppColors.primary,
      hoverColor: (widget.backgroundColor ?? AppColors.primaryContainer)
          .withValues(alpha: AppConstants.opacityHigh),
    );
  }
}

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

/// 事前定義されたチップバリエーション

/// カテゴリータグ
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.category = ChipCategory.general,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final ChipCategory category;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ModernChip(
      label: label,
      onTap: onTap,
      selected: selected,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
      size: ChipSize.medium,
      style: ChipStyle.filled,
    );
  }
}

/// フィルターチップ
class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelectionChanged,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelectionChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ModernChip(
      label: label,
      icon: icon,
      selected: selected,
      onTap: () => onSelectionChanged(!selected),
      style: selected ? ChipStyle.filled : ChipStyle.outlined,
      size: ChipSize.medium,
    );
  }
}

/// 削除可能なチップ
class DeletableChip extends StatelessWidget {
  const DeletableChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onDeleted;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ModernChip(
      label: label,
      icon: icon,
      onTap: onTap,
      onDeleted: onDeleted,
      size: ChipSize.medium,
      style: ChipStyle.filled,
    );
  }
}

/// チップのカテゴリー
enum ChipCategory { general, emotion, activity, location, food }
