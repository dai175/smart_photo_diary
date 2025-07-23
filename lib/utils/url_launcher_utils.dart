import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

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
          _showErrorDialog(context, 'リンクを開くことができませんでした');
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorDialog(context, 'エラーが発生しました: $e');
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
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
