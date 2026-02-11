import 'package:flutter/material.dart';

import '../../constants/subscription_constants.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/animations/micro_interactions.dart';
import '../../ui/design_system/app_colors.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../utils/dynamic_pricing_utils.dart';

/// オンボーディング: ウェルカムページ
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

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
      // アプリアイコン
      MicroInteractions.scaleTransition(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      Text(
        l10n.onboardingWelcomeTitle,
        style: AppTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingWelcomeSubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

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
        child: Icon(
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

/// オンボーディング: プラン紹介ページ
class OnboardingPlansPage extends StatelessWidget {
  const OnboardingPlansPage({super.key});

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
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium_rounded,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPlansTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      // Basicプラン
      OnboardingPlanCard(
        title: 'Basic',
        subtitle: l10n.onboardingPlanBasicSubtitle,
        icon: Icons.photo_rounded,
        color: AppColors.secondary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.basicMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeatureRecentPhotos,
          l10n.onboardingPlanFeatureBasicPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // Premiumプラン（動的価格対応）
      OnboardingDynamicPlanCard(
        title: 'Premium',
        planId: SubscriptionConstants.premiumMonthlyPlanId,
        formatter: (price) => context.l10n.pricingPerMonthShort(price),
        icon: Icons.star_rounded,
        color: AppColors.primary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.premiumMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeaturePastDays(
            SubscriptionConstants.subscriptionYearDays,
          ),
          l10n.onboardingPlanFeatureRichPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      Text(
        l10n.onboardingPlanStartFree,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

/// オンボーディング: 権限リクエストページ
class OnboardingPermissionPage extends StatelessWidget {
  const OnboardingPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildContent(context),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildContent(context)),
      );
    }
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
        child: Icon(Icons.security_rounded, size: 50, color: AppColors.info),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPermissionTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingPermissionDescription,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      // プライバシー保護の強調
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.onboardingPrivacyTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.onboardingPrivacyDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
  }
}

// ---------------------------------------------------------------------------
// 共有コンポーネント
// ---------------------------------------------------------------------------

/// 機能紹介ステップカード
class OnboardingFeatureStep extends StatelessWidget {
  const OnboardingFeatureStep({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// プランカード
class OnboardingPlanCard extends StatelessWidget {
  const OnboardingPlanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.features,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 動的価格対応のプランカード
class OnboardingDynamicPlanCard extends StatelessWidget {
  const OnboardingDynamicPlanCard({
    super.key,
    required this.title,
    required this.planId,
    required this.formatter,
    required this.icon,
    required this.color,
    required this.features,
  });

  final String title;
  final String planId;
  final String Function(String) formatter;
  final IconData icon;
  final Color color;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  DynamicPriceText(
                    planId: planId,
                    locale: context.l10n.localeName,
                    formatter: formatter,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    loadingWidget: SizedBox(
                      width: 80,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: color),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
