import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Modern Backgrounds
  static const Color scaffoldBg = Color(0xFFFAFAFA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color surfaceBg = Color(0xFFF5F5F7);
  static const Color overlayBg = Color(0xFFF9FAFB);

  // Premium Brand Colors - Inspired by Stripe/Linear
  static const Color primary = Color(0xFF635BFF);
  static const Color primaryLight = Color(0xFFE8E7FF);
  static const Color primaryDark = Color(0xFF4B44CC);
  static const Color primaryAccent = Color(0xFF7C75FF);

  // Sophisticated Neutrals
  static const Color navy = Color(0xFF0A2540);
  static const Color textPrimary = Color(0xFF171923);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Status Colors - Premium palette
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);
  
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);
  
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);
  
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF635BFF), Color(0xFF7C75FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF111827)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Backward compatibility
  static const Color accent = primary;
  static const Color background = scaffoldBg;
  static const Color surface = cardBg;
  static const Color darkBg = scaffoldBg;
  static const Color purple = primary;
  static const Color teal = Color(0xFF14B8A6);
  static const Color cyan = Color(0xFF06B6D4);
  static const Color pink = Color(0xFFEC4899);
  static const Color cardSurface = cardBg;
  static const LinearGradient secondaryGradient = successGradient;
}

class AppTextStyles {
  // Display & Headings - Premium typography
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1,
    height: 1.2,
  );

  static TextStyle get heading => GoogleFonts.inter(
    fontSize: 26, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
    height: 1.3,
  );

  static TextStyle get subHeading => GoogleFonts.inter(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: -0.2,
    height: 1.4,
  );

  // Body Text
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary, height: 1.5,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.5,
  );

  // Small Text
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary, letterSpacing: 0.15,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textTertiary, letterSpacing: 0.2,
  );

  static TextStyle get overline => GoogleFonts.inter(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textTertiary, letterSpacing: 0.8,
    height: 1.2,
  );

  // Special Uses
  static TextStyle get metricValue => GoogleFonts.inter(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -1,
    height: 1.2,
  );

  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.2,
  );

  static TextStyle get buttonLarge => GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, letterSpacing: 0.2,
  );

  // Backward compatibility
  static TextStyle get header => heading;
  static TextStyle get subHeader => body;
  static TextStyle get metricLabel => label;
}

class AppShadows {
  // Sophisticated shadow system
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 12),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get premium => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.08),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get glow => [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 2,
    ),
  ];

  // Backward compatibility
  static List<BoxShadow> get cardShadow => card;
  static List<BoxShadow> get subtleShadow => subtle;
  static List<BoxShadow> get elevatedShadow => elevated;
}

// Premium Theme Data
class AppTheme {
  // ═══════ DARK COLOR TOKENS ═══════
  static const Color _darkScaffold = Color(0xFF0F0F14);
  static const Color _darkCard = Color(0xFF1A1A24);
  static const Color _darkSurface = Color(0xFF15151E);
  static const Color _darkBorder = Color(0xFF2A2A3A);
  static const Color _darkTextPrimary = Color(0xFFF0F0F5);
  static const Color _darkTextSecondary = Color(0xFFA0A0B0);
  static const Color _darkTextTertiary = Color(0xFF6B6B80);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.success,
      surface: AppColors.cardBg,
      error: AppColors.error,
    ),
    
    scaffoldBackgroundColor: AppColors.scaffoldBg,
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardBg,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppTextStyles.subHeading,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.05),
    ),
    
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      margin: EdgeInsets.zero,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: AppTextStyles.button.copyWith(color: AppColors.textPrimary),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textTertiary),
      labelStyle: AppTextStyles.bodyMedium,
    ),
    
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceBg,
      disabledColor: AppColors.surfaceBg.withValues(alpha: 0.5),
      selectedColor: AppColors.primaryLight,
      secondarySelectedColor: AppColors.primaryLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: AppTextStyles.label,
      secondaryLabelStyle: AppTextStyles.label,
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  // ═══════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.inter().fontFamily,

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.success,
      surface: _darkCard,
      error: AppColors.error,
    ),

    scaffoldBackgroundColor: _darkScaffold,

    appBarTheme: AppBarTheme(
      backgroundColor: _darkCard,
      foregroundColor: _darkTextPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18, fontWeight: FontWeight.w600,
        color: _darkTextPrimary, letterSpacing: -0.2,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      surfaceTintColor: Colors.transparent,
    ),

    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: _darkBorder.withValues(alpha: 0.6)),
      ),
      margin: EdgeInsets.zero,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppTextStyles.button,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkTextPrimary,
        side: const BorderSide(color: _darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkBorder.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(color: _darkTextTertiary, fontSize: 14),
      labelStyle: GoogleFonts.inter(color: _darkTextSecondary, fontSize: 14, fontWeight: FontWeight.w500),
    ),

    dividerTheme: DividerThemeData(
      color: _darkBorder.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _darkSurface,
      disabledColor: _darkSurface.withValues(alpha: 0.5),
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      secondarySelectedColor: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: GoogleFonts.inter(color: _darkTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      brightness: Brightness.dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkCard,
      surfaceTintColor: Colors.transparent,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: _darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: _darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkCard,
      contentTextStyle: GoogleFonts.inter(color: _darkTextPrimary, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Extension for easy dark-aware color access.
/// Usage: `final c = Theme.of(context).pcc;`
extension PccColors on ThemeData {
  PccColorSet get pcc => brightness == Brightness.dark
      ? const PccColorSet(
          scaffold: AppTheme._darkScaffold,
          card: AppTheme._darkCard,
          surface: AppTheme._darkSurface,
          border: AppTheme._darkBorder,
          textPrimary: AppTheme._darkTextPrimary,
          textSecondary: AppTheme._darkTextSecondary,
          textTertiary: AppTheme._darkTextTertiary,
          toggleBg: AppTheme._darkSurface,
          toggleActive: AppTheme._darkCard,
          fieldFill: AppTheme._darkSurface,
          fieldBorder: AppTheme._darkBorder,
          navBg: AppTheme._darkCard,
          navBorder: AppTheme._darkBorder,
        )
      : const PccColorSet(
          scaffold: AppColors.scaffoldBg,
          card: AppColors.cardBg,
          surface: AppColors.surfaceBg,
          border: AppColors.border,
          textPrimary: AppColors.textPrimary,
          textSecondary: AppColors.textSecondary,
          textTertiary: AppColors.textTertiary,
          toggleBg: Color(0xFFF3F4F6),
          toggleActive: AppColors.cardBg,
          fieldFill: Color(0xFFF9FAFB),
          fieldBorder: Color(0xFFE5E7EB),
          navBg: AppColors.cardBg,
          navBorder: Color(0xFFE5E7EB),
        );
}

class PccColorSet {
  final Color scaffold;
  final Color card;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color toggleBg;
  final Color toggleActive;
  final Color fieldFill;
  final Color fieldBorder;
  final Color navBg;
  final Color navBorder;

  const PccColorSet({
    required this.scaffold,
    required this.card,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.toggleBg,
    required this.toggleActive,
    required this.fieldFill,
    required this.fieldBorder,
    required this.navBg,
    required this.navBorder,
  });
}
