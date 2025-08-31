import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

/// Smart Photo Diary アプリ全体で使用するアイコン定数
/// より印象的で親しみやすいアイコンを統一的に管理
class AppIcons {
  // プライベートコンストラクタ
  AppIcons._();

  /// ナビゲーション関連アイコン
  static const List<IconData> navigationIcons = [
    FeatherIcons.home, // ホーム
    FeatherIcons.bookOpen, // 日記
    FeatherIcons.barChart2, // 統計
    FeatherIcons.sliders, // 設定
  ];

  /// ホーム画面アイコン
  static const IconData homeRefresh = FeatherIcons.refreshCw;
  static const IconData photoLibrary = FeatherIcons.image;
  static const IconData photoCamera = FeatherIcons.camera;
  static const IconData addPhoto = FeatherIcons.plusCircle;

  /// 日記関連アイコン
  static const IconData diaryBook = FeatherIcons.bookOpen;
  static const IconData diaryEntry = FeatherIcons.fileText;
  static const IconData diaryEdit = FeatherIcons.edit3;
  static const IconData diarySave = FeatherIcons.checkCircle;
  static const IconData diaryDelete = FeatherIcons.trash2;
  static const IconData diaryDate = FeatherIcons.calendar;

  /// 検索・フィルタ関連アイコン
  static const IconData search = FeatherIcons.search;
  static const IconData searchStart = FeatherIcons.search;
  static const IconData searchClear = FeatherIcons.xCircle;
  static const IconData filter = FeatherIcons.filter;
  static const IconData filterActive = FeatherIcons.filter;
  static const IconData filterClear = FeatherIcons.slash;

  /// 写真選択関連アイコン
  static const IconData photoSelected = FeatherIcons.checkCircle;
  static const IconData photoUnselected = FeatherIcons.circle;
  static const IconData photoUsed = FeatherIcons.check;

  /// 統計・カレンダー関連アイコン
  static const IconData statisticsTotal = FeatherIcons.book;
  static const IconData statisticsStreak = FeatherIcons.activity;
  static const IconData statisticsRecord = FeatherIcons.award;
  static const IconData statisticsMonth = FeatherIcons.calendar;
  static const IconData calendarToday = FeatherIcons.calendar;
  static const IconData calendarPrev = FeatherIcons.chevronLeft;
  static const IconData calendarNext = FeatherIcons.chevronRight;

  /// 設定画面アイコン
  static const IconData settingsTheme = FeatherIcons.moon;
  static const IconData settingsStorage = FeatherIcons.hardDrive;
  static const IconData settingsExport = FeatherIcons.download;
  static const IconData settingsImport = FeatherIcons.upload;
  static const IconData settingsCleanup = FeatherIcons.trash;
  static const IconData settingsInfo = FeatherIcons.info;
  static const IconData settingsRefresh = FeatherIcons.refreshCw;

  /// アクション関連アイコン
  static const IconData actionEdit = FeatherIcons.edit;
  static const IconData actionSave = FeatherIcons.check;
  static const IconData actionCancel = FeatherIcons.x;
  static const IconData actionDelete = FeatherIcons.trash2;
  static const IconData actionBack = FeatherIcons.chevronLeft;
  static const IconData actionForward = FeatherIcons.chevronRight;

  /// タグ・メタデータ関連アイコン
  static const IconData tags = FeatherIcons.tag;
  static const IconData tagSingle = FeatherIcons.tag;
  static const IconData timeCreated = FeatherIcons.clock;
  static const IconData timeUpdated = FeatherIcons.refreshCw;

  /// 時間帯アイコン（統計・フィルタ用）
  static const IconData timeMorning = FeatherIcons.sunrise;
  static const IconData timeAfternoon = FeatherIcons.sun;
  static const IconData timeEvening = FeatherIcons.sunset;
  static const IconData timeNight = FeatherIcons.moon;
  static const IconData timeDefault = FeatherIcons.clock;

  /// エラー・状態表示アイコン
  static const IconData errorDefault = FeatherIcons.alertCircle;
  static const IconData errorCritical = FeatherIcons.alertTriangle;
  static const IconData warning = FeatherIcons.alertTriangle;
  static const IconData success = FeatherIcons.checkCircle;
  static const IconData info = FeatherIcons.info;
  static const IconData retry = FeatherIcons.refreshCw;

  /// 空状態アイコン
  static const IconData emptyDiary = FeatherIcons.book;
  static const IconData emptyPhoto = FeatherIcons.image;
  static const IconData emptySearch = FeatherIcons.search;
  static const IconData emptyFilter = FeatherIcons.slash;

  /// ダイアログ・モーダル関連アイコン
  static const IconData dialogHelp = FeatherIcons.helpCircle;
  static const IconData dialogConfirm = FeatherIcons.checkCircle;
  static const IconData dialogError = FeatherIcons.alertCircle;
  static const IconData dialogClose = FeatherIcons.x;

  /// 権限・アクセス関連アイコン
  static const IconData permissionPhoto = FeatherIcons.camera;
  static const IconData permissionSettings = FeatherIcons.settings;

  /// AI・生成関連アイコン
  static const IconData aiGenerate = FeatherIcons.zap; // AI生成イメージ
  static const IconData aiProcessing = FeatherIcons.cpu;
  static const IconData aiMagic = FeatherIcons.zap;
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
