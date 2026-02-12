import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';
import '../components/onboarding_feature_step.dart';

/// オンボーディング: 機能紹介ページ
class OnboardingFeaturesPage extends StatelessWidget {
  const OnboardingFeaturesPage({super.key});

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
      // ステップアイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.auto_awesome_motion_rounded,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingThreeStepsTitle,
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
        icon: Icons.photo_camera_rounded,
        color: AppColors.info,
        title: l10n.onboardingStepTitle(1),
        description: l10n.onboardingStep1Description,
      ),
      const SizedBox(height: AppSpacing.lg),

      OnboardingFeatureStep(
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
        title: l10n.onboardingStepTitle(2),
        description: l10n.onboardingStep2Description,
      ),
      const SizedBox(height: AppSpacing.lg),

      OnboardingFeatureStep(
        icon: Icons.edit_note_rounded,
        color: AppColors.success,
        title: l10n.onboardingStepTitle(3),
        description: l10n.onboardingStep3Description,
      ),
    ];
  }
}
