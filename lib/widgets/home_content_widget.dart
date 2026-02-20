import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../widgets/timeline_fab_integration.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/design_system/app_typography.dart';
import '../ui/components/buttons/text_only_button.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';
import '../constants/subscription_constants.dart';
import '../controllers/scroll_signal.dart';

/// ホーム画面のメインコンテンツウィジェット
///
/// タブ統合後の統一ホーム画面を提供。
/// - TimelinePhotoWidget と FAB統合のコンテナ
/// - プル・トゥ・リフレッシュ機能
/// - 日記作成フローとの統合
class HomeContentWidget extends StatefulWidget {
  final PhotoSelectionController photoController;
  final VoidCallback onRequestPermission;
  final VoidCallback onSelectionLimitReached;
  final VoidCallback onUsedPhotoSelected;
  final Function(String photoId)? onUsedPhotoDetail;
  final VoidCallback onCameraPressed;
  final Function(String) onDiaryTap;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onDiaryCreated;
  final VoidCallback? onLoadMorePhotos;
  final VoidCallback? onPreloadMorePhotos;
  final ScrollSignal? scrollSignal;

  const HomeContentWidget({
    super.key,
    required this.photoController,
    required this.onRequestPermission,
    required this.onSelectionLimitReached,
    required this.onUsedPhotoSelected,
    this.onUsedPhotoDetail,
    required this.onCameraPressed,
    required this.onDiaryTap,
    this.onRefresh,
    this.onDiaryCreated,
    this.onLoadMorePhotos,
    this.onPreloadMorePhotos,
    this.scrollSignal,
  });

  @override
  State<HomeContentWidget> createState() => _HomeContentWidgetState();
}

class _HomeContentWidgetState extends State<HomeContentWidget> {
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
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(context.l10n.formatFullDate(DateTime.now())),
      centerTitle: false,
      actions: [
        // 使用量カウンター表示ボタン
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.xs),
          child: IconButton(
            icon: const Icon(Icons.analytics_rounded),
            onPressed: () => _showUsageStatus(context),
            tooltip: context.l10n.usageStatusDialogTitle,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: _buildTimelineSection(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 選択解除バー
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ListenableBuilder(
              listenable: widget.photoController,
              builder: (context, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: widget.photoController.selectedCount > 0
                      ? Padding(
                          key: const ValueKey('selection-bar'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.l10n.homeSelectionCount(
                                  widget.photoController.selectedCount,
                                ),
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              TextOnlyButton(
                                onPressed:
                                    widget.photoController.clearSelection,
                                text: context.l10n.homeSelectionClearAll,
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(
                          width: double.infinity,
                          key: ValueKey('empty'),
                        ),
                );
              },
            ),
          ),
          // 統合されたタイムラインFAB表示
          Expanded(
            child: TimelineFABIntegration(
              controller: widget.photoController,
              onSelectionLimitReached: widget.onSelectionLimitReached,
              onUsedPhotoSelected: widget.onUsedPhotoSelected,
              onUsedPhotoDetail: widget.onUsedPhotoDetail,
              onRequestPermission: widget.onRequestPermission,
              onCameraPressed: widget.onCameraPressed,
              onDiaryCreated: widget.onDiaryCreated,
              onLoadMorePhotos: widget.onLoadMorePhotos,
              onPreloadMorePhotos: widget.onPreloadMorePhotos,
              scrollSignal: widget.scrollSignal,
            ),
          ),
        ],
      ),
    );
  }

  /// プランIDに基づいて多言語化されたプラン名を取得
  String _getLocalizedPlanName(BuildContext context, String planId) {
    switch (planId) {
      case SubscriptionConstants.basicPlanId:
        return context
            .l10n
            .onboardingPlanBasicSubtitle; // "Free plan" / "無料プラン"
      case SubscriptionConstants.premiumMonthlyPlanId:
        return context
            .l10n
            .settingsPremiumMonthlyTitle; // "Premium (monthly)" / "プレミアム（月額）"
      case SubscriptionConstants.premiumYearlyPlanId:
        return context
            .l10n
            .settingsPremiumYearlyTitle; // "Premium (yearly)" / "プレミアム（年額）"
      default:
        return planId; // フォールバック
    }
  }

  /// 使用量状況表示メソッド
  Future<void> _showUsageStatus(BuildContext context) async {
    try {
      final subscriptionService =
          await ServiceRegistration.getAsync<ISubscriptionService>();

      // 使用量情報を取得
      final statusResult = await subscriptionService.getCurrentStatus();
      final planResult = await subscriptionService.getCurrentPlanClass();
      final remainingResult = await subscriptionService
          .getRemainingGenerations();
      final resetDateResult = await subscriptionService.getNextResetDate();

      if (statusResult.isFailure || planResult.isFailure) {
        // エラー時はフォールバック表示
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

      final plan = planResult.value;
      final remaining = remainingResult.isSuccess ? remainingResult.value : 0;
      final nextResetDate = resetDateResult.isSuccess
          ? resetDateResult.value
          : DateTime.now().add(const Duration(days: 30));

      final limit = plan.monthlyAiGenerationLimit;
      final used = limit - remaining;

      if (context.mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (context) => PresetDialogs.usageStatus(
            context: context,
            planName: _getLocalizedPlanName(context, plan.id),
            planId: plan.id,
            used: used.clamp(0, limit),
            limit: limit,
            remaining: remaining.clamp(0, limit),
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

  /// プラン変更誘導機能
  void _navigateToUpgrade(BuildContext context) {
    // 共通のアップグレードダイアログを表示
    UpgradeDialogUtils.showUpgradeDialog(context);
  }
}
