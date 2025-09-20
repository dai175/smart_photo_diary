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
    const url =
        'https://titanium-crane-239.notion.site/Smart-Photo-Diary-2339724fbaba8040b797c52bcc314943';
    await launchExternalUrl(url, context: context);
  }

  /// 利用規約を開く
  static Future<void> launchTermsOfUse({BuildContext? context}) async {
    const url =
        'https://titanium-crane-239.notion.site/Smart-Photo-Diary-2399724fbaba80619c7af22bd048a37c';
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
