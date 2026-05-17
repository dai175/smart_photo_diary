import 'package:flutter/material.dart';

import '../../controllers/onboarding_controller.dart';
import '../../localization/localization_extensions.dart';
import '../../ui/components/buttons/animated_button_base.dart';
import '../../ui/design_system/app_colors.dart';
import '../home_screen.dart';
import 'components/onboarding_header.dart';
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

  String _getCtaLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (_controller.currentPage) {
      0 => l10n.onboardingPhilosophyCta,
      1 => l10n.onboardingExperienceCta,
      2 => l10n.onboardingTrustCta,
      3 =>
        _controller.isProcessing
            ? l10n.onboardingProcessing
            : l10n.onboardingPermissionCta,
      _ => l10n.onboardingPhilosophyCta,
    };
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
                OnboardingHeader(
                  step: _controller.currentPage + 1,
                  total: _controller.pageCount,
                  onSkip: _controller.isProcessing ? null : _completeOnboarding,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _controller.setCurrentPage,
                    children: const [
                      OnboardingWelcomePage(),
                      OnboardingHowItWorksPage(),
                      OnboardingPrivacyPage(),
                      OnboardingReadyPage(),
                    ],
                  ),
                ),
                _buildCta(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCta(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentLight : AppColors.accentDark;
    final isLastPage = _controller.isLastPage;
    final isProcessing = _controller.isProcessing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      child: AnimatedButton(
        width: double.infinity,
        onPressed: isProcessing
            ? null
            : isLastPage
            ? _completeOnboarding
            : () => _controller.nextPage(_pageController),
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shadowColor: accent.withValues(alpha: 0.35),
        height: 52,
        borderRadius: BorderRadius.circular(14),
        child: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getCtaLabel(context),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (isLastPage) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}
