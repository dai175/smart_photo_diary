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

    // Color Scheme
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
      onSurface: AppColors.onSurfaceDark,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      shadow: AppColors.shadow,
    ),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.onSurfaceDark,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.withColor(
        AppTypography.appTitle,
        AppColors.onSurfaceDark,
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

    // Card Theme
    cardTheme: const CardThemeData(
      color: AppColors.surfaceDark,
      elevation: AppSpacing.elevationSm,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
      margin: AppSpacing.cardMargin,
    ),

    // Elevated Button Theme (Dark)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onBackground,
        elevation: AppSpacing.elevationSm,
        shadowColor: Colors.black54,
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
      elevation: AppSpacing.elevationMd,
      shape: CircleBorder(),
    ),

    // Input Decoration Theme (Dark)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.primaryDark,
      border: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(color: AppColors.outline),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: BorderSide(color: AppColors.outline),
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

    // Chip Theme (Dark)
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryDark,
      labelStyle: AppTypography.withColor(
        AppTypography.tag,
        AppColors.primaryLight,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
    ),

    // Bottom Navigation Bar Theme (Dark)
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      // ダークは onSurfaceVariant だと暗すぎるため、基準色を onSurfaceDark に変更
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
      labelColor: AppColors.primaryLight,
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
      backgroundColor: AppColors.surfaceDark,
      elevation: AppSpacing.elevationLg,
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
