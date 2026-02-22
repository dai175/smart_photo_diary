import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../controllers/onboarding_controller.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/buttons/primary_button.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../home_screen.dart';
import 'onboarding_pages.dart';

class OnboardingScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;

  const OnboardingScreen({super.key, this.onThemeChanged});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final shouldNavigate = await _controller.completeOnboarding();

    if (shouldNavigate && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    }
  }

  String _getCtaText(BuildContext context) {
    final l10n = context.l10n;
    switch (_controller.currentPage) {
      case 0:
        return l10n.onboardingPhilosophyCta;
      case 1:
        return l10n.onboardingExperienceCta;
      case 2:
        return l10n.onboardingTrustCta;
      case 3:
        return _controller.isProcessing
            ? l10n.onboardingProcessing
            : l10n.onboardingPermissionCta;
      default:
        return l10n.onboardingPhilosophyCta;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // スキップボタン（最後のページ以外で表示）
                if (!_controller.isLastPage)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: TextButton(
                        onPressed: _controller.isProcessing
                            ? null
                            : _completeOnboarding,
                        child: Text(
                          context.l10n.onboardingSkip,
                          style: AppTypography.bodySmall.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: AppSpacing.xxxl),

                // ページビュー
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _controller.setCurrentPage,
                    children: const [
                      OnboardingPhilosophyPage(),
                      OnboardingExperiencePage(),
                      OnboardingTrustPage(),
                      OnboardingPermissionPage(),
                    ],
                  ),
                ),

                // ページインジケーター
                _buildPageIndicator(),

                // CTAボタン
                _buildCtaButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedContainer(
            duration: AppConstants.standardTransitionDuration,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _controller.currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCtaButton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          onPressed: _controller.isProcessing
              ? null
              : _controller.isLastPage
              ? _completeOnboarding
              : () => _controller.nextPage(_pageController),
          text: _getCtaText(context),
        ),
      ),
    );
  }
}
