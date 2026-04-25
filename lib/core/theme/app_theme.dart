import 'package:flutter/material.dart';

/// Paleta unificada. Se toma como referencia el verde neón más oscuro (#6ee718)
/// que aparece en la mayoría de pantallas, como color primario canónico.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF6EE718);
  static const background = Color(0xFF0D110E);
  static const surface = Color(0xFF161B14);
  static const surfaceVariant = Color(0xFF1D2616);
  static const border = Color(0xFF2F3829);
  static const onBackground = Color(0xFFF7F8F6);
  static const onSurface = Color(0xFFE6E6E6);
  static const muted = Color(0xFF8B9A8F);
  static const error = Color(0xFFFFB4AB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.primary,
      onSecondary: AppColors.background,
      error: AppColors.error,
      onError: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'SpaceGrotesk',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppColors.onBackground,
        ),
      ),

      // BottomNavigationBar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0B110D),
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: isSelected ? AppColors.primary : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected ? AppColors.primary : AppColors.muted,
            size: 24,
          );
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
        prefixIconColor: AppColors.muted,
      ),

      // ElevatedButton (botón primario)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      // OutlinedButton (botón secundario)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),

      // Chips (para etiquetas/tags)
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w700, fontSize: 18),
        titleMedium: TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w600, fontSize: 15),
        bodyLarge: TextStyle(color: AppColors.onSurface, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.muted, fontSize: 11),
        labelSmall: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.0),
      ),
    );
  }
}
