import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../models/timeline_photo_group.dart';
import '../../ui/design_system/app_spacing.dart';
import 'timeline_constants.dart';

/// タイムラインのスティッキーヘッダーウィジェット
class TimelineStickyHeader extends StatelessWidget {
  final TimelinePhotoGroup group;
  final bool isFullyLocked;

  const TimelineStickyHeader({
    super.key,
    required this.group,
    required this.isFullyLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: TimelineLayoutConstants.stickyHeaderHeight,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      ),
      child: Row(
        children: [
          Text(
            group.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isFullyLocked) ...[
            const Spacer(),
            Text(
              context.l10n.timelineLockedGroupLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
