import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/logging_service.dart';

/// パフォーマンス監視ユーティリティ
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<double>> _measurements = {};

  /// パフォーマンス計測を開始
  static void startMeasurement(String label) {
    _startTimes[label] = DateTime.now();
  }

  /// パフォーマンス計測を終了
  static Future<void> endMeasurement(String label, {String? context}) async {
    final startTime = _startTimes[label];
    if (startTime == null) {
      debugPrint('PerformanceMonitor: 計測開始されていません - $label');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final milliseconds = duration.inMilliseconds.toDouble();

    // 計測結果を記録
    _measurements[label] ??= [];
    _measurements[label]!.add(milliseconds);

    // 最新10件の平均を計算
    final recentMeasurements = _measurements[label]!.reversed.take(10).toList();
    final average = recentMeasurements.isEmpty
        ? 0.0
        : recentMeasurements.reduce((a, b) => a + b) /
              recentMeasurements.length;

    _startTimes.remove(label);

    // ログに記録
    final loggingService = await LoggingService.getInstance();
    loggingService.debug(
      'パフォーマンス: $label: ${milliseconds}ms (平均: ${average.toStringAsFixed(1)}ms)',
      context: context ?? 'PerformanceMonitor',
    );

    // デバッグビルドの場合はTimelineに記録
    if (kDebugMode) {
      developer.Timeline.finishSync();
    }
  }

  /// メモリ使用状況を記録
  static Future<void> logMemoryUsage(String context) async {
    // Flutter DevToolsのメモリプロファイラと連携
    if (kDebugMode) {
      developer.postEvent('memory_usage', {
        'context': context,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    final loggingService = await LoggingService.getInstance();
    loggingService.debug(
      'メモリ使用状況記録',
      context: context,
      data: 'Flutter DevToolsで確認してください',
    );
  }

  /// パフォーマンス統計をクリア
  static void clearStats() {
    _startTimes.clear();
    _measurements.clear();
  }

  /// パフォーマンス統計を取得
  static Map<String, double> getAverageStats() {
    final stats = <String, double>{};
    _measurements.forEach((label, measurements) {
      if (measurements.isNotEmpty) {
        stats[label] =
            measurements.reduce((a, b) => a + b) / measurements.length;
      }
    });
    return stats;
  }
}
