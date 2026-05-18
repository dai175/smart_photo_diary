import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../core/service_registration.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/custom_card.dart';
import '../ui/components/loading_state_card.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/scroll_signal.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../widgets/settings/about_settings_section.dart';
import '../widgets/settings/appearance_settings_section.dart';
import '../widgets/settings/diary_settings_section.dart';
import '../widgets/settings/photo_filter_settings_section.dart';
import '../widgets/settings/plan_status_card.dart';
import '../widgets/settings/storage_settings_section.dart';

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
        PlanStatusCard(
          info: _controller.subscriptionInfo,
          onUpgradePressed: _showUpgradeDialog,
        ),
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
          child: AboutSettingsSection(packageInfo: _controller.packageInfo),
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
}
