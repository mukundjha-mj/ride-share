import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ═══════════════════════════════════════════════════════════════
  // TWITTER-STYLE THEME
  // Clean. Modern. Professional.
  // ═══════════════════════════════════════════════════════════════

  // Primary - Twitter Blue
  static const Color primaryColor = Color(0xFF1E9DF1);

  // Secondary - Green (Success)
  static const Color secondaryColor = Color(0xFF00B87A);

  // Destructive - Red
  static const Color errorColor = Color(0xFFF4212E);

  // Success - Green
  static const Color successColor = Color(0xFF00B87A);

  // Warning - Yellow
  static const Color warningColor = Color(0xFFF7B928);

  // ═══════════════════════════════════════════════════════════════
  // LIGHT MODE
  // ═══════════════════════════════════════════════════════════════

  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightForeground = Color(0xFF0F1419);
  static const Color lightCard = Color(0xFFF7F8F8);
  static const Color lightCardForeground = Color(0xFF0F1419);
  static const Color lightMuted = Color(0xFFE5E5E6);
  static const Color lightMutedForeground = Color(0xFF0F1419);
  static const Color lightAccent = Color(0xFFE3ECF6);
  static const Color lightAccentForeground = Color(0xFF1E9DF1);
  static const Color lightBorder = Color(0xFFE1EAEF);
  static const Color lightInput = Color(0xFFF7F9FA);

  // ═══════════════════════════════════════════════════════════════
  // DARK MODE
  // ═══════════════════════════════════════════════════════════════

  static const Color darkBackground = Color(0xFF000000);
  static const Color darkForeground = Color(0xFFE7E9EA);
  static const Color darkCard = Color(0xFF17181C);
  static const Color darkCardForeground = Color(0xFFD9D9D9);
  static const Color darkMuted = Color(0xFF181818);
  static const Color darkMutedForeground = Color(0xFF72767A);
  static const Color darkAccent = Color(0xFF061622);
  static const Color darkAccentForeground = Color(0xFF1C9CF0);
  static const Color darkBorder = Color(0xFF242628);
  static const Color darkInput = Color(0xFF22303C);

  // ═══════════════════════════════════════════════════════════════
  // CHAT COLORS
  // ═══════════════════════════════════════════════════════════════

  static const Color chatOutgoing = primaryColor;
  static const Color chatOutgoingText = Colors.white;
  static const Color chatIncomingLight = lightCard;
  static const Color chatIncomingDark = darkCard;

  // ═══════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: lightForeground,
        surface: lightCard,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightForeground,
        outline: lightBorder,
      ),
      textTheme: _buildTextTheme(lightForeground, lightMutedForeground),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _outlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: lightInput,
        borderColor: lightBorder,
        hintColor: lightMutedForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightForeground,
        ),
        iconTheme: const IconThemeData(color: lightForeground),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: lightAccent,
        labelStyle: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: lightAccentForeground,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: darkForeground,
        surface: darkCard,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: darkBackground,
        onSurface: darkForeground,
        outline: darkBorder,
      ),
      textTheme: _buildTextTheme(darkForeground, darkMutedForeground),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: _elevatedButtonTheme(),
      outlinedButtonTheme: _darkOutlinedButtonTheme(),
      textButtonTheme: _textButtonTheme(),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: darkInput,
        borderColor: darkBorder,
        hintColor: darkMutedForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkForeground,
        ),
        iconTheme: const IconThemeData(color: darkForeground),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkCard,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: darkAccent,
        labelStyle: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: darkAccentForeground,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED COMPONENTS
  // ═══════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.openSansTextTheme().copyWith(
      headlineLarge: GoogleFonts.openSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.openSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: GoogleFonts.openSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.openSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      bodySmall: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.openSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelMedium: GoogleFonts.openSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _darkOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.openSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: GoogleFonts.openSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.openSans(color: hintColor, fontSize: 14),
    );
  }
}
