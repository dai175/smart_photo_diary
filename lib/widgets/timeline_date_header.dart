import 'package:flutter/material.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../models/timeline_photo_group.dart';

/// タイムライン用の日付ヘッダーデリゲート
class TimelineDateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TimelinePhotoGroup group;
  final double height;

  const TimelineDateHeaderDelegate({required this.group, this.height = 48.0});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return TimelineDateHeader(
      group: group,
      shrinkOffset: shrinkOffset,
      overlapsContent: overlapsContent,
    );
  }

  @override
  bool shouldRebuild(TimelineDateHeaderDelegate oldDelegate) {
    return oldDelegate.group != group;
  }
}

/// タイムライン用の日付ヘッダーウィジェット
class TimelineDateHeader extends StatelessWidget {
  final TimelinePhotoGroup group;
  final double shrinkOffset;
  final bool overlapsContent;

  const TimelineDateHeader({
    super.key,
    required this.group,
    required this.shrinkOffset,
    required this.overlapsContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48.0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          group.displayName,
          style: AppTypography.titleMedium.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: _getFontWeight(),
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  /// グループタイプに応じたフォント重みを取得
  FontWeight _getFontWeight() {
    switch (group.type) {
      case TimelineGroupType.today:
      case TimelineGroupType.yesterday:
        return FontWeight.w600; // 今日・昨日は太字
      case TimelineGroupType.monthly:
        return FontWeight.w500; // 月単位は中太字
    }
  }
}
