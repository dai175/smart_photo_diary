import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/interfaces/photo_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/animated_button.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/subscription_constants.dart';
import '../localization/localization_extensions.dart';
import 'home_screen.dart';

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

  // LoggingServiceアクセス用getter
  LoggingService get _logger => serviceLocator.get<LoggingService>();

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
      // 初回起動フラグを更新
      final settingsService = await SettingsService.getInstance();
      await settingsService.setFirstLaunchCompleted();

      // 写真アクセス権限をリクエスト
      final photoService = ServiceRegistration.get<IPhotoService>();
      await photoService.requestPermission();

      _logger.info('オンボーディング完了', context: 'OnboardingScreen');

      if (!mounted) return;

      // ホーム画面へ遷移
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomeScreen(onThemeChanged: widget.onThemeChanged),
        ),
      );
    } catch (e) {
      _logger.error('オンボーディング完了エラー', error: e, context: 'OnboardingScreen');

      // エラーが発生してもホーム画面へ遷移
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
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildSharePage(),
                  _buildPlansPage(),
                  _buildPermissionPage(),
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

  Widget _buildWelcomePage() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildWelcomeContent(),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildWelcomeContent()),
      );
    }
  }

  List<Widget> _buildWelcomeContent() {
    final l10n = context.l10n;

    return [
      // アプリアイコン
      MicroInteractions.scaleTransition(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/app_icon.png',
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      Text(
        l10n.onboardingWelcomeTitle,
        style: AppTypography.headlineMedium.copyWith(
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingWelcomeSubtitle,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _buildFeaturesPage() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildFeaturesContent(),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildFeaturesContent()),
      );
    }
  }

  List<Widget> _buildFeaturesContent() {
    final l10n = context.l10n;

    return [
      // ステップアイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_awesome_motion_rounded,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingThreeStepsTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      // ステップ1
      _buildFeatureStep(
        icon: Icons.photo_camera_rounded,
        color: AppColors.info,
        title: l10n.onboardingStepTitle(1),
        description: l10n.onboardingStep1Description,
      ),
      const SizedBox(height: AppSpacing.lg),

      // ステップ2
      _buildFeatureStep(
        icon: Icons.auto_awesome_rounded,
        color: AppColors.primary,
        title: l10n.onboardingStepTitle(2),
        description: l10n.onboardingStep2Description,
      ),
      const SizedBox(height: AppSpacing.lg),

      // ステップ3
      _buildFeatureStep(
        icon: Icons.edit_note_rounded,
        color: AppColors.success,
        title: l10n.onboardingStepTitle(3),
        description: l10n.onboardingStep3Description,
      ),
    ];
  }

  Widget _buildPlansPage() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildPlansContent(),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildPlansContent()),
      );
    }
  }

  // SNS共有の紹介ページ（3枚目）
  Widget _buildSharePage() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildShareContent(),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildShareContent()),
      );
    }
  }

  List<Widget> _buildShareContent() {
    final l10n = context.l10n;

    return [
      // 共有アイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.share_rounded, size: 50, color: AppColors.info),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingShareTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      _buildFeatureStep(
        icon: Icons.crop_rounded,
        color: AppColors.primary,
        title: l10n.onboardingShareFormatTitle,
        description: l10n.onboardingShareFormatDescription,
      ),
      const SizedBox(height: AppSpacing.md),
      _buildFeatureStep(
        icon: Icons.grid_view_rounded,
        color: AppColors.info,
        title: l10n.onboardingShareMultipleTitle,
        description: l10n.onboardingShareMultipleDescription,
      ),
    ];
  }

  List<Widget> _buildPlansContent() {
    final l10n = context.l10n;

    return [
      // プランアイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.workspace_premium_rounded,
          size: 50,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPlansTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),

      // Basicプラン
      _buildPlanCard(
        title: 'Basic',
        subtitle: l10n.onboardingPlanBasicSubtitle,
        icon: Icons.photo_rounded,
        color: AppColors.secondary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.basicMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeatureRecentPhotos,
          l10n.onboardingPlanFeatureBasicPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      // Premiumプラン
      _buildPlanCard(
        title: 'Premium',
        subtitle: context.l10n.pricingPerMonthShort(
          SubscriptionConstants.formatPriceForPlan(
            SubscriptionConstants.premiumMonthlyPlanId,
            context.l10n.localeName,
          ),
        ),
        icon: Icons.star_rounded,
        color: AppColors.primary,
        features: [
          l10n.onboardingPlanFeatureMonthlyLimit(
            SubscriptionConstants.premiumMonthlyAiLimit,
          ),
          l10n.onboardingPlanFeaturePastDays(
            SubscriptionConstants.subscriptionYearDays,
          ),
          l10n.onboardingPlanFeatureRichPrompts,
        ],
      ),
      const SizedBox(height: AppSpacing.md),

      Text(
        l10n.onboardingPlanStartFree,
        style: AppTypography.titleMedium.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _buildPermissionPage() {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _buildPermissionContent(),
        ),
      );
    } else {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(children: _buildPermissionContent()),
      );
    }
  }

  List<Widget> _buildPermissionContent() {
    final l10n = context.l10n;

    return [
      // 権限アイコン
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.security_rounded, size: 50, color: AppColors.info),
      ),
      const SizedBox(height: AppSpacing.xl),

      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          l10n.onboardingPermissionTitle,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.onboardingPermissionDescription,
        style: AppTypography.bodyLarge.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpacing.lg),

      // プライバシー保護の強調
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_rounded,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.onboardingPrivacyTitle,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.onboardingPrivacyDescription,
              style: AppTypography.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.4,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];
  }

  Widget _buildFeatureStep({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: color,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          // 戻るボタン（最初のページ以外で表示）
          if (_currentPage > 0)
            SecondaryButton(
              onPressed: _isProcessing ? null : _previousPage,
              text: context.l10n.commonBack,
            )
          else
            const SizedBox(width: 100),

          // 次へ/始めるボタン
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
