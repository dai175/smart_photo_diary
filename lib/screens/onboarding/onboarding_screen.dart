import 'package:flutter/material.dart';

import '../../controllers/onboarding_controller.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/animated_button.dart';
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
                          style: AppTypography.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.primary,
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
                      OnboardingWelcomePage(),
                      OnboardingFeaturesPage(),
                      OnboardingSharePage(),
                      OnboardingPlansPage(),
                      OnboardingPermissionPage(),
                    ],
                  ),
                ),

                // ページインジケーター
                _buildPageIndicator(),

                // ナビゲーションボタン
                _buildNavigationButtons(),
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
        children: List.generate(5, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            width: _controller.currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _controller.currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXs),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!_controller.isFirstPage)
            SecondaryButton(
              onPressed: _controller.isProcessing
                  ? null
                  : () => _controller.previousPage(_pageController),
              text: context.l10n.commonBack,
            )
          else
            const SizedBox(width: 100),

          if (!_controller.isLastPage)
            PrimaryButton(
              onPressed: _controller.isProcessing
                  ? null
                  : () => _controller.nextPage(_pageController),
              text: context.l10n.commonNext,
            )
          else
            PrimaryButton(
              onPressed: _controller.isProcessing ? null : _completeOnboarding,
              text: _controller.isProcessing
                  ? context.l10n.onboardingProcessing
                  : context.l10n.onboardingStart,
            ),
        ],
      ),
    );
  }
}
