import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium, modern theme configuration for the Fest'Ja application.
///
/// This theme uses the 'Outfit' Google Font to capture the geometric,
/// premium aesthetic from the design reference, featuring sleek dark navy primary
/// components, clean white cards with soft shadows, and vibrant accent colors/gradients.
class AppTheme {
  AppTheme._();

  // Core Palette
  static const Color primaryDark = Color(
    0xFF0D1B2A,
  ); // Dark navy/slate for primary elements, buttons
  static const Color secondaryPurple = Color(
    0xFF7209B7,
  ); // Vibrant purple for active icons, highlights
  static const Color accentPink = Color(
    0xFFF72585,
  ); // Vibrant pink/magenta for special accents (like favorites)
  static const Color accentGreen = Color(
    0xFF10B981,
  ); // Neon green for badges (e.g., "PAID" badge)
  static const Color backgroundLight = Color(
    0xFFFFFFFF,
  ); // Clean off-white scaffold background for contrast
  static const Color cardLight =
      Colors.white; // Pure white for cards, bottom sheets

  // Text Colors
  static const Color textPrimary = Color(
    0xFF0D1B2A,
  ); // Primary body and title text
  static const Color textSecondary = Color(
    0xFF6B7280,
  ); // Medium muted gray for subtitles
  static const Color textMuted = Color(
    0xFF9CA3AF,
  ); // Light gray for placeholders, helper text

  // Custom Gradient (inspired by the colorful header background in the image)
  static const Gradient headerGradient = LinearGradient(
    colors: [
      Color(0xFF3A0CA3), // Deep indigo
      Color(0xFF7209B7), // Royal purple
      Color(0xFFF72585), // Vibrant pink
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light theme definition
  static ThemeData get lightTheme {
    final baseLightTextTheme = GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundLight,
      dividerColor: Colors.black.withValues(alpha: 0.23),
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.23),
        thickness: 0.5,
      ),

      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: secondaryPurple,
        tertiary: accentPink,
        surface: cardLight,
        error: Colors.redAccent,
      ),

      // Typography setup using GoogleFonts.outfit
      textTheme: baseLightTextTheme.copyWith(
        displayLarge: baseLightTextTheme.displayLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: baseLightTextTheme.displayMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: baseLightTextTheme.displaySmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: baseLightTextTheme.headlineLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineMedium: baseLightTextTheme.headlineMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        headlineSmall: baseLightTextTheme.headlineSmall?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleLarge: baseLightTextTheme.titleLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        titleMedium: baseLightTextTheme.titleMedium?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        titleSmall: baseLightTextTheme.titleSmall?.copyWith(
          color: textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        bodyLarge: baseLightTextTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontSize: 14,
        ),
        bodyMedium: baseLightTextTheme.bodyMedium?.copyWith(
          color: textSecondary,
          fontSize: 13,
        ),
        bodySmall: baseLightTextTheme.bodySmall?.copyWith(
          color: textMuted,
          fontSize: 11,
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryDark),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme with soft shadows and demarcated borders
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.08),
            width: 1.2,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons Theme (Elevated & Outlined)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Capsule style
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark, width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Capsule style
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Chip Theme for Category filters and options
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF3F4F6),
        selectedColor: primaryDark,
        labelStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide.none,
        ),
      ),

      // Text Input Decoration Theme (Search Bar, Location search)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6), // Soft gray background
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: textMuted,
          fontSize: 14,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30), // Fully rounded search field
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: secondaryPurple, width: 1.5),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardLight,
        elevation: 10,
        selectedItemColor: primaryDark,
        unselectedItemColor: textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Dark theme definition for high-end nighttime event browsing
  static ThemeData get darkTheme {
    final baseDarkTextTheme = GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF9D4EDD),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      dividerColor: Colors.white24,
      dividerTheme: const DividerThemeData(
        color: Colors.white24,
        thickness: 0.5,
      ),

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9D4EDD), // Vibrant purple brand color for dark theme
        onPrimary: Colors.white,
        secondary: Color(0xFF7209B7), // Royal purple
        onSecondary: Colors.white,
        tertiary: accentPink,
        onTertiary: Colors.white,
        surface: Color(0xFF1E293B), // Slate 800
        onSurface: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
      ),

      textTheme: baseDarkTextTheme.copyWith(
        displayLarge: baseDarkTextTheme.displayLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: baseDarkTextTheme.displayMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: baseDarkTextTheme.displaySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: baseDarkTextTheme.headlineLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        headlineMedium: baseDarkTextTheme.headlineMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        headlineSmall: baseDarkTextTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        titleLarge: baseDarkTextTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        titleMedium: baseDarkTextTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        titleSmall: baseDarkTextTheme.titleSmall?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        bodyLarge: baseDarkTextTheme.bodyLarge?.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
        bodyMedium: baseDarkTextTheme.bodyMedium?.copyWith(
          color: Colors.white70,
          fontSize: 13,
        ),
        bodySmall: baseDarkTextTheme.bodySmall?.copyWith(
          color: Colors.white54,
          fontSize: 11,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Color(0xFF0F172A),
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.2,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7209B7),
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9D4EDD),
          side: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E293B), // Slate 800
        hintStyle: const TextStyle(
          fontFamily: 'Outfit',
          color: Colors.white38,
          fontSize: 14,
        ),
        prefixIconColor: Colors.white70,
        suffixIconColor: Colors.white70,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F172A),
        elevation: 10,
        selectedItemColor: Color(0xFF9D4EDD),
        unselectedItemColor: Colors.white38,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;

  Color get primaryColor => colorScheme.primary;
  Color get secondaryColor => isDarkMode ? const Color(0xFF9D4EDD) : AppTheme.secondaryPurple;
  Color get tertiaryColor => colorScheme.tertiary; // accentPink
  Color get surfaceColor =>
      colorScheme.surface; // cardLight in light, dark surface in dark
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  Color get textPrimary => textTheme.bodyLarge?.color ?? colorScheme.onSurface;
  Color get textSecondary =>
      textTheme.bodyMedium?.color ?? colorScheme.onSurfaceVariant;
  Color get textMuted => textTheme.bodySmall?.color ?? theme.disabledColor;
  bool get isDarkMode => theme.brightness == Brightness.dark;
}
