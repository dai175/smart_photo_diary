import 'dart:async';

import '../core/errors/app_exceptions.dart';
import '../core/service_locator.dart';
import '../models/diary_change.dart';
import '../models/diary_entry.dart';
import '../services/interfaces/diary_service_interface.dart';
import '../services/interfaces/logging_service_interface.dart';
import '../screens/statistics/statistics_calculator.dart';
import 'base_error_controller.dart';

/// StatisticsScreen の状態管理・ビジネスロジック
class StatisticsController extends BaseErrorController {
  late final ILoggingService _logger;

  List<DiaryEntry> _allDiaries = [];
  StatisticsData _stats = const StatisticsData(
    totalEntries: 0,
    currentStreak: 0,
    longestStreak: 0,
    monthlyCount: 0,
    diaryMap: {},
  );
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  StreamSubscription<DiaryChange>? _diarySub;
  Timer? _debounce;

  /// 全日記エントリー
  List<DiaryEntry> get allDiaries => _allDiaries;

  /// 統計データ
  StatisticsData get stats => _stats;

  /// カレンダーのフォーカス日
  DateTime get focusedDay => _focusedDay;

  /// カレンダーの選択日
  DateTime? get selectedDay => _selectedDay;

  StatisticsController() {
    _logger = serviceLocator.get<ILoggingService>();
  }

  /// 統計データを読み込む
  Future<void> loadStatistics() async {
    setLoading(true);

    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();
      final result = await diaryService.getSortedDiaryEntries();

      if (result.isSuccess) {
        _allDiaries = result.value;
        _stats = StatisticsCalculator.calculate(_allDiaries);
        setLoading(false);
      } else {
        _logger.error(
          'Statistics data loading error',
          error: result.error,
          context: 'StatisticsController',
        );
        setError(result.error);
      }
    } catch (e) {
      _logger.error(
        'Unexpected error while loading statistics data',
        error: e,
        context: 'StatisticsController',
      );
      setError(
        e is AppException
            ? e
            : ServiceException(
                'Failed to load statistics data',
                originalError: e,
              ),
      );
    }
  }

  /// 日記変更ストリームを購読する
  Future<void> subscribeDiaryChanges() async {
    try {
      final diaryService = await ServiceLocator().getAsync<IDiaryService>();
      _diarySub = diaryService.changes.listen((_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 350), () {
          loadStatistics();
        });
      });
    } catch (e) {
      _logger.warning(
        'Failed to subscribe to diary changes',
        context: 'StatisticsController.subscribeDiaryChanges',
        data: '$e',
      );
    }
  }

  /// カレンダーの日選択処理。
  /// 選択日の日記リストを返す（ナビゲーションは画面側で処理）。
  List<DiaryEntry>? onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final normalizedDay = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    final isSameDay =
        _selectedDay != null &&
        _selectedDay!.year == normalizedDay.year &&
        _selectedDay!.month == normalizedDay.month &&
        _selectedDay!.day == normalizedDay.day;

    if (isSameDay) return null;

    _selectedDay = normalizedDay;
    _focusedDay = focusedDay;
    notifyListeners();

    return _stats.diaryMap[normalizedDay];
  }

  /// ヘッダータップ処理（今月に戻る）
  void onHeaderTapped(DateTime focusedDay) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, now.day);
    if (focusedDay.year != currentMonth.year ||
        focusedDay.month != currentMonth.month) {
      _focusedDay = currentMonth;
      _selectedDay = null;
      notifyListeners();
    }
  }

  /// カレンダーページ変更
  void onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  @override
  void dispose() {
    _diarySub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
