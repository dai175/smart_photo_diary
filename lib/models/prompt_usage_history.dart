import 'package:hive_ce/hive_ce.dart';

part 'prompt_usage_history.g.dart';

@HiveType(typeId: 5)
class PromptUsageHistory extends HiveObject {
  @HiveField(0)
  final String promptId;

  @HiveField(1)
  final DateTime usedAt;

  @HiveField(2)
  final String? diaryEntryId;

  @HiveField(3)
  final bool wasHelpful;

  PromptUsageHistory({
    required this.promptId,
    DateTime? usedAt,
    this.diaryEntryId,
    this.wasHelpful = true,
  }) : usedAt = usedAt ?? DateTime.now();

  factory PromptUsageHistory.fromJson(Map<String, dynamic> json) {
    return PromptUsageHistory(
      promptId: json['promptId'] as String,
      usedAt: DateTime.parse(json['usedAt'] as String),
      diaryEntryId: json['diaryEntryId'] as String?,
      wasHelpful: json['wasHelpful'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promptId': promptId,
      'usedAt': usedAt.toIso8601String(),
      'diaryEntryId': diaryEntryId,
      'wasHelpful': wasHelpful,
    };
  }

  @override
  String toString() {
    return 'PromptUsageHistory(promptId: $promptId, usedAt: $usedAt, helpful: $wasHelpful)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromptUsageHistory &&
        other.promptId == promptId &&
        other.usedAt == usedAt;
  }

  @override
  int get hashCode => Object.hash(promptId, usedAt);
}
