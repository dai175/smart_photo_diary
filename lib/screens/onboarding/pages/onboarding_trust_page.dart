import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';

/// オンボーディング: 信頼ページ
class OnboardingTrustPage extends StatelessWidget {
  const OnboardingTrustPage({super.key});

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
      // シールドアイコン
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield_outlined,
          size: 40,
          color: AppColors.success.withValues(alpha: 0.6),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      Text(
        l10n.onboardingTrustTitle,
        style: AppTypography.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingTrustSubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }
}
