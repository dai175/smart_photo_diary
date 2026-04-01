import 'package:flutter/material.dart';

import '../design_system/app_spacing.dart';
import '../design_system/app_typography.dart';
import 'custom_card.dart';

/// ローディング状態を表示する共通カードウィジェット
///
/// スピナー + タイトル + サブタイトルのパターンを統一的に提供する。
class LoadingStateCard extends StatelessWidget {
  const LoadingStateCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.indicatorColor,
    this.additionalContent,
  });

  /// ローディングタイトル
  final String title;

  /// ローディングサブタイトル
  final String subtitle;

  /// インジケーター背景色（デフォルト: surfaceContainerHighest）
  final Color? indicatorColor;

  /// 追加コンテンツ（進捗バーなど）
  final Widget? additionalContent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor =
        indicatorColor ??
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);

    return CustomCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: effectiveColor,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            title,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (additionalContent != null) ...[
            const SizedBox(height: AppSpacing.lg),
            additionalContent!,
          ],
        ],
      ),
    );
  }
}
