import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_spacing.dart';

/// シンプルなローディング状態ウィジェット
class TimelineLoadingState extends StatelessWidget {
  const TimelineLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: AppConstants.progressIndicatorStrokeWidth,
      ),
    );
  }
}

/// 写真アクセス権限が拒否された状態ウィジェット
class TimelinePermissionDeniedState extends StatelessWidget {
  final VoidCallback? onRequestPermission;

  const TimelinePermissionDeniedState({super.key, this.onRequestPermission});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: AppConstants.emptyStateIconSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.photoPermissionMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (onRequestPermission != null)
                  TextButton(
                    onPressed: onRequestPermission,
                    child: Text(context.l10n.commonAllow),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 写真が空の状態ウィジェット
class TimelineEmptyState extends StatelessWidget {
  const TimelineEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_outlined,
                  size: AppConstants.emptyStateIconSize,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.l10n.photoNoPhotosMessage,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
