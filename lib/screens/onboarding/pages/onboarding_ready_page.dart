import 'package:flutter/material.dart';

import '../../../localization/localization_extensions.dart';
import '../../../ui/design_system/app_colors.dart';
import '../components/onboarding_page_scaffold.dart';

/// オンボーディング ステップ4: 準備完了
/// ビジュアル: 3×3フォトグリッド（1枚目をアクセントでハイライト）
class OnboardingReadyPage extends StatelessWidget {
  const OnboardingReadyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return OnboardingPageScaffold(
      eyebrow: l10n.onboardingStep4Eyebrow,
      headline: l10n.onboardingPermissionTitle,
      body: l10n.onboardingPermissionSubtitle,
      subnote: _Subnote(text: l10n.onboardingStep4Note),
      visual: const _PhotoGridTeaser(),
    );
  }
}

class _PhotoGridTeaser extends StatelessWidget {
  static const _assets = [
    'assets/onboarding/evening.jpg',
    'assets/onboarding/flowers.jpg',
    'assets/onboarding/sunset.jpg',
    'assets/onboarding/cat.jpg',
    'assets/onboarding/forest.jpg',
    'assets/onboarding/waterfall.jpg',
    'assets/onboarding/hill.jpg',
    'assets/onboarding/lake.jpg',
    'assets/onboarding/city.jpg',
  ];

  const _PhotoGridTeaser();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;

    return SizedBox(
      width: 280,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _assets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, i) {
          final isFirst = i == 0;
          return Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _assets[i],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: isDark
                          ? AppColors.surfaceContainerHighestDark
                          : AppColors.glyphBg,
                    ),
                  ),
                ),
              ),
              // 最初のセルにアクセントボーダーとチェックマークを表示
              if (isFirst) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Subnote extends StatelessWidget {
  final String text;

  const _Subnote({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerHighestDark
            : AppColors.glyphBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
