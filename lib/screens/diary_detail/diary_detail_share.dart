import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/service_locator.dart';
import '../../localization/localization_extensions.dart';
import '../../models/diary_entry.dart';
import '../../services/interfaces/social_share_service_interface.dart';
import '../../services/social_share/channels/x_share_channel.dart';
import '../../ui/components/custom_dialog.dart';
import '../../ui/design_system/app_spacing.dart';
import '../../ui/design_system/app_typography.dart';
import '../../ui/animations/micro_interactions.dart';

/// 日記詳細画面の共有ロジックヘルパー
///
/// SNS共有（X / Instagram）のダイアログ表示・共有実行を担当する。
/// State の変数を引数で受け取る静的メソッド群で構成。
class DiaryDetailShareHelper {
  DiaryDetailShareHelper._();

  /// 共有ダイアログを表示
  static Future<void> showShareDialog({
    required BuildContext context,
    required DiaryEntry diaryEntry,
    required List<AssetEntity> photoAssets,
  }) async {
    final result = await showDialog<ShareFormat>(
      context: context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return CustomDialog(
          title: l10n.commonShare,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.diaryDetailShareDialogMessage,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildShareOption(
                context: context,
                format: ShareFormat.square,
                title: l10n.diaryDetailShareTextOptionTitle,
                subtitle: l10n.diaryDetailShareTextOptionSubtitle,
                icon: Icons.share_rounded,
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  await shareToX(context: context, diaryEntry: diaryEntry);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildShareOption(
                context: context,
                format: ShareFormat.portrait,
                title: l10n.diaryDetailShareImageOptionTitle,
                subtitle: l10n.diaryDetailSharePortraitSubtitle,
                icon: Icons.crop_portrait_rounded,
                onTap: () {
                  Navigator.of(dialogContext).pop(ShareFormat.portrait);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _buildShareOption(
                context: context,
                format: ShareFormat.square,
                title: l10n.diaryDetailShareImageOptionTitle,
                subtitle: l10n.diaryDetailShareSquareSubtitle,
                icon: Icons.crop_din_rounded,
                onTap: () {
                  Navigator.of(dialogContext).pop(ShareFormat.square);
                },
              ),
            ],
          ),
          actions: [
            CustomDialogAction(
              text: l10n.commonCancel,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (!context.mounted) return;
      await shareToInstagram(
        context: context,
        diaryEntry: diaryEntry,
        photoAssets: photoAssets,
        format: result,
      );
    }
  }

  /// テキストで共有（X）
  static Future<void> shareToX({
    required BuildContext context,
    required DiaryEntry diaryEntry,
  }) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final shareOrigin = _resolveShareOrigin(context);
    final l10n = context.l10n;

    try {
      // ローディングダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final dialogL10n = dialogContext.l10n;
          return CustomDialog(
            title: dialogL10n.diaryDetailSharePreparingTitle,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  dialogL10n.commonPreparing,
                  style: AppTypography.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Center(child: CircularProgressIndicator(strokeWidth: 3)),
              ],
            ),
            actions: const [],
          );
        },
      );

      final share = serviceLocator.get<ISocialShareService>();
      final result = await share.shareToX(
        diary: diaryEntry,
        shareOrigin: shareOrigin,
      );

      // ローディングダイアログを閉じる
      if (context.mounted) navigator.pop();

      result.fold(
        (_) {
          // 成功時は特に何もしない（システム共有シートで完結）
        },
        (error) {
          final message = error is XShareException
              ? l10n.commonShareFailedWithReason(
                  l10n.diaryDetailShareTextOptionTitle,
                )
              : l10n.commonShareFailedWithReason(error.message);
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } catch (e) {
      // ローディングダイアログを閉じる
      if (context.mounted) navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.commonUnexpectedErrorWithDetails('$e'))),
      );
    }
  }

  /// Instagramに共有
  static Future<void> shareToInstagram({
    required BuildContext context,
    required DiaryEntry diaryEntry,
    required List<AssetEntity> photoAssets,
    required ShareFormat format,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final shareOrigin = _resolveShareOrigin(context);
    final l10n = context.l10n;

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CustomDialog(
          title: dialogContext.l10n.diaryDetailSharePreparingTitle,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                dialogContext.l10n.diaryDetailShareGeneratingBody,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      // SocialShareServiceを取得
      final socialShareService = serviceLocator.get<ISocialShareService>();

      // Instagram共有を実行
      final result = await socialShareService.shareToSocialMedia(
        diary: diaryEntry,
        format: format,
        photos: photoAssets,
        shareOrigin: shareOrigin,
      );

      // ローディングダイアログを閉じる
      if (context.mounted) navigator.pop();

      result.fold(
        (_) {
          // 共有成功時は特に何もしない（システム共有シートで完結）
        },
        (error) {
          // エラーメッセージ
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(l10n.commonShareFailedWithReason(error.message)),
              backgroundColor: errorColor,
            ),
          );
        },
      );
    } catch (e) {
      // ローディングダイアログを閉じる
      if (context.mounted) navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(l10n.commonUnexpectedErrorWithDetails('$e')),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  /// 共有オプションのウィジェットを構築
  static Widget _buildShareOption({
    required BuildContext context,
    required ShareFormat format,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MicroInteractions.bounceOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: AppSpacing.cardRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: AppSpacing.iconMd,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: AppTypography.titleMedium),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: AppSpacing.iconSm,
            ),
          ],
        ),
      ),
    );
  }

  /// 共有元の領域を解決
  static Rect _resolveShareOrigin(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final topLeft = renderBox.localToGlobal(Offset.zero);
      return topLeft & renderBox.size;
    }
    // iPad/iOS 26 で Rect が小さすぎると PlatformException が発生するため安全な値を使用
    return const Rect.fromLTWH(0, 0, 100, 100);
  }
}
