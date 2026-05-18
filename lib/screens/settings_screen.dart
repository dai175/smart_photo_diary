import 'package:flutter/material.dart';
import '../controllers/settings_controller.dart';
import '../core/service_registration.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/animations/micro_interactions.dart';
import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../controllers/scroll_signal.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../widgets/settings/settings_content_body.dart';
import '../widgets/settings/settings_load_error_view.dart';
import '../widgets/settings/settings_loading_view.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ScrollSignal? scrollSignal;
  final ILoggingService? logger;

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.scrollSignal,
    this.logger,
  });

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
      logger: widget.logger ?? ServiceRegistration.get<ILoggingService>(),
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
                  const _SettingsHeader(),
                  if (_controller.isLoading)
                    const SettingsLoadingView()
                  else if (_controller.hasSettingsLoaded)
                    SettingsContentBody(
                      settingsService: _controller.settingsService,
                      logger: _controller.logger,
                      selectedLocale: _controller.selectedLocale,
                      subscriptionInfo: _controller.subscriptionInfo,
                      packageInfo: _controller.packageInfo,
                      onThemeChanged: widget.onThemeChanged,
                      onLocaleChanged: _controller.onLocaleChanged,
                      onStateChanged: _controller.notifyStateChanged,
                      onUpgradePressed: _showUpgradeDialog,
                      onReloadSettings: _controller.loadSettings,
                    )
                  else
                    const SettingsLoadErrorView(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showUpgradeDialog() async {
    await UpgradeDialogUtils.showUpgradeDialog(context);
    if (!mounted) return;
    _controller.notifyStateChanged();
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
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
}
