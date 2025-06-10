import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Smart Photo Diary アプリケーションのテーマ設定
/// Material Design 3 に基づいたライト・ダークテーマを提供
class AppTheme {
  AppTheme._();

  // ============= LIGHT THEME =============
  static ThemeData get lightTheme {
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
        centerTitle: true,
        titleTextStyle: AppTypography.withColor(AppTypography.appTitle, Colors.white),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppSpacing.elevationSm,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        margin: AppSpacing.cardMargin,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppSpacing.elevationSm,
          shadowColor: AppColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
          padding: AppSpacing.buttonPadding,
          textStyle: AppTypography.button,
          minimumSize: const Size(0, AppSpacing.buttonHeightMd),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.buttonRadius,
          ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.inputRadius,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: AppSpacing.inputPadding,
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.withColor(AppTypography.bodyMedium, AppColors.onSurfaceVariant),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: AppSpacing.listItemPadding,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: AppSpacing.iconMd,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        labelStyle: AppTypography.withColor(AppTypography.tag, AppColors.onPrimaryContainer),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.chipRadius,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: AppSpacing.elevationSm,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: AppSpacing.elevationLg,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadiusLarge,
        ),
        titleTextStyle: AppTypography.withColor(AppTypography.headlineSmall, AppColors.onSurface),
        contentTextStyle: AppTypography.withColor(AppTypography.bodyMedium, AppColors.onSurface),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.onSurface,
        contentTextStyle: AppTypography.withColor(AppTypography.bodyMedium, AppColors.surface),
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.buttonRadius,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============= DARK THEME =============
  static ThemeData get darkTheme {
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
        centerTitle: true,
        titleTextStyle: AppTypography.withColor(AppTypography.appTitle, AppColors.onSurfaceDark),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTypography.withColor(AppTypography.displayLarge, AppColors.onBackgroundDark),
        displayMedium: AppTypography.withColor(AppTypography.displayMedium, AppColors.onBackgroundDark),
        displaySmall: AppTypography.withColor(AppTypography.displaySmall, AppColors.onBackgroundDark),
        headlineLarge: AppTypography.withColor(AppTypography.headlineLarge, AppColors.onBackgroundDark),
        headlineMedium: AppTypography.withColor(AppTypography.headlineMedium, AppColors.onBackgroundDark),
        headlineSmall: AppTypography.withColor(AppTypography.headlineSmall, AppColors.onBackgroundDark),
        titleLarge: AppTypography.withColor(AppTypography.titleLarge, AppColors.onBackgroundDark),
        titleMedium: AppTypography.withColor(AppTypography.titleMedium, AppColors.onBackgroundDark),
        titleSmall: AppTypography.withColor(AppTypography.titleSmall, AppColors.onBackgroundDark),
        bodyLarge: AppTypography.withColor(AppTypography.bodyLarge, AppColors.onBackgroundDark),
        bodyMedium: AppTypography.withColor(AppTypography.bodyMedium, AppColors.onBackgroundDark),
        bodySmall: AppTypography.withColor(AppTypography.bodySmall, AppColors.onBackgroundDark),
        labelLarge: AppTypography.withColor(AppTypography.labelLarge, AppColors.onBackgroundDark),
        labelMedium: AppTypography.withColor(AppTypography.labelMedium, AppColors.onBackgroundDark),
        labelSmall: AppTypography.withColor(AppTypography.labelSmall, AppColors.onBackgroundDark),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: AppSpacing.elevationSm,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.cardRadius,
        ),
        margin: AppSpacing.cardMargin,
      ),

      // その他のテーマ設定はライトテーマと同様...
    );
  }

  // ============= HELPER METHODS =============
  /// 現在のテーマがダークかどうかを判定
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// カスタムテーマデータを作成
  static ThemeData createCustomTheme({
    required Color primaryColor,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: brightness == Brightness.light
          ? lightTheme.textTheme
          : darkTheme.textTheme,
    );
  }

  /// グラデーション背景を作成
  static Widget createGradientBackground({
    required Widget child,
    Gradient? gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.modernHomeGradient,
      ),
      child: child,
    );
  }

  /// ブラー効果付きコンテナを作成
  static Widget createBlurContainer({
    required Widget child,
    double blurAmount = 10.0,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface.withValues(alpha: 0.8),
        borderRadius: AppSpacing.cardRadius,
        boxShadow: AppSpacing.cardShadow,
      ),
      child: child,
    );
  }
}