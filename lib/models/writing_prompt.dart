import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

part 'writing_prompt.g.dart';

/// ライティングプロンプトのカテゴリ定義（感情深掘り型）
/// 感情中心のプロンプトカテゴリのみを提供します
@HiveType(typeId: 3)
enum PromptCategory {
  // 基本感情カテゴリ（Basic用）
  @HiveField(0)
  emotion('emotion', '感情'),

  // Premium感情深掘りカテゴリ
  @HiveField(1)
  emotionDepth('emotion_depth', '感情深掘り'),

  @HiveField(2)
  sensoryEmotion('sensory_emotion', '感情五感'),

  @HiveField(3)
  emotionGrowth('emotion_growth', '感情成長'),

  @HiveField(4)
  emotionConnection('emotion_connection', '感情つながり'),

  @HiveField(5)
  emotionDiscovery('emotion_discovery', '感情発見'),

  @HiveField(6)
  emotionFantasy('emotion_fantasy', '感情幻想'),

  @HiveField(7)
  emotionHealing('emotion_healing', '感情癒し'),

  @HiveField(8)
  emotionEnergy('emotion_energy', '感情エネルギー');

  const PromptCategory(this.id, this.displayName);

  /// カテゴリID（JSON保存用）
  final String id;

  /// 表示名（日本語）
  final String displayName;

  /// IDからカテゴリを取得
  static PromptCategory fromId(String id) {
    return PromptCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => PromptCategory.emotion,
    );
  }

  /// 表示名のリストを取得
  static List<String> get displayNames {
    return PromptCategory.values
        .map((category) => category.displayName)
        .toList();
  }
}

/// ライティングプロンプトモデル
/// Premium機能として日記生成時の創作支援を提供します
@HiveType(typeId: 4)
class WritingPrompt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String text;

  @HiveField(2)
  final PromptCategory category;

  @HiveField(3)
  final bool isPremiumOnly;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final int priority;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final bool isActive;

  WritingPrompt({
    required this.id,
    required this.text,
    required this.category,
    this.isPremiumOnly = false,
    this.tags = const [],
    this.description,
    this.priority = 0,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();

  /// JSONからWritingPromptを作成
  factory WritingPrompt.fromJson(Map<String, dynamic> json) {
    return WritingPrompt(
      id: json['id'] as String,
      text: json['text'] as String,
      category: PromptCategory.fromId(json['category'] as String),
      isPremiumOnly: json['isPremiumOnly'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      priority: json['priority'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// WritingPromptをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category.id,
      'isPremiumOnly': isPremiumOnly,
      'tags': tags,
      'description': description,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// プロンプトが指定されたプランで使用可能かどうか
  bool isAvailableForPlan({required bool isPremium}) {
    if (isPremiumOnly && !isPremium) {
      return false;
    }
    return isActive;
  }

  /// プロンプトがキーワードにマッチするかどうか
  bool matchesKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return text.toLowerCase().contains(lowerKeyword) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerKeyword)) ||
        (description?.toLowerCase().contains(lowerKeyword) ?? false);
  }

  /// カテゴリの表示名を取得
  String get categoryDisplayName => category.displayName;

  /// プロンプトの長さ（文字数）を取得
  int get textLength => text.length;

  /// プロンプトが長文かどうか（50文字以上）
  bool get isLongPrompt => text.length >= 50;

  /// プロンプトのプレビューテキスト（最初の30文字 + "..."）
  String get previewText {
    if (text.length <= 30) return text;
    return '${text.substring(0, 30)}...';
  }

  /// プロンプトの重要度レベル（priority基準）
  String get importanceLevel {
    if (priority >= 80) return '高';
    if (priority >= 50) return '中';
    return '低';
  }

  @override
  String toString() {
    return 'WritingPrompt(id: $id, category: ${category.displayName}, isPremium: $isPremiumOnly, text: $previewText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WritingPrompt && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// デバッグ用の詳細情報を取得
  @visibleForTesting
  Map<String, dynamic> get debugInfo {
    return {
      'id': id,
      'category': category.displayName,
      'isPremiumOnly': isPremiumOnly,
      'textLength': textLength,
      'tagsCount': tags.length,
      'priority': priority,
      'isActive': isActive,
    };
  }

  /// コピーコンストラクタ
  WritingPrompt copyWith({
    String? id,
    String? text,
    PromptCategory? category,
    bool? isPremiumOnly,
    List<String>? tags,
    String? description,
    int? priority,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return WritingPrompt(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      isPremiumOnly: isPremiumOnly ?? this.isPremiumOnly,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// プロンプト使用履歴管理用モデル
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

  /// JSONからPromptUsageHistoryを作成
  factory PromptUsageHistory.fromJson(Map<String, dynamic> json) {
    return PromptUsageHistory(
      promptId: json['promptId'] as String,
      usedAt: DateTime.parse(json['usedAt'] as String),
      diaryEntryId: json['diaryEntryId'] as String?,
      wasHelpful: json['wasHelpful'] as bool? ?? true,
    );
  }

  /// PromptUsageHistoryをJSONに変換
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
