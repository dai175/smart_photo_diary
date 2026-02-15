import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  String title;

  @HiveField(3)
  String content;

  @HiveField(4)
  final List<String> photoIds; // 写真のIDリスト（AssetEntityのIDを保存）

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  @HiveField(7)
  List<String>? tags; // AI生成またはインポートされたタグ

  @HiveField(8)
  DateTime? tagsGeneratedAt; // タグ生成日時

  @HiveField(9)
  String? location; // 位置情報

  /// タグを統一的に取得
  List<String> get effectiveTags => tags ?? const [];

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.photoIds,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.tagsGeneratedAt,
    this.location,
  });

  // 日記エントリーを更新するメソッド
  void updateContent(String newTitle, String newContent) {
    title = newTitle;
    content = newContent;
    updatedAt = DateTime.now();
  }

  // タグを更新（永続化はサービス層が担当）
  void updateTags(List<String> newTags) {
    tags = newTags;
    tagsGeneratedAt = DateTime.now();
  }

  // タグが有効かどうかをチェック（7日間有効）
  bool get hasValidTags {
    if (tags == null || tagsGeneratedAt == null) return false;

    final daysSinceGeneration = DateTime.now()
        .difference(tagsGeneratedAt!)
        .inDays;
    return daysSinceGeneration < 7; // 7日以内なら有効
  }

  // 日記エントリーのコピーを作成するメソッド
  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    List<String>? photoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    DateTime? tagsGeneratedAt,
    String? location,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      photoIds: photoIds ?? this.photoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      tagsGeneratedAt: tagsGeneratedAt ?? this.tagsGeneratedAt,
      location: location ?? this.location,
    );
  }
}
