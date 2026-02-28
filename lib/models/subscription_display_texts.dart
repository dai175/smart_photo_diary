/// `SubscriptionInfoV2.getLocalizedDisplayData` に渡すローカライズ済みテキスト群
class SubscriptionDisplayTexts {
  // フォーマッター（関数）
  final String Function(int used, int limit) usageFormatter;
  final String Function(int remaining) remainingFormatter;
  final String Function() limitReachedFormatter;
  final String Function(int remaining) warningRemainingFormatter;
  final String Function(int limit) upgradeRecommendationLimitFormatter;
  final String Function() upgradeRecommendationGeneralFormatter;

  // テキスト文字列
  final String expiredText;
  final String todayText;
  final String tomorrowText;
  final String inactiveStatusText;
  final String expiryNearStatusText;
  final String autoRenewalNotApplicableText;
  final String autoRenewalEnabledText;
  final String autoRenewalDisabledText;

  const SubscriptionDisplayTexts({
    required this.usageFormatter,
    required this.remainingFormatter,
    required this.limitReachedFormatter,
    required this.warningRemainingFormatter,
    required this.upgradeRecommendationLimitFormatter,
    required this.upgradeRecommendationGeneralFormatter,
    required this.expiredText,
    required this.todayText,
    required this.tomorrowText,
    required this.inactiveStatusText,
    required this.expiryNearStatusText,
    required this.autoRenewalNotApplicableText,
    required this.autoRenewalEnabledText,
    required this.autoRenewalDisabledText,
  });
}
