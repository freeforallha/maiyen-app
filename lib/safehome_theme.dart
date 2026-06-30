import 'package:flutter/material.dart';

class SafeHomeColors {
  const SafeHomeColors._();

  static const Color primary = Color(0xFF167D5A);
  static const Color primaryDark = Color(0xFF0F5E43);
  static const Color primarySoft = Color(0xFFE7F5EF);

  static const Color background = Color(0xFFF5F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEDF3F0);
  static const Color border = Color(0xFFDDE7E2);

  static const Color textPrimary = Color(0xFF18201D);
  static const Color textSecondary = Color(0xFF69746F);

  static const Color safe = primary;
  static const Color warning = Color(0xFFE99822);
  static const Color danger = Color(0xFFD94A4A);
  static const Color info = Color(0xFF3B82D0);
}

class SafeHomeTheme {
  const SafeHomeTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: SafeHomeColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: SafeHomeColors.primary,
      onPrimary: Colors.white,
      primaryContainer: SafeHomeColors.primarySoft,
      onPrimaryContainer: SafeHomeColors.primaryDark,
      secondary: SafeHomeColors.info,
      onSecondary: Colors.white,
      surface: SafeHomeColors.surface,
      onSurface: SafeHomeColors.textPrimary,
      error: SafeHomeColors.danger,
      onError: Colors.white,
      outline: SafeHomeColors.border,
      outlineVariant: SafeHomeColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SafeHomeColors.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
        headlineSmall: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
        ),
        titleLarge: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.25,
        ),
        titleMedium: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        bodyMedium: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        bodySmall: const TextStyle(
          color: SafeHomeColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: SafeHomeColors.textPrimary,
        iconTheme: IconThemeData(
          color: SafeHomeColors.textPrimary,
          size: 24,
        ),
        titleTextStyle: TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: SafeHomeColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
            color: SafeHomeColors.border,
            width: 0.8,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SafeHomeColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        hintStyle: const TextStyle(
          color: SafeHomeColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: SafeHomeColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: SafeHomeColors.primary,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: SafeHomeColors.textSecondary,
        suffixIconColor: SafeHomeColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SafeHomeColors.primary,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SafeHomeColors.danger,
            width: 1.2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SafeHomeColors.danger,
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: SafeHomeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          backgroundColor: SafeHomeColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: SafeHomeColors.primary,
          side: const BorderSide(
            color: SafeHomeColors.border,
            width: 1.2,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SafeHomeColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: SafeHomeColors.textPrimary,
          backgroundColor: SafeHomeColors.surface,
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SafeHomeColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: SafeHomeColors.surface,
        modalBarrierColor: Color(0x660F1814),
        showDragHandle: false,
        dragHandleColor: SafeHomeColors.border,
        dragHandleSize: Size(44, 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SafeHomeColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: const TextStyle(
          color: SafeHomeColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: SafeHomeColors.textSecondary,
        textColor: SafeHomeColors.textPrimary,
        titleTextStyle: TextStyle(
          color: SafeHomeColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: TextStyle(
          color: SafeHomeColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: SafeHomeColors.surfaceSoft,
        selectedColor: SafeHomeColors.primarySoft,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          color: SafeHomeColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: SafeHomeColors.primary,
          fontWeight: FontWeight.w800,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SafeHomeColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: SafeHomeColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: SafeHomeColors.primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: SafeHomeColors.primary,
              size: 24,
            );
          }

          return const IconThemeData(
            color: SafeHomeColors.textSecondary,
            size: 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? SafeHomeColors.primary
                : SafeHomeColors.textSecondary,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SafeHomeColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
