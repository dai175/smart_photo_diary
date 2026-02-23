import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';
import '../components/onboarding_page_layout.dart';

/// オンボーディング: 信頼ページ
class OnboardingTrustPage extends StatelessWidget {
  const OnboardingTrustPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return OnboardingPageLayout(
      children: [
        // シールドアイコン
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shield_outlined,
            size: 40,
            color: colorScheme.primary.withValues(alpha: 0.6),
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
      ],
    );
  }
}
