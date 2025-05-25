import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  String content;

  @HiveField(3)
  final List<String> photoIds; // 写真のIDリスト（AssetEntityのIDを保存）

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.photoIds,
    required this.createdAt,
    required this.updatedAt,
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
        debugPrint('写真の取得エラー: $e');
      }
    }

    return assets;
  }

  // 日記エントリーを更新するメソッド
  void updateContent(String newContent) {
    content = newContent;
    updatedAt = DateTime.now();
    save(); // Hiveオブジェクトの保存メソッド
  }

  // 日記エントリーのコピーを作成するメソッド
  DiaryEntry copyWith({
    String? id,
    DateTime? date,
    String? content,
    List<String>? photoIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      content: content ?? this.content,
      photoIds: photoIds ?? this.photoIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
