import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../core/service_locator.dart';

/// パフォーマンス監視ユーティリティ
class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<double>> _measurements = {};

  // LoggingServiceのゲッター
  static ILoggingService get _logger => serviceLocator.get<ILoggingService>();

  /// パフォーマンス計測を開始
  static void startMeasurement(String label) {
    _startTimes[label] = DateTime.now();

    // デバッグビルドの場合はTimelineに記録
    if (kDebugMode) {
      developer.Timeline.startSync(label);
    }
  }

  /// パフォーマンス計測を終了
  static Future<void> endMeasurement(String label, {String? context}) async {
    final startTime = _startTimes[label];
    if (startTime == null) {
      _logger.warning(
        '計測開始されていません: $label',
        context: 'PerformanceMonitor.endMeasurement',
      );
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
    _logger.debug(
      'パフォーマンス: $label: ${milliseconds}ms (平均: ${average.toStringAsFixed(1)}ms)',
      context: context ?? 'PerformanceMonitor.endMeasurement',
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

    _logger.debug(
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
