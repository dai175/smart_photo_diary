import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

/// copyWith で nullable フィールドを明示的に null に設定するための sentinel
const _sentinel = Object();

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

  /// レガシーフィールド: 旧tagsデータの読み取り用（書き込みには使用しない）
  @HiveField(10)
  List<String>? legacyTags;

  /// タグを統一的に取得（tags → legacyTags の順にフォールバック）
  List<String> get effectiveTags => tags ?? legacyTags ?? const [];

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
    this.legacyTags,
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
  //
  // nullable フィールド (tags, tagsGeneratedAt, location) を明示的に null に
  // リセットするには、copyWith(tags: null) のように渡す。
  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? title,
    String? content,
    List<String>? photoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? tags = _sentinel,
    Object? tagsGeneratedAt = _sentinel,
    Object? location = _sentinel,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      photoIds: photoIds ?? this.photoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags == _sentinel ? this.tags : tags as List<String>?,
      tagsGeneratedAt: tagsGeneratedAt == _sentinel
          ? this.tagsGeneratedAt
          : tagsGeneratedAt as DateTime?,
      location: location == _sentinel ? this.location : location as String?,
    );
  }
}
