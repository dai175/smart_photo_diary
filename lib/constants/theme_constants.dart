import 'package:flutter/material.dart';

/// テーマ関連の定数
class ThemeConstants {
  ThemeConstants._();

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
