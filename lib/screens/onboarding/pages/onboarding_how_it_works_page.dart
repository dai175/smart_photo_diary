import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/components/modern_chip.dart';
import '../components/onboarding_page_scaffold.dart';

/// オンボーディング ステップ2: 使い方
/// ビジュアル: Hero再設計済みのサンプル日記カード（3:2写真 + アクセント日付 + 3色チップ）
class OnboardingHowItWorksPage extends StatelessWidget {
  const OnboardingHowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingPageScaffold(
      eyebrow: l10n.onboardingStep2Eyebrow,
      headline: l10n.onboardingExperienceTitle,
      body: l10n.onboardingExperienceSubtitle,
      visual: const _MiniHeroCard(),
    );
  }
}

class _MiniHeroCard extends StatelessWidget {
  const _MiniHeroCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceContainerDark : cs.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isDark ? AppSpacing.cardShadowDark : AppSpacing.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 写真エリア（3:2）
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/onboarding/cat.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: isDark
                          ? AppColors.surfaceContainerHighestDark
                          : AppColors.glyphBg,
                    ),
                  ),
                  // 「サンプル」バッジ
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.onboardingExampleEntryPill.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: AppColors.accentDark,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // テキストエリア
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // アクセントカラーの日付
                  Text(
                    l10n.onboardingSampleDate.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // タイトル
                  Text(
                    l10n.onboardingSampleTitle,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.22,
                      letterSpacing: -0.2,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ModernChip.tonedTag(l10n.onboardingSampleTag1, index: 0),
                      ModernChip.tonedTag(l10n.onboardingSampleTag2, index: 1),
                      ModernChip.tonedTag(l10n.onboardingSampleTag3, index: 2),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
