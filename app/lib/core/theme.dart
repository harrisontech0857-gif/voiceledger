import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// === Warm, Minimal, Cute Color Palette ===
// Inspired by "Petit a Petit" aesthetic
const Color _warmSeedColor = Color(0xFFE8A87C); // Warm coral/peach
const Color _softLavender = Color(0xFFD4A5D0);
const Color _mintGreen = Color(0xFF85CDCA);
const Color _warmCream = Color(0xFFFFF8F0);
const Color _veryLightWarm = Color(0xFFFFFDF8);
const Color _softRed = Color(0xFFE57373);

// Dark theme warm colors
const Color _darkWarmSurface = Color(0xFF1A1612);
const Color _darkWarmOnSurface = Color(0xFFFFF5E8);

// === Spacing System ===
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// === Radius System ===
abstract class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;
}

// === Theme Mode Provider ===
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == ThemeMode.dark;
});

// === Theme Builder ===
class AppTheme {
  AppTheme._();

  /// Light theme with warm, minimal, cute aesthetic
  static final lightScheme = ColorScheme.fromSeed(
    seedColor: _warmSeedColor,
    brightness: Brightness.light,
    surface: _veryLightWarm,
  );

  /// Dark theme with warm aesthetic (not pure black)
  static final darkScheme = ColorScheme.fromSeed(
    seedColor: _warmSeedColor,
    brightness: Brightness.dark,
    surface: _darkWarmSurface,
  );

  static ThemeData _buildTheme(ColorScheme scheme) {
    // Use a warm, friendly font
    final textTheme = GoogleFonts.poppinsTextTheme(
      ThemeData(colorScheme: scheme).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    ).copyWith(
      bodyMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      // Card Theme - soft, minimal with subtle borders
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(
            color: scheme.outlineVariant.withOpacity(0.3),
            width: 0.5,
          ),
        ),
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      // AppBar Theme - flat, no shadow
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // Elevated Button Theme - warm, rounded, friendly
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          minimumSize: const Size(0, 48),
          shadowColor: Colors.transparent,
        ),
      ),
      // Filled Button Theme - primary accent color
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
        ),
      ),
      // Outlined Button Theme - soft borders
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 48),
        ),
      ),
      // Input Decoration Theme - soft, rounded fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.7)),
      ),
      // Bottom Navigation Bar Theme - transparent, minimal
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: scheme.surface,
        selectedItemColor: scheme.primary,
        unselectedItemColor: scheme.onSurfaceVariant,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
      ),
      // Floating Action Button Theme - soft, warm colors
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        elevation: 0,
        highlightElevation: 0,
      ),
      // Dialog Theme - warm, rounded corners
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      // SnackBar Theme - soft, floating behavior
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.surfaceContainerHighest,
        contentTextStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      // Divider Theme - soft, subtle lines
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withOpacity(0.3),
        thickness: 0.5,
        space: AppSpacing.md,
      ),
      // Chip Theme - cute, rounded chips
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primaryContainer,
        disabledColor: scheme.surfaceContainerLow.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        labelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      // Progress Indicator Theme - warm primary color
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerLow,
        circularTrackColor: scheme.surfaceContainerLow,
      ),
      // Checkbox Theme - rounded, warm accent
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return BorderSide(color: scheme.primary);
          }
          return BorderSide(color: scheme.outlineVariant);
        }),
      ),
      // Radio Theme - warm accent
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            return scheme.primary;
          }
          return scheme.onSurface.withOpacity(0.54);
        }),
      ),
      // Switch Theme - warm primary color
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            return scheme.primary;
          }
          return scheme.outlineVariant;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.selected)) {
            return scheme.primaryContainer;
          }
          return scheme.surfaceContainerLow;
        }),
      ),
      // Tooltip Theme - warm, soft
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  static final lightTheme = _buildTheme(lightScheme);
  static final darkTheme = _buildTheme(darkScheme);
}
