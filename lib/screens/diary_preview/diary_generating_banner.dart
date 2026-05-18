import 'package:flutter/material.dart';

import '../../localization/localization_extensions.dart';
import '../../models/writing_prompt.dart';
import '../../ui/design_system/app_colors.dart';
import '../../utils/prompt_category_utils.dart';

class DiaryGeneratingBanner extends StatelessWidget {
  const DiaryGeneratingBanner({
    super.key,
    required this.photoCount,
    required this.selectedPrompt,
    required this.statusText,
  });

  final int photoCount;
  final WritingPrompt? selectedPrompt;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    final bg = isDark
        ? AppColors.accentLight.withValues(alpha: 0.14)
        : AppColors.accent.withValues(alpha: 0.10);
    final border = isDark
        ? AppColors.accentLight.withValues(alpha: 0.22)
        : AppColors.accent.withValues(alpha: 0.20);

    final l10n = context.l10n;
    final caption = selectedPrompt == null
        ? l10n.diaryGenerationCaptionNoPrompt(photoCount)
        : l10n.diaryGenerationCaptionWithPrompt(
            photoCount,
            PromptCategoryUtils.getCategoryDisplayName(
              selectedPrompt!.category,
              locale: Localizations.localeOf(context),
            ).toLowerCase(),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 0.5),
          ),
          child: Row(
            children: [
              _PulsingDisc(color: accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        height: 1.25,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 0.2,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const _IndeterminateBar(),
      ],
    );
  }
}

class _PulsingDisc extends StatefulWidget {
  const _PulsingDisc({required this.color});

  final Color color;

  @override
  State<_PulsingDisc> createState() => _PulsingDiscState();
}

class _PulsingDiscState extends State<_PulsingDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);
  late final Animation<double> _opacity = Tween<double>(
    begin: 0.6,
    end: 1.0,
  ).animate(_ac);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IndeterminateBar extends StatelessWidget {
  const _IndeterminateBar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    return LinearProgressIndicator(
      minHeight: 4,
      borderRadius: BorderRadius.circular(999),
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06),
      valueColor: AlwaysStoppedAnimation<Color>(accent),
    );
  }
}
