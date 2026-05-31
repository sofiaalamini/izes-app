import 'package:flutter/material.dart';

class IzesColors {
  static const canvas = Color(0xFFF3F0E6);
  static const surface = Color(0xFFFFFCF7);
  static const surfaceAlt = Color(0xFFF1E8D9);
  static const surfaceSoft = Color(0xFFF7F3EA);
  static const ink = Color(0xFF1E261C);
  static const muted = Color(0xFF64705E);
  static const line = Color(0xFFDCD4C5);
  static const green = Color(0xFF2E6840);
  static const greenDark = Color(0xFF214E30);
  static const greenSoft = Color(0xFFD8E7D8);
  static const earth = Color(0xFF8A5D41);
  static const earthSoft = Color(0xFFF2E4D6);
  static const urgent = Color(0xFF94483B);
  static const urgentSoft = Color(0xFFF4DED7);
  static const attention = Color(0xFF8B7130);
  static const attentionSoft = Color(0xFFF2E8CC);
}

class IzesTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: IzesColors.green,
      onPrimary: Color(0xFFF9F6EF),
      secondary: IzesColors.earth,
      onSecondary: Color(0xFFF9F6EF),
      error: IzesColors.urgent,
      onError: Color(0xFFFFFFFF),
      surface: IzesColors.surface,
      onSurface: IzesColors.ink,
      tertiary: IzesColors.greenSoft,
      onTertiary: IzesColors.green,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: IzesColors.canvas,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
          color: IzesColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: IzesColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          height: 1.1,
          color: IzesColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: IzesColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5, color: IzesColors.ink),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.55,
          color: IzesColors.muted,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: IzesColors.muted,
        ),
        labelMedium: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.35,
          color: IzesColors.muted,
        ),
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: IzesColors.canvas,
        foregroundColor: IzesColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
      ),
      cardTheme: CardThemeData(
        color: IzesColors.surface,
        elevation: 0,
        shadowColor: const Color(0x33203321),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: IzesColors.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: IzesColors.green,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IzesColors.ink,
          side: const BorderSide(color: IzesColors.line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: IzesColors.green,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: IzesColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1A2E6840),
        elevation: 0,
        height: 66,
        indicatorColor: IzesColors.surfaceAlt,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? IzesColors.green
                : IzesColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? IzesColors.green
                : IzesColors.muted,
          ),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: IzesColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: IzesColors.surfaceAlt,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: IzesColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IzesColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IzesColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: IzesColors.green, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
