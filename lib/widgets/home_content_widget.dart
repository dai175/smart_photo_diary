import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/photo_selection_controller.dart';
import '../controllers/scroll_signal.dart';
import '../models/timeline_callbacks.dart';
import '../models/plans/plan.dart';
import '../widgets/timeline_fab_integration.dart';
import '../ui/design_system/app_colors.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/animations/micro_interactions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import '../constants/subscription_constants.dart';

class HomeContentWidget extends StatefulWidget {
  final PhotoSelectionController photoController;
  final TimelineCallbacks callbacks;
  final Function(String) onDiaryTap;
  final Future<void> Function()? onRefresh;
  final ScrollSignal? scrollSignal;
  final ISubscriptionService? subscriptionService;

  const HomeContentWidget({
    super.key,
    required this.photoController,
    this.callbacks = const TimelineCallbacks(),
    required this.onDiaryTap,
    this.onRefresh,
    this.scrollSignal,
    this.subscriptionService,
  });

  @override
  State<HomeContentWidget> createState() => _HomeContentWidgetState();
}

class _HomeContentWidgetState extends State<HomeContentWidget> {
  late final ISubscriptionService _subscriptionService;
  int? _remainingGenerations;
  Plan? _cachedPlan;

  @override
  void initState() {
    super.initState();
    _subscriptionService =
        widget.subscriptionService ??
        ServiceRegistration.get<ISubscriptionService>();
    _loadUsageSummary();
  }

  Future<void> _loadUsageSummary() async {
    final remainingFuture = _subscriptionService.getRemainingGenerations();
    final planFuture = _subscriptionService.getCurrentPlanClass();
    final remainingResult = await remainingFuture;
    final planResult = await planFuture;
    if (mounted) {
      setState(() {
        _remainingGenerations = remainingResult.isSuccess
            ? remainingResult.value
            : null;
        _cachedPlan = planResult.isSuccess ? planResult.value : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(context),
      body: widget.onRefresh != null
          ? MicroInteractions.pullToRefresh(
              onRefresh: widget.onRefresh!,
              color: Theme.of(context).colorScheme.primary,
              child: _buildMainContent(context),
            )
          : _buildMainContent(context),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(84),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderDateLabel(context),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.timelineToday,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              _buildUsagePill(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderDateLabel(BuildContext context) {
    final label = DateFormat(
      'EEEE · MMM d',
      context.l10n.localeName,
    ).format(DateTime.now()).toUpperCase();
    return Text(
      label,
      style: AppTypography.dateLabel.copyWith(color: AppColors.accentMuted),
    );
  }

  Widget _buildUsagePill(BuildContext context) {
    final remaining = _remainingGenerations;
    final limit = _cachedPlan?.monthlyAiGenerationLimit;
    final label = (remaining != null && limit != null)
        ? '$remaining / $limit'
        : '—';

    return Material(
      color: AppColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: () => _showUsageStatus(context),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: AppSpacing.iconXxs,
                color: AppColors.accentMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: _buildTimelineSection(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    return TimelineFABIntegration(
      controller: widget.photoController,
      callbacks: widget.callbacks,
      scrollSignal: widget.scrollSignal,
    );
  }

  Future<void> _showUsageStatus(BuildContext context) async {
    try {
      // 常に最新のプラン情報を取得し、プラン変更が即座にダイアログに反映されるようにする
      final statusFuture = _subscriptionService.getCurrentStatus();
      final resetDateFuture = _subscriptionService.getNextResetDate();
      final planFuture = _subscriptionService.getCurrentPlanClass();

      final statusResult = await statusFuture;
      final planResult = await planFuture;
      final resetDateResult = await resetDateFuture;

      if (statusResult.isFailure || planResult.isFailure) {
        if (context.mounted) {
          await showDialog<void>(
            context: context,
            builder: (context) => PresetDialogs.error(
              context: context,
              title: context.l10n.usageStatusFetchErrorTitle,
              message: context.l10n.commonTryAgainLater,
              onConfirm: () => Navigator.of(context).pop(),
            ),
          );
        }
        return;
      }

      final status = statusResult.value;
      final plan = planResult.value;
      final nextResetDate = resetDateResult.isSuccess
          ? resetDateResult.value
          : DateTime.now().add(const Duration(days: 30));

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PresetDialogs.usageStatus(
            context: context,
            planName: context.l10n.localizedPlanName(plan.id),
            planId: plan.id,
            usageCount: status.monthlyUsageCount,
            limit: plan.monthlyAiGenerationLimit,
            nextResetDate: nextResetDate,
            onUpgrade: plan.id == SubscriptionConstants.basicPlanId
                ? () {
                    Navigator.of(context).pop();
                    _navigateToUpgrade(context);
                  }
                : null,
            onDismiss: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => PresetDialogs.error(
            context: context,
            title: context.l10n.commonErrorTitle,
            message: context.l10n.usageStatusFetchErrorMessage,
            onConfirm: () => Navigator.of(context).pop(),
          ),
        );
      }
    }
  }

  void _navigateToUpgrade(BuildContext context) {
    UpgradeDialogUtils.showUpgradeDialog(context);
  }
}
