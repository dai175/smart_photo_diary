import 'package:flutter/material.dart';

/// Smart Photo Diary アプリ全体で使用するアイコン定数
/// Material 3 に調和するアイコンを統一的に管理
class AppIcons {
  AppIcons._();

  /// ナビゲーション関連アイコン（Rounded基調）
  static const List<IconData> navigationIcons = [
    Icons.home_filled, // ホーム
    Icons.menu_book_rounded, // 日記
    Icons.insights_rounded, // 統計
    Icons.tune_rounded, // 設定
  ];

  /// ホーム画面アイコン
  static const IconData homeRefresh = Icons.refresh_rounded;
  static const IconData photoLibrary = Icons.collections_rounded;
  static const IconData photoCamera = Icons.photo_camera_rounded;
  static const IconData addPhoto = Icons.add_a_photo_rounded;

  /// 日記関連アイコン
  static const IconData diaryBook = Icons.auto_stories_rounded;
  static const IconData diaryEntry = Icons.article_rounded;
  static const IconData diaryEdit = Icons.edit_note_rounded;
  static const IconData diarySave = Icons.bookmark_add_rounded;
  static const IconData diaryDelete = Icons.delete_sweep_rounded;
  static const IconData diaryDate = Icons.event_note_rounded;

  /// 検索・フィルタ関連アイコン
  static const IconData search = Icons.search_rounded;
  static const IconData searchStart = Icons.travel_explore_rounded;
  static const IconData searchClear = Icons.clear_rounded;
  static const IconData filter = Icons.filter_list_rounded;
  static const IconData filterActive = Icons.filter_list; // 塗りつぶしバリエーション
  static const IconData filterClear = Icons.filter_alt_off_rounded;

  /// 写真選択関連アイコン
  static const IconData photoSelected = Icons.check_circle_rounded;
  static const IconData photoUnselected = Icons.radio_button_unchecked_rounded;
  static const IconData photoUsed = Icons.verified_rounded;

  /// 統計・カレンダー関連アイコン
  static const IconData statisticsTotal = Icons.auto_stories_outlined;
  static const IconData statisticsStreak = Icons.local_fire_department_rounded;
  static const IconData statisticsRecord = Icons.emoji_events_rounded;
  static const IconData statisticsMonth = Icons.calendar_view_month_rounded;
  static const IconData calendarToday = Icons.today_rounded;
  static const IconData calendarPrev = Icons.chevron_left_rounded;
  static const IconData calendarNext = Icons.chevron_right_rounded;

  /// 設定画面アイコン
  static const IconData settingsTheme = Icons.palette_rounded;
  static const IconData settingsStorage = Icons.storage_rounded;
  static const IconData settingsExport = Icons.file_download_rounded;
  static const IconData settingsImport = Icons.file_upload_rounded;
  static const IconData settingsCleanup = Icons.cleaning_services_rounded;
  static const IconData settingsInfo = Icons.info_rounded;
  static const IconData settingsRefresh = Icons.refresh_rounded;

  /// アクション関連アイコン
  static const IconData actionEdit = Icons.edit_rounded;
  static const IconData actionSave = Icons.check_rounded;
  static const IconData actionCancel = Icons.close_rounded;
  static const IconData actionDelete = Icons.delete_outline_rounded;
  static const IconData actionBack = Icons.arrow_back_ios_rounded;
  static const IconData actionForward = Icons.arrow_forward_ios_rounded;

  /// タグ・メタデータ関連アイコン
  static const IconData tags = Icons.local_offer_rounded;
  static const IconData tagSingle = Icons.label_rounded;
  static const IconData timeCreated = Icons.schedule_rounded;
  static const IconData timeUpdated = Icons.update_rounded;

  /// 時間帯アイコン（統計・フィルタ用）
  static const IconData timeMorning = Icons.wb_sunny_rounded;
  static const IconData timeAfternoon = Icons.light_mode_rounded;
  static const IconData timeEvening = Icons.wb_twilight_rounded;
  static const IconData timeNight = Icons.nights_stay_rounded;
  static const IconData timeDefault = Icons.access_time_rounded;

  /// エラー・状態表示アイコン
  static const IconData errorDefault = Icons.error_outline_rounded;
  static const IconData errorCritical = Icons.dangerous_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData success = Icons.check_circle_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData retry = Icons.refresh_rounded;

  /// 空状態アイコン
  static const IconData emptyDiary = Icons.auto_stories_outlined;
  static const IconData emptyPhoto = Icons.photo_library_outlined;
  static const IconData emptySearch = Icons.search_off_rounded;
  static const IconData emptyFilter = Icons.filter_list_off_rounded;

  /// ダイアログ・モーダル関連アイコン
  static const IconData dialogHelp = Icons.help_outline_rounded;
  static const IconData dialogConfirm = Icons.check_circle_outline_rounded;
  static const IconData dialogError = Icons.error_outline_rounded;
  static const IconData dialogClose = Icons.close_rounded;

  /// 権限・アクセス関連アイコン
  static const IconData permissionPhoto = Icons.photo_camera_outlined;
  static const IconData permissionSettings = Icons.settings_rounded;

  /// AI・生成関連アイコン
  static const IconData aiGenerate = Icons.auto_awesome_rounded;
  static const IconData aiProcessing = Icons.psychology_rounded;
  static const IconData aiMagic = Icons.auto_fix_high_rounded;
}

/// アイコンサイズ定数
class AppIconSizes {
  static const double small = 16.0;
  static const double medium = 20.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  static const double huge = 48.0;

  // 特定用途のサイズ
  static const double navigation = 24.0;
  static const double appBar = 24.0;
  static const double button = 20.0;
  static const double fab = 24.0;
  static const double card = 18.0;
  static const double list = 20.0;
}
