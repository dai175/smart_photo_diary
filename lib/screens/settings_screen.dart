import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../core/service_registration.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/component_constants.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_state_card.dart';
import '../ui/components/animated_button.dart';
import '../ui/components/buttons/button_content.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/scroll_signal.dart';
import '../utils/url_launcher_utils.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../widgets/settings/appearance_settings_section.dart';
import '../widgets/settings/diary_settings_section.dart';
import '../widgets/settings/photo_filter_settings_section.dart';
import '../widgets/settings/settings_row.dart';
import '../widgets/settings/storage_settings_section.dart';
import '../ui/components/modern_chip.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ScrollSignal? scrollSignal;

  const SettingsScreen({super.key, this.onThemeChanged, this.scrollSignal});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = SettingsController(
      logger: ServiceRegistration.get<ILoggingService>(),
    );
    _scrollController = ScrollController();
    widget.scrollSignal?.addListener(_onScrollToTop);
    _controller.loadSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    widget.scrollSignal?.removeListener(_onScrollToTop);
    super.dispose();
  }

  void _onScrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: AppConstants.defaultAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: MicroInteractions.pullToRefresh(
              onRefresh: _controller.loadSettings,
              color: AppColors.primary,
              child: ListView(
                controller: _scrollController,
                padding: AppSpacing.screenPadding,
                children: [
                  _buildHeader(),
                  if (_controller.isLoading)
                    _buildLoadingContent()
                  else if (_controller.hasSettingsLoaded)
                    _buildSettingsContent()
                  else
                    _buildSettingsLoadError(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.settingsAccountLabel.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.l10n.settingsAppBarTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
              AppConstants.loadingCenterHeightRatio,
        ),
        Center(
          child: LoadingStateCard(
            title: context.l10n.settingsLoadingTitle,
            subtitle: context.l10n.settingsLoadingSubtitle,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildPlanCard(),
        _buildSectionGroupHeader(context.l10n.settingsGroupAppearance),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: AppearanceSettingsSection(
            settingsService: _controller.settingsService!,
            logger: _controller.logger,
            selectedLocale: _controller.selectedLocale,
            onThemeChanged: widget.onThemeChanged,
            onLocaleChanged: (locale) {
              _controller.onLocaleChanged(locale);
            },
            onStateChanged: _controller.notifyStateChanged,
          ),
        ),
        _buildSectionGroupHeader(context.l10n.settingsGroupDiaryPhotos),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: Column(
            children: [
              DiarySettingsSection(
                settingsService: _controller.settingsService!,
                logger: _controller.logger,
                onStateChanged: _controller.notifyStateChanged,
                showBottomDivider: true,
              ),
              PhotoFilterSettingsSection(
                settingsService: _controller.settingsService!,
                logger: _controller.logger,
                onStateChanged: _controller.notifyStateChanged,
              ),
            ],
          ),
        ),
        _buildSectionGroupHeader(context.l10n.settingsGroupData),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: StorageSettingsSection(
            onReloadSettings: _controller.loadSettings,
          ),
        ),
        _buildSectionGroupHeader(context.l10n.settingsGroupAbout),
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: Column(
            children: [
              _buildVersionInfo(),
              _buildPrivacyPolicyInfo(),
              _buildLicenseInfo(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  Widget _buildSectionGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 24, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.sectionLabel.copyWith(
          color: AppColors.accentMuted,
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _controller.subscriptionInfo;
    final cardRadius = BorderRadius.circular(CardConstants.radiusHero);
    const cardPadding = EdgeInsets.all(18);

    if (info == null) {
      return Container(
        padding: cardPadding,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: cardRadius,
        ),
        child: Text(
          context.l10n.settingsSubscriptionSectionTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final planName = info.getLocalizedPlanDisplayName(context.l10n.localeName);
    final usageRate = info.usageStats.usageRate.clamp(0.0, 1.0);
    final used = info.usageStats.monthlyUsageCount;
    final total = info.usageStats.monthlyLimit;
    final remaining = info.usageStats.remainingCount;
    final resetDate = context.l10n.formatMonthDayLong(
      info.usageStats.nextResetDate,
    );
    final expiryDate = info.periodInfo.expiryDate != null
        ? context.l10n.formatMonthDayLong(info.periodInfo.expiryDate!)
        : null;

    const usageWarningThreshold = 0.85;

    final cardBgColor = isDark
        ? AppColors.premiumBgDark
        : (info.isPremium ? AppColors.premiumBg : AppColors.cardBg);
    final barColor = usageRate > usageWarningThreshold
        ? colorScheme.error
        : AppColors.calSelected;

    return Container(
      padding: cardPadding,
      decoration: BoxDecoration(color: cardBgColor, borderRadius: cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ModernChip(
                label: planName,
                size: ChipSize.medium,
                backgroundColor: info.isPremium
                    ? Colors.white
                    : AppColors.tagPrimaryBg,
                foregroundColor: info.isPremium
                    ? AppColors.tagAccentFg
                    : AppColors.tagPrimaryFg,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.planCardThisMonth.toUpperCase(),
            style: AppTypography.sectionLabel.copyWith(
              color: AppColors.accentMuted,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$used',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  height: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '/ $total ${context.l10n.planCardDiaryUnit}',
                style: const TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.planCardRemainingAndReset(remaining, resetDate),
            style: AppTypography.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: usageRate,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusXs),
            backgroundColor: colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
          const SizedBox(height: 14),
          if (!info.isPremium)
            AnimatedButton(
              onPressed: _showUpgradeDialog,
              width: double.infinity,
              backgroundColor: AppColors.accentDark,
              foregroundColor: Colors.white,
              shadowColor: AppColors.accentDark.withValues(alpha: 0.3),
              child: ButtonContent(text: context.l10n.settingsUpgradeToPremium),
            )
          else if (expiryDate != null)
            Text(
              context.l10n.planCardAutoRenews(expiryDate),
              style: AppTypography.caption.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }

  Future<void> _showUpgradeDialog() async {
    await UpgradeDialogUtils.showUpgradeDialog(context);
    if (!mounted) return;
    _controller.notifyStateChanged();
  }

  Widget _buildSettingsLoadError() {
    return Column(
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
              AppConstants.loadingCenterHeightRatio,
        ),
        Center(
          child: CustomCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer
                        .withValues(alpha: AppConstants.opacityXLow),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: AppSpacing.iconLg,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.l10n.commonErrorOccurred,
                  style: AppTypography.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.settingsLoadErrorSubtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return SettingsRow(
      showDivider: true,
      icon: AppIcons.settingsInfo,
      title: context.l10n.settingsVersionTitle,
      subtitle: _controller.packageInfo != null
          ? '${_controller.packageInfo!.version} (${_controller.packageInfo!.buildNumber})'
          : context.l10n.commonLoading,
    );
  }

  Widget _buildPrivacyPolicyInfo() {
    return SettingsRow(
      showDivider: true,
      icon: Icons.privacy_tip_outlined,
      title: context.l10n.commonPrivacyPolicy,
      subtitle: context.l10n.settingsPrivacyPolicySubtitle,
      onTap: () => UrlLauncherUtils.launchPrivacyPolicy(context: context),
    );
  }

  Widget _buildLicenseInfo() {
    return SettingsRow(
      icon: Icons.article_outlined,
      title: context.l10n.settingsLicenseTitle,
      subtitle: context.l10n.settingsLicenseSubtitle,
      onTap: () => showLicensePage(
        context: context,
        applicationName: context.l10n.appTitle,
        applicationVersion: _controller.packageInfo?.version ?? '1.0.0',
        applicationLegalese:
            '© ${DateTime.now().year} ${context.l10n.appTitle}',
      ),
    );
  }
}
