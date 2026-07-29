import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A premium, modern theme configuration for the iFest application.
/// 
/// This theme uses the 'Outfit' Google Font to capture the geometric,
/// premium aesthetic from the design reference, featuring sleek dark navy primary
/// components, clean white cards with soft shadows, and vibrant accent colors/gradients.
class AppTheme {
  AppTheme._();

  // Core Palette
  static const Color primaryDark = Color(0xFF0D1B2A); // Dark navy/slate for primary elements, buttons
  static const Color secondaryPurple = Color(0xFF7209B7); // Vibrant purple for active icons, highlights
  static const Color accentPink = Color(0xFFF72585); // Vibrant pink/magenta for special accents (like favorites)
  static const Color accentGreen = Color(0xFF10B981); // Neon green for badges (e.g., "PAID" badge)
  static const Color backgroundLight = Color(0xFFFFFFFF); // Pure white scaffold background
  static const Color cardLight = Colors.white; // Pure white for cards, bottom sheets
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0D1B2A); // Primary body and title text
  static const Color textSecondary = Color(0xFF6B7280); // Medium muted gray for subtitles
  static const Color textMuted = Color(0xFF9CA3AF); // Light gray for placeholders, helper text

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
    colors: [
      Color(0xFF1E293B),
      Color(0xFF0F172A),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light theme definition
  static ThemeData get lightTheme {
    final baseLightTextTheme = GoogleFonts.outfitTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: backgroundLight,
      
      colorScheme: const ColorScheme.light(
        primary: primaryDark,
        secondary: secondaryPurple,
        tertiary: accentPink,
        surface: cardLight,
        error: Colors.redAccent,
      ),

      // Typography setup using GoogleFonts.outfit
      textTheme: baseLightTextTheme.copyWith(
        displayLarge: baseLightTextTheme.displayLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        displayMedium: baseLightTextTheme.displayMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        displaySmall: baseLightTextTheme.displaySmall?.copyWith(color: textPrimary, fontWeight: FontWeight.bold),
        headlineLarge: baseLightTextTheme.headlineLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: baseLightTextTheme.headlineMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        headlineSmall: baseLightTextTheme.headlineSmall?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        titleLarge: baseLightTextTheme.titleLarge?.copyWith(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        titleMedium: baseLightTextTheme.titleMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
        titleSmall: baseLightTextTheme.titleSmall?.copyWith(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: baseLightTextTheme.bodyLarge?.copyWith(color: textPrimary, fontSize: 14),
        bodyMedium: baseLightTextTheme.bodyMedium?.copyWith(color: textSecondary, fontSize: 13),
        bodySmall: baseLightTextTheme.bodySmall?.copyWith(color: textMuted, fontSize: 11),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryDark),
        titleTextStyle: TextStyle(
          color: primaryDark,
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme with soft shadows matching the design
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      // Buttons Theme (Elevated & Outlined)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56), // Standard tall button height in design
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
          minimumSize: const Size.fromHeight(56),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
    final baseDarkTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Slate 900
      
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: Color(0xFF9D4EDD), // Lighter purple for dark theme visibility
        tertiary: accentPink,
        surface: Color(0xFF1E293B), // Slate 800
        error: Colors.redAccent,
      ),

      textTheme: baseDarkTextTheme.copyWith(
        displayLarge: baseDarkTextTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        displayMedium: baseDarkTextTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        displaySmall: baseDarkTextTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        headlineLarge: baseDarkTextTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: baseDarkTextTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        headlineSmall: baseDarkTextTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        titleLarge: baseDarkTextTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        titleMedium: baseDarkTextTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        titleSmall: baseDarkTextTheme.titleSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12),
        bodyLarge: baseDarkTextTheme.bodyLarge?.copyWith(color: Colors.white, fontSize: 14),
        bodyMedium: baseDarkTextTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 13),
        bodySmall: baseDarkTextTheme.bodySmall?.copyWith(color: Colors.white54, fontSize: 11),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
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
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 1.5),
          minimumSize: const Size.fromHeight(56),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        selectedItemColor: Colors.white,
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
