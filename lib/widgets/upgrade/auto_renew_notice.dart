import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// 自動更新に関する注意事項 Widget（Apple ガイドライン 3.1.2 準拠）
class AutoRenewNotice extends StatelessWidget {
  const AutoRenewNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: AppSpacing.iconXs,
                color: AppColors.info,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.settingsSubscriptionAutoRenewTitle,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.settingsSubscriptionAutoRenewDescription,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
