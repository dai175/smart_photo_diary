import 'package:flutter/material.dart';
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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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
                          width: 1.5,
                        )
                      : null,
                  boxShadow: widget.style == ChipStyle.elevated
                      ? [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: _isHovered ? 4 : 2,
                            offset: Offset(0, _isHovered ? 2 : 1),
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
                          color: colorData.foregroundColor.withValues(alpha: 0.7),
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
      return colorData.backgroundColor.withValues(alpha: 0.3);
    }
    
    if (widget.style == ChipStyle.outlined) {
      return _isHovered ? colorData.backgroundColor.withValues(alpha: 0.1) : Colors.transparent;
    }
    
    if (_isHovered) {
      return colorData.hoverColor;
    }
    
    return colorData.backgroundColor;
  }

  _ChipSizeData _getChipSizeData(ChipSize size) {
    switch (size) {
      case ChipSize.small:
        return _ChipSizeData(
          height: 24,
          horizontalPadding: AppSpacing.sm,
          verticalPadding: AppSpacing.xxs,
          iconSize: 14,
          spacing: 4,
          textStyle: AppTypography.labelSmall,
        );
      case ChipSize.medium:
        return _ChipSizeData(
          height: 32,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.xs,
          iconSize: 16,
          spacing: AppSpacing.xs,
          textStyle: AppTypography.labelMedium,
        );
      case ChipSize.large:
        return _ChipSizeData(
          height: 40,
          horizontalPadding: AppSpacing.lg,
          verticalPadding: AppSpacing.sm,
          iconSize: 18,
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
        hoverColor: (widget.backgroundColor ?? AppColors.primary).withValues(alpha: 0.8),
      );
    }

    // final theme = Theme.of(context); // 将来的に使用予定
    return _ChipColorData(
      backgroundColor: widget.backgroundColor ?? AppColors.primaryContainer,
      foregroundColor: widget.foregroundColor ?? AppColors.onPrimaryContainer,
      borderColor: widget.backgroundColor ?? AppColors.primary,
      hoverColor: (widget.backgroundColor ?? AppColors.primaryContainer).withValues(alpha: 0.8),
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
    final colors = _getCategoryColors(category);
    
    return ModernChip(
      label: label,
      onTap: onTap,
      selected: selected,
      backgroundColor: colors.backgroundColor,
      foregroundColor: colors.foregroundColor,
      size: ChipSize.medium,
      style: ChipStyle.filled,
    );
  }

  _CategoryColors _getCategoryColors(ChipCategory category) {
    switch (category) {
      case ChipCategory.general:
        return const _CategoryColors(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
        );
      case ChipCategory.emotion:
        return const _CategoryColors(
          backgroundColor: AppColors.secondaryContainer,
          foregroundColor: AppColors.onSecondaryContainer,
        );
      case ChipCategory.activity:
        return _CategoryColors(
          backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
          foregroundColor: AppColors.secondaryDark,
        );
      case ChipCategory.location:
        return _CategoryColors(
          backgroundColor: AppColors.success.withValues(alpha: 0.2),
          foregroundColor: AppColors.success,
        );
      case ChipCategory.food:
        return _CategoryColors(
          backgroundColor: AppColors.warning.withValues(alpha: 0.2),
          foregroundColor: AppColors.warning,
        );
    }
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

/// カテゴリー色データ
class _CategoryColors {
  const _CategoryColors({
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;
}