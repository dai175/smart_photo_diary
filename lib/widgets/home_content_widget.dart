import 'package:flutter/material.dart';
import '../controllers/photo_selection_controller.dart';
import '../widgets/timeline_fab_integration.dart';
import '../ui/design_system/app_spacing.dart';
import '../ui/animations/list_animations.dart';
import '../ui/animations/micro_interactions.dart';
import '../services/interfaces/subscription_service_interface.dart';
import '../core/service_registration.dart';
import '../utils/upgrade_dialog_utils.dart';
import '../ui/components/custom_dialog.dart';

class HomeContentWidget extends StatefulWidget {
  final PhotoSelectionController photoController;
  final VoidCallback onRequestPermission;
  final VoidCallback onSelectionLimitReached;
  final VoidCallback onUsedPhotoSelected;
  final VoidCallback onCameraPressed;
  final Function(String) onDiaryTap;
  final Future<void> Function()? onRefresh;

  const HomeContentWidget({
    super.key,
    required this.photoController,
    required this.onRequestPermission,
    required this.onSelectionLimitReached,
    required this.onUsedPhotoSelected,
    required this.onCameraPressed,
    required this.onDiaryTap,
    this.onRefresh,
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
      title: Text(
        '${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
      ),
      centerTitle: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      elevation: 2,
      actions: [
        // 使用量カウンター表示ボタン
        Container(
          margin: const EdgeInsets.only(right: AppSpacing.xs),
          child: IconButton(
            icon: Icon(
              Icons.analytics_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => _showUsageStatus(context),
            tooltip: 'AI生成の使用状況',
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
            padding: AppSpacing.screenPadding,
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
          // 統合されたタイムラインFAB表示
          Expanded(
            child: TimelineFABIntegration(
              controller: widget.photoController,
              onSelectionLimitReached: widget.onSelectionLimitReached,
              onUsedPhotoSelected: widget.onUsedPhotoSelected,
              onRequestPermission: widget.onRequestPermission,
              onCameraPressed: widget.onCameraPressed,
            ),
          ),
        ],
      ),
    );
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
              title: '使用状況を取得できませんでした',
              message: 'しばらく時間をおいてから再度お試しください。',
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
            planName: plan.displayName,
            used: used.clamp(0, limit),
            limit: limit,
            remaining: remaining.clamp(0, limit),
            nextResetDate: nextResetDate,
            onUpgrade: plan.displayName == 'Basic'
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
            title: 'エラーが発生しました',
            message: '使用状況の取得中にエラーが発生しました。',
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

// PresetDialogs の簡易実装（必要なダイアログのみ）
class PresetDialogs {
  static Widget error({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    return Builder(
      builder: (context) => CustomDialog(
        icon: Icons.error_outline,
        title: title,
        message: message,
        actions: [
          CustomDialogAction(text: 'OK', isPrimary: true, onPressed: onConfirm),
        ],
      ),
    );
  }

  static Widget usageStatus({
    required String planName,
    required int used,
    required int limit,
    required int remaining,
    required DateTime nextResetDate,
    VoidCallback? onUpgrade,
    required VoidCallback onDismiss,
  }) {
    return Builder(
      builder: (context) => CustomDialog(
        icon: Icons.analytics_rounded,
        title: 'AI生成の使用状況',
        message:
            '''プラン: $planName
使用済み: $used/$limit回
残り: $remaining回
リセット日: ${nextResetDate.year}年${nextResetDate.month}月${nextResetDate.day}日''',
        actions: [
          if (onUpgrade != null)
            CustomDialogAction(text: 'アップグレード', onPressed: onUpgrade),
          CustomDialogAction(
            text: '閉じる',
            isPrimary: true,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
