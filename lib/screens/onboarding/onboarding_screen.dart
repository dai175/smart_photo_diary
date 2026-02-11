import 'package:flutter/material.dart';

import '../../core/service_locator.dart';
import '../../core/service_registration.dart';
import '../../localization/localization_extensions.dart';
import '../../services/interfaces/logging_service_interface.dart';
import '../../services/interfaces/photo_service_interface.dart';
import '../../services/interfaces/settings_service_interface.dart';
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
  int _currentPage = 0;
  bool _isProcessing = false;

  ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final settingsService =
          await ServiceRegistration.getAsync<ISettingsService>();
      await settingsService.setFirstLaunchCompleted();

      final photoService = ServiceRegistration.get<IPhotoService>();
      await photoService.requestPermission();

      _logger.info('オンボーディング完了', context: 'OnboardingScreen');

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    } catch (e) {
      _logger.error('オンボーディング完了エラー', error: e, context: 'OnboardingScreen');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(onThemeChanged: widget.onThemeChanged),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // スキップボタン（最後のページ以外で表示）
            if (_currentPage < 4)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: TextButton(
                    onPressed: _isProcessing ? null : _completeOnboarding,
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
              const SizedBox(height: 48),

            // ページビュー
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
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
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
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
          if (_currentPage > 0)
            SecondaryButton(
              onPressed: _isProcessing ? null : _previousPage,
              text: context.l10n.commonBack,
            )
          else
            const SizedBox(width: 100),

          if (_currentPage < 4)
            PrimaryButton(
              onPressed: _isProcessing ? null : _nextPage,
              text: context.l10n.commonNext,
            )
          else
            PrimaryButton(
              onPressed: _isProcessing ? null : _completeOnboarding,
              text: _isProcessing
                  ? context.l10n.onboardingProcessing
                  : context.l10n.onboardingStart,
            ),
        ],
      ),
    );
  }
}
