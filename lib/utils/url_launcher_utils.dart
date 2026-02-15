import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import '../ui/components/custom_dialog.dart';
import '../localization/localization_extensions.dart';

/// URL起動用のユーティリティクラス
class UrlLauncherUtils {
  UrlLauncherUtils._();

  /// 外部URLを開く
  ///
  /// [url] 開くURL
  /// [context] エラーメッセージ表示用のコンテキスト（オプション）
  static Future<void> launchExternalUrl(
    String url, {
    BuildContext? context,
  }) async {
    try {
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context != null && context.mounted) {
          _showErrorDialog(context, context.l10n.urlLauncherOpenFailed);
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorDialog(
          context,
          context.l10n.commonUnexpectedErrorWithDetails(e.toString()),
        );
      }
    }
  }

  /// プライバシーポリシーを開く
  static Future<void> launchPrivacyPolicy({BuildContext? context}) async {
    final isJapanese =
        context != null && Localizations.localeOf(context).languageCode == 'ja';
    final url = isJapanese
        ? 'https://focuswave.cc/ja/privacy/'
        : 'https://focuswave.cc/privacy/';
    await launchExternalUrl(url, context: context);
  }

  /// エラーダイアログを表示
  static Future<void> _showErrorDialog(
    BuildContext context,
    String message,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => PresetDialogs.error(
        context: dialogContext,
        title: dialogContext.l10n.urlLauncherErrorTitle,
        message: message,
        onConfirm: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
