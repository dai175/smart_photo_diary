import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../widgets/settings/settings_row.dart';
import '../components/onboarding_page_scaffold.dart';

/// オンボーディング ステップ3: プライバシー
/// ビジュアル: 3つのプライバシー約束を SettingsRow で構成したカード
class OnboardingPrivacyPage extends StatelessWidget {
  const OnboardingPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingPageScaffold(
      eyebrow: l10n.onboardingStep3Eyebrow,
      headline: l10n.onboardingTrustTitle,
      visual: const _PrivacyGroup(),
    );
  }
}

class _PrivacyGroup extends StatelessWidget {
  const _PrivacyGroup();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceContainerDark : cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsRow(
            icon: Icons.lock_outline_rounded,
            title: l10n.onboardingPrivacyOnDeviceTitle,
            subtitle: l10n.onboardingPrivacyOnDeviceSubtitle,
            showDivider: true,
          ),
          SettingsRow(
            icon: Icons.shield_outlined,
            title: l10n.onboardingPrivacyNoAccountTitle,
            subtitle: l10n.onboardingPrivacyNoAccountSubtitle,
            showDivider: true,
          ),
          SettingsRow(
            icon: Icons.verified_outlined,
            title: l10n.onboardingPrivacyYouOwnTitle,
            subtitle: l10n.onboardingPrivacyYouOwnSubtitle,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
