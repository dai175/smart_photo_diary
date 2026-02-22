import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_spacing.dart';
import '../../../ui/design_system/app_typography.dart';

/// オンボーディング: 体験ページ
class OnboardingExperiencePage extends StatelessWidget {
  const OnboardingExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(children: _buildContent(context)),
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
      // 日記サンプル（ウィジェット）
      _buildDiaryCard(context),
      const SizedBox(height: AppSpacing.xl),

      Text(
        l10n.onboardingExperienceTitle,
        style: AppTypography.headlineSmall,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingExperienceSubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _buildDiaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.78;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.asset(
                'assets/images/onboarding_sample_photo.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                  );
                },
              ),
            ),

            // テキスト部分
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日付
                  Text(
                    'February 22, 2026',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // タイトル
                  Text(
                    'A Quiet Afternoon',
                    style: AppTypography.titleMedium.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // 本文
                  Text(
                    'He curled up in the fading light,\n'
                    'breathing softly beside me.\n'
                    'The room grew still,\n'
                    'and for a while,\n'
                    'nothing else seemed to matter.',
                    style: AppTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
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
