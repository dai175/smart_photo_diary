// PromptUsageService実装
//
// プロンプト使用履歴のCRUD操作を担当するサービス
// Hive Boxを使用したローカル永続化

import 'package:hive_flutter/hive_flutter.dart';
import '../core/service_locator.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../models/writing_prompt.dart';
import 'interfaces/prompt_usage_service_interface.dart';

/// プロンプト使用履歴管理サービス
///
/// Hive Boxを使用して使用履歴を永続化し、
/// 履歴の記録・取得・クリア・統計機能を提供
class PromptUsageService implements IPromptUsageService {
  static const String _usageHistoryBoxName = 'prompt_usage_history';

  Box<PromptUsageHistory>? _usageHistoryBox;

  @override
  bool get isAvailable => _usageHistoryBox != null && _usageHistoryBox!.isOpen;

  @override
  Future<void> initialize() async {
    final loggingService = await ServiceLocator().getAsync<ILoggingService>();

    // 既存のBoxがあればクローズ
    if (Hive.isBoxOpen(_usageHistoryBoxName)) {
      await Hive.box<PromptUsageHistory>(_usageHistoryBoxName).close();
    }

    _usageHistoryBox = await Hive.openBox<PromptUsageHistory>(
      _usageHistoryBoxName,
    );
    loggingService.info(
      'PromptUsageService: 使用履歴Box初期化完了（履歴数: ${_usageHistoryBox!.length}）',
    );
  }

  @override
  Future<bool> recordPromptUsage({
    required String promptId,
    String? diaryEntryId,
    bool wasHelpful = true,
  }) async {
    if (!isAvailable) {
      return false;
    }

    try {
      final usage = PromptUsageHistory(
        promptId: promptId,
        diaryEntryId: diaryEntryId,
        wasHelpful: wasHelpful,
      );

      await _usageHistoryBox!.add(usage);

      final loggingService = await ServiceLocator().getAsync<ILoggingService>();
      loggingService.info(
        'PromptUsageService: プロンプト使用履歴記録完了（promptId: $promptId）',
      );

      return true;
    } catch (e) {
      final loggingService = await ServiceLocator().getAsync<ILoggingService>();
      loggingService.error('PromptUsageService: 使用履歴記録失敗', error: e);
      return false;
    }
  }

  @override
  List<PromptUsageHistory> getUsageHistory({int? limit, String? promptId}) {
    if (!isAvailable) {
      return [];
    }

    var histories = _usageHistoryBox!.values.toList();

    // 特定プロンプトIDでフィルタ
    if (promptId != null) {
      histories = histories.where((h) => h.promptId == promptId).toList();
    }

    // 新しい順でソート
    histories.sort((a, b) => b.usedAt.compareTo(a.usedAt));

    // 件数制限
    if (limit != null && limit > 0) {
      histories = histories.take(limit).toList();
    }

    return histories;
  }

  @override
  List<String> getRecentlyUsedPromptIds({int days = 7, int limit = 10}) {
    if (!isAvailable) {
      return [];
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final recentHistories = _usageHistoryBox!.values
        .where((h) => h.usedAt.isAfter(cutoffDate))
        .toList();

    // 新しい順でソート
    recentHistories.sort((a, b) => b.usedAt.compareTo(a.usedAt));

    // プロンプトIDを抽出（重複除去）
    final recentIds = <String>[];
    for (final history in recentHistories) {
      if (!recentIds.contains(history.promptId)) {
        recentIds.add(history.promptId);

        if (recentIds.length >= limit) {
          break;
        }
      }
    }

    return recentIds;
  }

  @override
  Future<bool> clearUsageHistory({int? olderThanDays}) async {
    if (!isAvailable) {
      return false;
    }

    try {
      if (olderThanDays == null) {
        // 全削除
        await _usageHistoryBox!.clear();
      } else {
        // 指定日数より古いもののみ削除
        final cutoffDate = DateTime.now().subtract(
          Duration(days: olderThanDays),
        );
        final keysToDelete = <int>[];

        for (int i = 0; i < _usageHistoryBox!.length; i++) {
          final history = _usageHistoryBox!.getAt(i);
          if (history != null && history.usedAt.isBefore(cutoffDate)) {
            keysToDelete.add(i);
          }
        }

        // 後ろから削除（インデックスのずれを防ぐため）
        for (final key in keysToDelete.reversed) {
          await _usageHistoryBox!.deleteAt(key);
        }
      }

      final loggingService = await ServiceLocator().getAsync<ILoggingService>();
      loggingService.info('PromptUsageService: 使用履歴クリア完了');

      return true;
    } catch (e) {
      final loggingService = await ServiceLocator().getAsync<ILoggingService>();
      loggingService.error('PromptUsageService: 使用履歴クリア失敗', error: e);
      return false;
    }
  }

  @override
  Map<String, int> getUsageFrequencyStats({int days = 30}) {
    if (!isAvailable) {
      return {};
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final stats = <String, int>{};

    for (final history in _usageHistoryBox!.values) {
      if (history.usedAt.isAfter(cutoffDate)) {
        stats[history.promptId] = (stats[history.promptId] ?? 0) + 1;
      }
    }

    return stats;
  }

  @override
  void reset() {
    _usageHistoryBox = null;
  }
}
