import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';
import '../components/onboarding_feature_step.dart';

/// オンボーディング: SNS共有紹介ページ
class OnboardingSharePage extends StatelessWidget {
  const OnboardingSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: isPortrait
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: _buildContent(context),
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context) {
    final l10n = context.l10n;

    return [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.share_rounded, size: 50, color: AppColors.info),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingShareTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      OnboardingFeatureStep(
        icon: Icons.crop_rounded,
        color: AppColors.primary,
        title: l10n.onboardingShareFormatTitle,
        description: l10n.onboardingShareFormatDescription,
      ),
      const SizedBox(height: AppSpacing.md),
      OnboardingFeatureStep(
        icon: Icons.grid_view_rounded,
        color: AppColors.info,
        title: l10n.onboardingShareMultipleTitle,
        description: l10n.onboardingShareMultipleDescription,
      ),
    ];
  }
}
