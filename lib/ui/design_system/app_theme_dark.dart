import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import '../component_constants.dart';

/// ダークテーマの ThemeData を構築する
ThemeData buildDarkTheme({required bool isTestEnv}) {
  if (isTestEnv) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Color Scheme — 温かみのあるダークパレット
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onBackground,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onBackground,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondaryLight,
      surface: AppColors.surfaceDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      onSurface: AppColors.onSurfaceDark,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.outlineDark,
      outlineVariant: AppColors.surfaceContainerHighestDark,
      shadow: AppColors.shadow,
    ),

    // Scaffold background
    scaffoldBackgroundColor: AppColors.surfaceDark,

    // App Bar Theme — 背景と一体化
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.onSurfaceDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.withColor(
        AppTypography.appTitle,
        AppColors.onSurfaceDark,
      ),
      actionsIconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariantDark,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // Text Theme - Google Fonts in production, system font in tests (Dark)
    textTheme:
        (isTestEnv
                ? ThemeData.dark().textTheme
                : GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme))
            .copyWith(
              headlineLarge: AppTypography.withColor(
                AppTypography.headlineLarge,
                AppColors.onBackgroundDark,
              ),
              headlineMedium: AppTypography.withColor(
                AppTypography.headlineMedium,
                AppColors.onBackgroundDark,
              ),
              headlineSmall: AppTypography.withColor(
                AppTypography.headlineSmall,
                AppColors.onBackgroundDark,
              ),
              titleLarge: AppTypography.withColor(
                AppTypography.titleLarge,
                AppColors.onBackgroundDark,
              ),
              titleMedium: AppTypography.withColor(
                AppTypography.titleMedium,
                AppColors.onBackgroundDark,
              ),
              bodyLarge: AppTypography.withColor(
                AppTypography.bodyLarge,
                AppColors.onBackgroundDark,
              ),
              bodyMedium: AppTypography.withColor(
                AppTypography.bodyMedium,
                AppColors.onBackgroundDark,
              ),
            ),

    // Card Theme — ボーダーベース（シャドウなし）
    cardTheme: const CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadius,
        side: BorderSide(color: AppColors.outlineDark, width: 0.5),
      ),
      margin: AppSpacing.cardMargin,
    ),

    // Elevated Button Theme (Dark)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onBackground,
        elevation: AppSpacing.elevationXs,
        shadowColor: Colors.black26,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: AppSpacing.buttonPadding,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, AppSpacing.buttonHeightMd),
      ),
    ),

    // Outlined Button Theme (Dark)
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: const BorderSide(color: AppColors.primaryLight),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: AppSpacing.buttonPadding,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, AppSpacing.buttonHeightMd),
      ),
    ),

    // Text Button Theme (Dark)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        padding: AppSpacing.buttonPaddingSmall,
        textStyle: AppTypography.button,
      ),
    ),

    // Floating Action Button Theme (Dark)
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.onBackground,
      elevation: AppSpacing.elevationSm,
      shape: CircleBorder(),
    ),

    // Input Decoration Theme (Dark) — 温かみのあるサーフェス
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainerDark,
      border: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(color: AppColors.outlineDark),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(color: AppColors.outlineDark),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(
          color: AppColors.primaryLight,
          width: InputConstants.borderWidthFocused,
        ),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(color: AppColors.error),
      ),
      contentPadding: AppSpacing.inputPadding,
      labelStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.onSurfaceDark,
      ),
      hintStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.onSurfaceVariant,
      ),
    ),

    // List Tile Theme (Dark)
    listTileTheme: const ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
      textColor: AppColors.onSurfaceDark,
      iconColor: AppColors.onSurfaceDark,
    ),

    // Icon Theme (Dark)
    iconTheme: const IconThemeData(
      color: AppColors.onSurfaceDark,
      size: AppSpacing.iconMd,
    ),

    // Chip Theme (Dark) — 温かみのあるサーフェス
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceContainerDark,
      labelStyle: AppTypography.withColor(
        AppTypography.tag,
        AppColors.onSurfaceDark,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
    ),

    // Bottom Navigation Bar Theme (Dark) — 控えめな選択色
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: AppColors.onSurfaceDark,
      unselectedItemColor: AppColors.onSurfaceDark.withValues(
        alpha: LabelConstants.unselectedOpacity,
      ),
      selectedIconTheme: const IconThemeData(size: AppSpacing.iconMd),
      unselectedIconTheme: const IconThemeData(size: AppSpacing.iconMd),
      selectedLabelStyle: AppTypography.labelMedium,
      unselectedLabelStyle: AppTypography.labelMedium,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Tab Bar Theme (Dark)
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.onSurfaceDark,
      unselectedLabelColor: AppColors.onSurfaceVariant,
      labelStyle: AppTypography.labelLarge,
      unselectedLabelStyle: AppTypography.labelLarge,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: AppColors.primaryLight,
          width: TabConstants.indicatorThickness,
        ),
      ),
    ),

    // Dialog Theme (Dark)
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceContainerDark,
      elevation: AppSpacing.elevationMd,
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.cardRadiusLarge,
      ),
      titleTextStyle: AppTypography.withColor(
        AppTypography.headlineSmall,
        AppColors.onSurfaceDark,
      ),
      contentTextStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.onSurfaceDark,
      ),
    ),

    // Snack Bar Theme (Dark)
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.onSurfaceDark,
      contentTextStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.surfaceDark,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: AppSpacing.buttonRadius,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
