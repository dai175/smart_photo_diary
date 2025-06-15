import 'package:flutter/material.dart';

/// Smart Photo Diary アプリケーション定数
class AppConstants {
  // 写真選択関連
  static const int maxPhotosSelection = 3;
  static const int photoGridCrossAxisCount = 3;
  static const double photoGridSpacing = 8.0;
  static const double photoThumbnailSize = 90.0;
  static const double photoCornerRadius = 16.0;
  
  // UI関連
  static const double defaultPadding = 16.0;
  static const double largePadding = 20.0;
  static const double smallPadding = 8.0;
  static const double buttonHeight = 48.0;
  static const double bottomNavPadding = 80.0;
  
  // ダイアログ・ボトムシート
  static const double bottomSheetHeightRatio = 0.75;
  
  // 写真サムネイル
  static const double diaryThumbnailSize = 120.0;
  static const double detailImageSize = 200.0;
  static const double previewImageSize = 200.0;
  static const double largeImageSize = 400.0;
  
  // グラデーション色
  static const List<Color> headerGradientColors = [
    Color(0xFFFF5F6D),
    Color(0xFFFFC371),
  ];
  
  // レイアウト
  static const double headerTopPadding = 50.0;
  static const double headerBottomPadding = 16.0;
  static const double photoGridHeight = 250.0;
  static const double recentDiaryCardHeight = 120.0;
  
  // テキストサイズ
  static const double titleFontSize = 24.0;
  static const double subtitleFontSize = 16.0;
  static const double sectionTitleFontSize = 20.0;
  static const double cardTitleFontSize = 18.0;
  static const double bodyFontSize = 15.0;
  static const double captionFontSize = 14.0;
  static const double smallCaptionFontSize = 10.0;
  
  // メッセージ
  static const String appTitle = 'Smart Photo Diary';
  static const String newPhotosTitle = '新しい写真';
  static const String recentDiariesTitle = '最近の日記';
  static const String noPhotosMessage = '写真が見つかりませんでした';
  static const String noDiariesMessage = '保存された日記がありません';
  static const String permissionMessage = '写真へのアクセス権限が必要です';
  static const String requestPermissionButton = '権限をリクエスト';
  static const String selectionLimitMessage = '写真は3枚までにしてください';
  static const String usedPhotoMessage = 'この写真はすでに日記で使用されています';
  static const String usedPhotoLabel = '使用済み';
  static const String okButton = 'OK';
  
  // エラーメッセージ
  static const String diaryNotFoundMessage = '日記が見つかりませんでした';
  static const String diaryLoadErrorMessage = '日記の読み込みに失敗しました';
  static const String diaryUpdateSuccessMessage = '日記を更新しました';
  static const String diaryDeleteSuccessMessage = '日記を削除しました';
  
  // ナビゲーション
  static const List<String> navigationLabels = [
    'ホーム',
    '日記',
    '統計',
    '設定',
  ];
  
  // アイコン（AppIconsから参照）
  static const List<IconData> navigationIcons = [
    Icons.home_filled,           // より温かみのあるホームアイコン
    Icons.menu_book_rounded,     // 本を開いた印象的なアイコン
    Icons.insights_rounded,      // より分析的で魅力的な統計アイコン
    Icons.tune_rounded,          // 調整・カスタマイズのイメージ
  ];
  
  // アニメーション
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // 写真サービス関連
  static const int defaultPhotoLimit = 20;
  static const int maxPhotoLimit = 100;
  static const int defaultThumbnailWidth = 200;
  static const int defaultThumbnailHeight = 200;
  
  // 影
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];
}

/// テーマ関連の定数
class ThemeConstants {
  static const double borderRadius = 16.0;
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 24.0;
  static const double extraSmallBorderRadius = 4.0;
  
  static const EdgeInsets defaultCardPadding = EdgeInsets.all(14.0);
  static const EdgeInsets defaultScreenPadding = EdgeInsets.symmetric(
    horizontal: 20.0, 
    vertical: 12.0,
  );
}

/// AI関連の定数
class AiConstants {
  // Gemini API設定
  static const String geminiModelName = 'gemini-2.5-flash-preview-04-17';
  static const double defaultTemperature = 0.7;
  static const int defaultMaxOutputTokens = 1000;
  static const double defaultTopP = 0.8;
  static const int defaultTopK = 10;
  static const double tagGenerationTemperature = 0.3;
  
  // 時間帯判定
  static const int morningStartHour = 5;
  static const int afternoonStartHour = 12;
  static const int eveningStartHour = 18;
  static const int nightStartHour = 22;
}