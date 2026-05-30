enum SubscriptionSyncOutcome {
  noChange,
  synced,
  downgradedToBasic,

  /// IAP未初期化・stateService未初期化など前提条件不足
  skipped,

  /// ネットワークまたはStore通信失敗により現状維持
  error,
}

class SubscriptionSyncResult {
  final SubscriptionSyncOutcome outcome;
  final int restoredCount;

  const SubscriptionSyncResult._({
    required this.outcome,
    this.restoredCount = 0,
  });

  factory SubscriptionSyncResult.noChange() =>
      const SubscriptionSyncResult._(outcome: SubscriptionSyncOutcome.noChange);

  factory SubscriptionSyncResult.synced(int count) => SubscriptionSyncResult._(
    outcome: SubscriptionSyncOutcome.synced,
    restoredCount: count,
  );

  factory SubscriptionSyncResult.downgradedToBasic() =>
      const SubscriptionSyncResult._(
        outcome: SubscriptionSyncOutcome.downgradedToBasic,
      );

  factory SubscriptionSyncResult.skipped() =>
      const SubscriptionSyncResult._(outcome: SubscriptionSyncOutcome.skipped);

  factory SubscriptionSyncResult.error() =>
      const SubscriptionSyncResult._(outcome: SubscriptionSyncOutcome.error);

  @override
  String toString() =>
      'SubscriptionSyncResult(outcome: $outcome, restoredCount: $restoredCount)';
}
