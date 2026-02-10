import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';

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
  List<String>? cachedTags; // 生成されたタグのキャッシュ

  @HiveField(8)
  DateTime? tagsGeneratedAt; // タグ生成日時

  @HiveField(9)
  String? location; // 位置情報

  @HiveField(10)
  List<String>? tags; // 初期タグ（キャッシュとは別）

  /// タグを統一的に取得（cachedTagsを優先、なければtagsにフォールバック）
  List<String> get effectiveTags => cachedTags ?? tags ?? const [];

  DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.photoIds,
    required this.createdAt,
    required this.updatedAt,
    this.cachedTags,
    this.tagsGeneratedAt,
    this.location,
    this.tags,
  });

  // 写真のIDリストからAssetEntityのリストを取得するメソッド
  Future<List<AssetEntity>> getPhotoAssets() async {
    final List<AssetEntity> assets = [];

    for (final photoId in photoIds) {
      try {
        final asset = await AssetEntity.fromId(photoId);
        if (asset != null) {
          assets.add(asset);
        }
      } catch (e) {
        try {
          final logger = serviceLocator.get<ILoggingService>();
          logger.error(
            '写真の取得エラー: photoId: $photoId',
            context: 'DiaryEntry.getPhotoAssets',
            error: e,
          );
        } catch (_) {
          // LoggingServiceが利用できない場合はdebugPrintにフォールバック
          debugPrint('写真の取得エラー: $e');
        }
      }
    }

    return assets;
  }

  // 日記エントリーを更新するメソッド
  void updateContent(String newTitle, String newContent) {
    title = newTitle;
    content = newContent;
    updatedAt = DateTime.now();
    save(); // Hiveオブジェクトの保存メソッド
  }

  // タグを更新してデータベースに保存
  Future<void> updateTags(List<String> tags) async {
    cachedTags = tags;
    tagsGeneratedAt = DateTime.now();
    await save(); // Hiveのsaveメソッドでデータベースに保存
  }

  // タグが有効かどうかをチェック（7日間有効）
  bool get hasValidTags {
    if (cachedTags == null || tagsGeneratedAt == null) return false;

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
    List<String>? cachedTags,
    DateTime? tagsGeneratedAt,
    String? location,
    List<String>? tags,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      photoIds: photoIds ?? this.photoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cachedTags: cachedTags ?? this.cachedTags,
      tagsGeneratedAt: tagsGeneratedAt ?? this.tagsGeneratedAt,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }
}
