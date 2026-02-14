import '../../models/diary_change.dart';
import 'diary_crud_service_interface.dart';
import 'diary_query_service_interface.dart';

/// 日記サービスの複合インターフェース
///
/// [IDiaryCrudService] と [IDiaryQueryService] を統合し、
/// 変更ストリームとリソース管理を追加する。
///
/// タグ管理は [IDiaryTagService]、統計は [IDiaryStatisticsService] を使用。
abstract class IDiaryService implements IDiaryCrudService, IDiaryQueryService {
  /// 日記の変更ストリーム（作成/更新/削除）。broadcast。
  Stream<DiaryChange> get changes;

  /// データベースの最適化（断片化を解消）
  Future<void> compactDatabase();

  /// リソースを解放する
  void dispose();
}
