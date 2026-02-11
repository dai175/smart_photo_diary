import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import '../component_constants.dart';

/// ライトテーマの ThemeData を構築する
ThemeData buildLightTheme({required bool isTestEnv}) {
  if (isTestEnv) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
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
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTypography.withColor(
        AppTypography.appTitle,
        Colors.white,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // Text Theme - Google Fonts in production, system font in tests
    textTheme:
        (isTestEnv
                ? ThemeData.light().textTheme
                : GoogleFonts.notoSansJpTextTheme(ThemeData.light().textTheme))
            .copyWith(
              headlineLarge: AppTypography.headlineLarge,
              headlineMedium: AppTypography.headlineMedium,
              headlineSmall: AppTypography.headlineSmall,
              titleLarge: AppTypography.titleLarge,
              titleMedium: AppTypography.titleMedium,
              bodyLarge: AppTypography.bodyLarge,
              bodyMedium: AppTypography.bodyMedium,
            ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: AppSpacing.elevationSm,
      shadowColor: AppColors.shadow,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
      margin: AppSpacing.cardMargin,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppSpacing.elevationSm,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        padding: AppSpacing.buttonPadding,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, AppSpacing.buttonHeightMd),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        padding: AppSpacing.buttonPadding,
        textStyle: AppTypography.button,
        minimumSize: const Size(0, AppSpacing.buttonHeightMd),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
        padding: AppSpacing.buttonPaddingSmall,
        textStyle: AppTypography.button,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: AppSpacing.elevationMd,
      shape: CircleBorder(),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: InputConstants.borderWidthFocused,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppSpacing.inputRadius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: AppSpacing.inputPadding,
      labelStyle: AppTypography.bodyMedium,
      hintStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.onSurfaceVariant,
      ),
    ),

    // List Tile Theme
    listTileTheme: const ListTileThemeData(
      contentPadding: AppSpacing.listItemPadding,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.onSurface,
      size: AppSpacing.iconMd,
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primaryContainer,
      labelStyle: AppTypography.withColor(
        AppTypography.tag,
        AppColors.onPrimaryContainer,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.chipRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant.withValues(
        alpha: LabelConstants.unselectedOpacity,
      ),
      selectedIconTheme: const IconThemeData(size: AppSpacing.iconMd),
      unselectedIconTheme: const IconThemeData(size: AppSpacing.iconMd),
      selectedLabelStyle: AppTypography.labelMedium,
      unselectedLabelStyle: AppTypography.labelMedium,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.onSurfaceVariant,
      labelStyle: AppTypography.labelLarge,
      unselectedLabelStyle: AppTypography.labelLarge,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(
          color: AppColors.primary,
          width: TabConstants.indicatorThickness,
        ),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: AppSpacing.elevationLg,
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadiusLarge),
      titleTextStyle: AppTypography.withColor(
        AppTypography.headlineSmall,
        AppColors.onSurface,
      ),
      contentTextStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.onSurface,
      ),
    ),

    // Snack Bar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.onSurface,
      contentTextStyle: AppTypography.withColor(
        AppTypography.bodyMedium,
        AppColors.surface,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.buttonRadius),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
