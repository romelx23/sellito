import 'package:flutter/material.dart';

abstract final class SellaColors {
  static const ink = Color(0xFF14161B);
  static const cream = Color(0xFFF4F1EA);
  static const teal = Color(0xFF0F766E);
  static const amber = Color(0xFFF5C451);
  static const muted = Color(0xFF6B7280);
  static const line = Color(0xFFE6E1D6);
  static const white = Colors.white;
  static const danger = Color(0xFFB42318);
}

ThemeData buildSellaTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: SellaColors.teal,
        brightness: Brightness.light,
      ).copyWith(
        primary: SellaColors.teal,
        secondary: SellaColors.amber,
        surface: SellaColors.white,
        onSurface: SellaColors.ink,
        error: SellaColors.danger,
      );

  final text = base.textTheme
      .apply(bodyColor: SellaColors.ink, displayColor: SellaColors.ink)
      .copyWith(
        displaySmall: const TextStyle(
          color: SellaColors.ink,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.1,
          height: 1.08,
        ),
        headlineMedium: const TextStyle(
          color: SellaColors.ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
          height: 1.12,
        ),
        headlineSmall: const TextStyle(
          color: SellaColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -.4,
        ),
        titleLarge: const TextStyle(
          color: SellaColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -.2,
        ),
        titleMedium: const TextStyle(
          color: SellaColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: const TextStyle(
          color: SellaColors.ink,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          fontSize: 12.5,
          color: SellaColors.muted,
          height: 1.4,
        ),
        labelSmall: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: SellaColors.muted,
        ),
      );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: SellaColors.cream,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: SellaColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: SellaColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: SellaColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SellaColors.ink,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SellaColors.ink,
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: SellaColors.line),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SellaColors.teal,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF9A958A)),
      labelStyle: const TextStyle(color: SellaColors.muted, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SellaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SellaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SellaColors.teal, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SellaColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SellaColors.danger, width: 1.6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: SellaColors.amber.withValues(alpha: .28),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? SellaColors.ink
              : SellaColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 23,
          color: states.contains(WidgetState.selected)
              ? SellaColors.ink
              : SellaColors.muted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: SellaColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SellaColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13.5),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: SellaColors.line, thickness: 1),
  );
}

extension ColorX on Color {
  Color darken([double amount = .18]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color lighten([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color get onColor =>
      ThemeData.estimateBrightnessForColor(this) == Brightness.dark
      ? Colors.white
      : SellaColors.ink;
}
