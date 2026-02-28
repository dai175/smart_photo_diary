import 'dart:ui';

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
  static const String defaultLocaleCode = 'ja';

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

  @HiveField(9)
  final Map<String, String> localizedTexts;

  @HiveField(10)
  final Map<String, String>? localizedDescriptions;

  @HiveField(11)
  final Map<String, List<String>>? localizedTags;

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
    Map<String, String>? localizedTexts,
    Map<String, String>? localizedDescriptions,
    Map<String, List<String>>? localizedTags,
  }) : createdAt = createdAt ?? DateTime.now(),
       localizedTexts = _mergeLocalizedTexts(localizedTexts, text),
       localizedDescriptions = _mergeLocalizedDescriptions(
         localizedDescriptions,
         description,
       ),
       localizedTags = _mergeLocalizedTags(localizedTags, tags);

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
      localizedTexts:
          _parseLocalizedStringMap(json['localizedTexts']) ??
          _parseDualLocaleDeprecated(json, 'texts'),
      localizedDescriptions: _parseLocalizedStringMap(
        json['localizedDescriptions'],
      ),
      localizedTags: _parseLocalizedTags(json['localizedTags']),
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
      'localizedTexts': localizedTexts,
      'localizedDescriptions': localizedDescriptions,
      'localizedTags': localizedTags,
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
    if (text.toLowerCase().contains(lowerKeyword)) {
      return true;
    }

    if (localizedTexts.values.any(
      (value) => value.toLowerCase().contains(lowerKeyword),
    )) {
      return true;
    }

    if (tags.any((tag) => tag.toLowerCase().contains(lowerKeyword))) {
      return true;
    }

    if (localizedTags != null &&
        localizedTags!.values.any(
          (tags) => tags.any((tag) => tag.toLowerCase().contains(lowerKeyword)),
        )) {
      return true;
    }

    if ((description?.toLowerCase().contains(lowerKeyword) ?? false)) {
      return true;
    }

    if (localizedDescriptions != null &&
        localizedDescriptions!.values.any(
          (value) => value.toLowerCase().contains(lowerKeyword),
        )) {
      return true;
    }

    return false;
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

  /// 指定ロケールに適したテキストを取得
  String textForLocale(Locale? locale) {
    return _resolveLocalizedString(localizedTexts, locale) ?? text;
  }

  /// 指定ロケールに適した説明を取得
  String? descriptionForLocale(Locale? locale) {
    return _resolveLocalizedString(localizedDescriptions, locale) ??
        description;
  }

  /// 指定ロケールに適したタグリストを取得
  List<String> tagsForLocale(Locale? locale) {
    final localized = _resolveLocalizedList(localizedTags, locale);
    if (localized != null && localized.isNotEmpty) {
      return localized;
    }
    return tags;
  }

  /// 指定ロケール向けにローカライズしたコピーを生成
  WritingPrompt localizedCopy(Locale? locale) {
    if (locale == null) {
      return this;
    }

    final localizedText = textForLocale(locale);
    final localizedDescription = descriptionForLocale(locale);
    final localizedTags = tagsForLocale(locale);

    if (localizedText == text &&
        localizedDescription == description &&
        listEquals(localizedTags, tags)) {
      return this;
    }

    return copyWith(
      text: localizedText,
      description: localizedDescription,
      tags: localizedTags,
    );
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
    Map<String, String>? localizedTexts,
    Map<String, String>? localizedDescriptions,
    Map<String, List<String>>? localizedTags,
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
      localizedTexts: localizedTexts ?? this.localizedTexts,
      localizedDescriptions:
          localizedDescriptions ?? this.localizedDescriptions,
      localizedTags: localizedTags ?? this.localizedTags,
    );
  }

  static Map<String, String> _mergeLocalizedTexts(
    Map<String, String>? provided,
    String baseText,
  ) {
    final map = <String, String>{if (provided != null) ...provided};
    map.putIfAbsent(defaultLocaleCode, () => baseText);
    return Map.unmodifiable(map);
  }

  static Map<String, String>? _mergeLocalizedDescriptions(
    Map<String, String>? provided,
    String? baseDescription,
  ) {
    if (provided == null && baseDescription == null) {
      return null;
    }

    final map = <String, String>{if (provided != null) ...provided};

    if (baseDescription != null && baseDescription.isNotEmpty) {
      map.putIfAbsent(defaultLocaleCode, () => baseDescription);
    }

    return map.isEmpty ? null : Map.unmodifiable(map);
  }

  static Map<String, List<String>>? _mergeLocalizedTags(
    Map<String, List<String>>? provided,
    List<String> baseTags,
  ) {
    if ((provided == null || provided.isEmpty) && baseTags.isEmpty) {
      return null;
    }

    final map = <String, List<String>>{};
    if (provided != null) {
      for (final entry in provided.entries) {
        map[entry.key] = List.unmodifiable(entry.value);
      }
    }

    if (baseTags.isNotEmpty) {
      map.putIfAbsent(defaultLocaleCode, () => List.unmodifiable(baseTags));
    }

    return map.isEmpty ? null : Map.unmodifiable(map);
  }

  static Map<String, String>? _parseLocalizedStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, dynamic v) => MapEntry(key, v as String));
    }
    if (value is Map) {
      return value.map((key, v) => MapEntry(key as String, v as String));
    }
    return null;
  }

  static Map<String, String>? _parseDualLocaleDeprecated(
    Map<String, dynamic> json,
    String key,
  ) {
    if (!json.containsKey(key)) {
      return null;
    }
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value.map((k, dynamic v) => MapEntry(k, v as String));
    }
    return null;
  }

  static Map<String, List<String>>? _parseLocalizedTags(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, dynamic v) => MapEntry(
          key,
          (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
    }
    if (value is Map) {
      return value.map(
        (key, v) => MapEntry(
          key as String,
          (v as List).map((item) => item as String).toList(),
        ),
      );
    }
    return null;
  }

  static String? _resolveLocalizedString(
    Map<String, String>? values,
    Locale? locale,
  ) {
    if (values == null || values.isEmpty) {
      return null;
    }

    if (locale == null) {
      return values[defaultLocaleCode] ?? values.values.first;
    }

    final searchOrder = _candidateLocaleKeys(locale);
    for (final key in searchOrder) {
      final value = values[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return values[defaultLocaleCode] ?? values.values.first;
  }

  static List<String>? _resolveLocalizedList(
    Map<String, List<String>>? values,
    Locale? locale,
  ) {
    if (values == null || values.isEmpty) {
      return null;
    }

    if (locale == null) {
      final defaultList = values[defaultLocaleCode];
      return defaultList ?? values.values.first;
    }

    final searchOrder = _candidateLocaleKeys(locale);
    for (final key in searchOrder) {
      final value = values[key];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return values[defaultLocaleCode] ?? values.values.first;
  }

  static List<String> _candidateLocaleKeys(Locale locale) {
    final candidates = <String>[];
    final languageCode = locale.languageCode.toLowerCase();
    final countryCode = locale.countryCode?.toLowerCase();

    if (countryCode != null && countryCode.isNotEmpty) {
      candidates.add('$languageCode-$countryCode');
      candidates.add('${languageCode}_$countryCode');
    }

    candidates.add(languageCode);
    return candidates;
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
