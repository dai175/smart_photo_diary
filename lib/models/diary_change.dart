/// 日記の変更イベント
class DiaryChange {
  DiaryChange({
    required this.type,
    required this.entryId,
    this.addedPhotoIds = const <String>[],
    this.removedPhotoIds = const <String>[],
    DateTime? changedAt,
  }) : changedAt = changedAt ?? DateTime.now();

  final DiaryChangeType type;
  final String entryId;
  final List<String> addedPhotoIds;
  final List<String> removedPhotoIds;
  final DateTime changedAt;

  @override
  String toString() =>
      'DiaryChange(type=$type, entry=$entryId, +${addedPhotoIds.length}, -${removedPhotoIds.length})';
}

enum DiaryChangeType { created, updated, deleted }
