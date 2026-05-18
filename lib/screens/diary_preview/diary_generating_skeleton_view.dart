import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../ui/components/loading_shimmer.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_typography.dart';

class DiaryGeneratingSkeletonView extends StatelessWidget {
  const DiaryGeneratingSkeletonView({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateLine(date: date),
          const SizedBox(height: 12),
          const LoadingShimmer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonBar(widthFactor: 0.85, height: 22, radius: 6),
                SizedBox(height: 10),
                _SkeletonBar(widthFactor: 0.55, height: 22, radius: 6),
                SizedBox(height: 16),
                Row(
                  children: [
                    _SkeletonBar(fixedWidth: 70, height: 22, radius: 6),
                    SizedBox(width: 6),
                    _SkeletonBar(fixedWidth: 86, height: 22, radius: 6),
                    SizedBox(width: 6),
                    _SkeletonBar(fixedWidth: 58, height: 22, radius: 6),
                  ],
                ),
                SizedBox(height: 20),
                _Hairline(),
                SizedBox(height: 20),
                _SkeletonBar(height: 12, radius: 4),
                SizedBox(height: 10),
                _SkeletonBar(widthFactor: 0.96, height: 12, radius: 4),
                SizedBox(height: 10),
                _SkeletonBar(height: 12, radius: 4),
                SizedBox(height: 10),
                _SkeletonBar(widthFactor: 0.78, height: 12, radius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    this.widthFactor,
    this.fixedWidth,
    required this.height,
    required this.radius,
  });

  final double? widthFactor;
  final double? fixedWidth;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = Container(
      height: height,
      width: fixedWidth,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    return fixedWidth != null
        ? shape
        : FractionallySizedBox(
            widthFactor: widthFactor ?? 1.0,
            alignment: Alignment.centerLeft,
            child: shape,
          );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Text(
      context.l10n.formatMonthDayWithDayName(date),
      style: AppTypography.withColor(
        AppTypography.dateLabel,
        AppColors.accentMuted,
      ),
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
