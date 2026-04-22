import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF6C63FF);
  static const primaryDark = Color(0xFF4B44CC);
  static const primaryLight = Color(0xFFEEEDFF);
  static const secondary = Color(0xFF2DD4BF);
  static const background = Color(0xFFF5F6FA);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFFF4757);
  static const warning = Color(0xFFFFB142);
  static const success = Color(0xFF26D782);

  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF8892A4);
  static const textHint = Color(0xFFBFC6D1);

  static const inputFill = Color(0xFFF0F1F5);
  static const divider = Color(0xFFE8EAF0);
  static const cardBorder = Color(0xFFF0F1F5);

  // Modern Dark Theme Colors
  static const bgDark = Color(0xFF09090E);
  static const cardDark = Color(0xFF16161F);
  static const accentBlue = Color(0xFF00E5FF);
  static const accentMagenta = Color(0xFFFF00FF);
  static const glassBorder = Color(0x1AFFFFFF);

  // Stat card accent colors
  static const statBlue = Color(0xFF4E91F9);
  static const statGreen = Color(0xFF26D782);
  static const statOrange = Color(0xFFFFB142);
  static const statPurple = Color(0xFF9B59B6);
}

class AppTheme {
  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
      brightness: Brightness.light,
    ).copyWith(
      surfaceContainerHighest: AppColors.inputFill,
      outline: AppColors.divider,
    );

    return _buildTheme(base, AppColors.background);
  }

  static ThemeData get dark {
    final base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.cardDark,
      onSurface: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      brightness: Brightness.dark,
    ).copyWith(
      surfaceContainerHighest: Colors.white10,
      outline: Colors.white12,
    );

    return _buildTheme(base, AppColors.bgDark);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Color scaffoldBg) {
    final isDark = colorScheme.brightness == Brightness.dark;
    
    final textTheme = GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15, fontWeight: FontWeight.w400, color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w400, color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: scaffoldBg,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.transparent : AppColors.surface,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: isDark ? Colors.transparent : AppColors.divider,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: isDark ? AppColors.accentBlue : AppColors.textPrimary),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? AppColors.glassBorder : AppColors.cardBorder, 
            width: 1
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w400, color: isDark ? Colors.white24 : AppColors.textHint,
        ),
        prefixIconColor: isDark ? Colors.white54 : AppColors.textSecondary,
        suffixIconColor: isDark ? Colors.white54 : AppColors.textSecondary,
        floatingLabelStyle: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary,
        ),
      ),

      // Filled buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.5) : AppColors.textSecondary,
        ),
        iconColor: isDark ? AppColors.accentBlue : AppColors.textSecondary,
      ),

      // Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
      ),

      // SNR
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? Colors.grey[900] : AppColors.textPrimary,
        contentTextStyle: GoogleFonts.poppins(
          fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
