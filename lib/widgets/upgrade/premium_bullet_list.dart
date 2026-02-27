import 'package:flutter/material.dart';

import '../../constants/subscription_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';

/// Premium特典の箇条書きリスト Widget
class PremiumBulletList extends StatelessWidget {
  const PremiumBulletList({super.key});

  @override
  Widget build(BuildContext context) {
    final bullets = [
      context.l10n.premiumBulletPhotos,
      context.l10n.premiumBulletStories(
        SubscriptionConstants.premiumMonthlyAiLimit,
      ),
      context.l10n.premiumBulletStyles,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
