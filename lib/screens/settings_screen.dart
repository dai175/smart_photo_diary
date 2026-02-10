import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart'; // StorageInfoクラス用
import '../services/interfaces/storage_service_interface.dart';
import '../core/service_registration.dart';
import '../core/service_locator.dart';
import '../services/logging_service.dart';
import '../models/subscription_info_v2.dart';
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
import '../widgets/settings/settings_row.dart';
import '../widgets/settings/storage_settings_section.dart';
import '../widgets/settings/subscription_settings_section.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  final ScrollSignal? scrollSignal;

  const SettingsScreen({super.key, this.onThemeChanged, this.scrollSignal});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final LoggingService _logger;
  late SettingsService _settingsService;
  late final ScrollController _scrollController;
  PackageInfo? _packageInfo;
  StorageInfo? _storageInfo;
  SubscriptionInfoV2? _subscriptionInfo;
  bool _isLoading = true;
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _logger = serviceLocator.get<LoggingService>();
    _scrollController = ScrollController();
    widget.scrollSignal?.addListener(_onScrollToTop);
    _loadSettings();
  }

  @override
  void dispose() {
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

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _settingsService = await ServiceRegistration.getAsync<SettingsService>();
      _packageInfo = await PackageInfo.fromPlatform();
      final storageService = ServiceRegistration.get<IStorageService>();
      final storageResult = await storageService.getStorageInfoResult();
      if (storageResult.isSuccess) {
        _storageInfo = storageResult.value;
      } else {
        _logger.error(
          'Failed to fetch storage info',
          error: storageResult.error,
          context: 'SettingsScreen',
        );
      }

      _selectedLocale = _settingsService.locale;

      final subscriptionResult = await _settingsService.getSubscriptionInfoV2();
      if (subscriptionResult.isSuccess) {
        _subscriptionInfo = subscriptionResult.value;
      } else {
        _logger.error(
          'Failed to fetch subscription info',
          error: subscriptionResult.error,
          context: 'SettingsScreen',
        );
      }
    } catch (e) {
      _logger.error(
        'Failed to load settings',
        error: e,
        context: 'SettingsScreen',
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.settingsAppBarTitle),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        elevation: 2,
      ),
      body: MicroInteractions.pullToRefresh(
        onRefresh: _loadSettings,
        color: AppColors.primary,
        child: ListView(
          controller: _scrollController,
          padding: AppSpacing.screenPadding,
          children: _isLoading
              ? [_buildLoadingContent()]
              : [_buildSettingsContent()],
        ),
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
          child: FadeInWidget(
            child: CustomCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(
                        alpha: AppConstants.opacityXLow,
                      ),
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
                  settingsService: _settingsService,
                  logger: _logger,
                  selectedLocale: _selectedLocale,
                  onThemeChanged: widget.onThemeChanged,
                  onLocaleChanged: (locale) {
                    setState(() {
                      _selectedLocale = locale;
                    });
                  },
                  onStateChanged: () => setState(() {}),
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 50),
                child: SubscriptionSettingsSection(
                  subscriptionInfo: _subscriptionInfo,
                  onStateChanged: () => setState(() {}),
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: StorageSettingsSection(
                  storageInfo: _storageInfo,
                  onReloadSettings: _loadSettings,
                ),
              ),
              _buildDivider(),
              SlideInWidget(
                delay: const Duration(milliseconds: 175),
                child: _buildVersionInfo(),
              ),
              SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildLicenseInfo(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
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
      iconColor: AppColors.primary,
      title: context.l10n.settingsVersionTitle,
      subtitle: _packageInfo != null
          ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
          : context.l10n.commonLoading,
    );
  }

  Widget _buildLicenseInfo() {
    return SettingsRow(
      icon: Icons.article_outlined,
      iconColor: Theme.of(context).colorScheme.secondary,
      title: context.l10n.settingsLicenseTitle,
      subtitle: context.l10n.settingsLicenseSubtitle,
      onTap: () => showLicensePage(
        context: context,
        applicationName: context.l10n.appTitle,
        applicationVersion: _packageInfo?.version ?? '1.0.0',
        applicationLegalese:
            '© ${DateTime.now().year} ${context.l10n.appTitle}',
      ),
    );
  }
}
