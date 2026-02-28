import 'dart:ui';

import '../../l10n/generated/app_localizations.dart';
import '../../localization/localization_utils.dart';

/// 共有チャネル共通の定数とヘルパーを提供する mixin
mixin ShareChannelMixin {
  /// 共有処理のタイムアウト秒数
  static const int shareTimeoutSeconds = 60;

  /// iPad/iOS 26 で Rect が小さすぎると PlatformException が発生するため安全な値を使用
  static const Rect defaultShareOrigin = Rect.fromLTWH(0, 0, 100, 100);

  /// ローカライズされたメッセージを取得（解決失敗時はフォールバックを返す）
  String getLocalizedMessage(
    Locale locale,
    String Function(AppLocalizations) getMessage,
    String fallback,
  ) {
    try {
      final l10n = LocalizationUtils.resolveFor(locale);
      return getMessage(l10n);
    } catch (_) {
      return fallback;
    }
  }
}
