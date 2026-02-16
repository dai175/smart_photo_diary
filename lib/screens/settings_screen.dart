import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_icons.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/scroll_signal.dart';
import '../widgets/settings/appearance_settings_section.dart';
import '../widgets/settings/diary_settings_section.dart';
import '../widgets/settings/settings_row.dart';
import '../widgets/settings/storage_settings_section.dart';
import '../widgets/settings/subscription_settings_section.dart';
import '../utils/url_launcher_utils.dart';

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
    _controller = SettingsController();
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
          appBar: AppBar(
            title: Text(context.l10n.settingsAppBarTitle),
            centerTitle: false,
          ),
          body: MicroInteractions.pullToRefresh(
            onRefresh: _controller.loadSettings,
            color: AppColors.primary,
            child: ListView(
              controller: _scrollController,
              padding: AppSpacing.screenPadding,
              children: _controller.isLoading
                  ? [_buildLoadingContent()]
                  : _controller.hasSettingsLoaded
                  ? [_buildSettingsContent()]
                  : [_buildSettingsLoadError()],
            ),
          ),
        );
      },
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
          child: FadeInWidget(
            child: CustomCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: AppConstants.opacityXLow),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    context.l10n.settingsLoadingTitle,
                    style: AppTypography.titleLarge.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.settingsLoadingSubtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsContent() {
    return Column(
      children: [
        CustomCard(
          elevation: AppSpacing.elevationMd,
          child: Column(
            children: [
              FadeInWidget(
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
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 50),
                child: DiarySettingsSection(
                  settingsService: _controller.settingsService!,
                  logger: _controller.logger,
                  onStateChanged: _controller.notifyStateChanged,
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 75),
                child: SubscriptionSettingsSection(
                  subscriptionInfo: _controller.subscriptionInfo,
                  onStateChanged: _controller.notifyStateChanged,
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 125),
                child: StorageSettingsSection(
                  storageInfo: _controller.storageInfo,
                  onReloadSettings: _controller.loadSettings,
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildVersionInfo(),
              ),
              SlideInWidget(
                delay: const Duration(milliseconds: 225),
                child: _buildLicenseInfo(),
              ),
              SlideInWidget(
                delay: const Duration(milliseconds: 250),
                child: _buildPrivacyPolicyInfo(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
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
          child: FadeInWidget(
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
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: AppColors.outline.withValues(alpha: 0.1),
    );
  }

  Widget _buildVersionInfo() {
    return SettingsRow(
      icon: AppIcons.settingsInfo,
      title: context.l10n.settingsVersionTitle,
      subtitle: _controller.packageInfo != null
          ? '${_controller.packageInfo!.version} (${_controller.packageInfo!.buildNumber})'
          : context.l10n.commonLoading,
    );
  }

  Widget _buildPrivacyPolicyInfo() {
    return SettingsRow(
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
