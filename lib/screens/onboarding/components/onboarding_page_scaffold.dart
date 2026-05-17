import 'package:flutter/material.dart';

import '../../../ui/design_system/app_colors.dart';

/// オンボーディング各ページの共通スキャフォールド:
/// ビジュアルエリア(minHeight: 280) + アイブロウ + 見出し + 本文 + サブノート
class OnboardingPageScaffold extends StatelessWidget {
  final Widget visual;
  final String eyebrow;
  final String headline;
  final String? body;
  final Widget? subnote;

  const OnboardingPageScaffold({
    super.key,
    required this.visual,
    required this.eyebrow,
    required this.headline,
    this.body,
    this.subnote,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ビジュアルエリア — minHeight で全ページを揃えつつ、背の高いビジュアルは伸長可
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 280),
            child: Center(child: visual),
          ),
          const SizedBox(height: 32),
          Text(
            eyebrow.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            headline,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 1.12,
              letterSpacing: -0.5,
              color: cs.onSurface,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 14),
            Text(
              body!,
              style: TextStyle(
                fontSize: 15,
                height: 1.55,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (subnote != null) ...[const SizedBox(height: 12), subnote!],
        ],
      ),
    );
  }
}
