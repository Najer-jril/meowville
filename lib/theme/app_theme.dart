import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Token warna. Ubah `primary` jika hex asli dari mockup Stitch berbeda.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0F766E);
  static const primarySoft = Color(0xFFCCEFEA);
  static const secondary = Color(0xFFF59E6B);
  static const secondarySoft = Color(0xFFFFE4D2);
  static const accent = Color(0xFFFFC94D);

  static const bg = Color(0xFFFAF8F4);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0EEE8);
  static const border = Color(0xFFE5E7EB);

  static const text = Color(0xFF1F2937);
  static const muted = Color(0xFF6B7280);

  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF0284C7);
  static const infoSoft = Color(0xFFE0F2FE);

  static const adminRole = Color(0xFFB45309);

  // Warna tambahan untuk ilustrasi SVG di layar auth.
  static const primaryMuted = Color(0xFF80D5CB);
  static const primaryDeep = Color(0xFF00504A);
  static const catBrown = Color(0xFF904C20);
  static const catNose = Color(0xFFFFA673);
  static const cream = Color(0xFFFFFDF9);
  static const keyGold = Color(0xFFFFDF9F);
  static const whisker = Color(0xFFBDC9C6);

  /// Hex `#RRGGBB` untuk disisipkan ke string SVG.
  static String svg(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

class AppRadius {
  AppRadius._();

  static const double card = 20;
  static const double button = 16;
  static const double input = 14;
  static const double checkbox = 8;
  static const double pill = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double page = 20;
}

class AppShadows {
  AppShadows._();

  /// 0 4 16 rgba(15,118,110,0.08)
  static const soft = [
    BoxShadow(
      color: Color(0x140F766E),
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];
}

/// Pasangan warna teks + latar untuk badge.
class BadgeStyle {
  final Color fg;
  final Color bg;
  const BadgeStyle(this.fg, this.bg);
}

class AppBadges {
  AppBadges._();

  /// status: pending | confirmed | checked_in | completed | rejected | cancelled
  static BadgeStyle booking(String status) {
    switch (status) {
      case 'pending':
        return const BadgeStyle(AppColors.warning, AppColors.warningSoft);
      case 'confirmed':
        return const BadgeStyle(AppColors.success, AppColors.successSoft);
      case 'checked_in':
        return const BadgeStyle(AppColors.info, AppColors.infoSoft);
      case 'completed':
        return const BadgeStyle(AppColors.muted, AppColors.surfaceAlt);
      case 'rejected':
      case 'cancelled':
        return const BadgeStyle(AppColors.danger, AppColors.dangerSoft);
      default:
        return const BadgeStyle(AppColors.muted, AppColors.surfaceAlt);
    }
  }

  static String bookingLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'checked_in':
        return 'Sedang Menginap';
      case 'completed':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// role: owner | admin | sitter
  static BadgeStyle role(String role) {
    switch (role) {
      case 'admin':
        return const BadgeStyle(AppColors.adminRole, AppColors.secondarySoft);
      case 'sitter':
        return const BadgeStyle(AppColors.info, AppColors.infoSoft);
      default:
        return const BadgeStyle(AppColors.primary, AppColors.primarySoft);
    }
  }

  static String roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'sitter':
        return 'Pet Sitter';
      default:
        return 'Pemilik';
    }
  }

  /// mood: Ceria | Tenang | Lesu | Gelisah
  static BadgeStyle mood(String mood) {
    switch (mood) {
      case 'Ceria':
        return const BadgeStyle(AppColors.success, AppColors.successSoft);
      case 'Tenang':
        return const BadgeStyle(AppColors.info, AppColors.infoSoft);
      case 'Lesu':
        return const BadgeStyle(AppColors.warning, AppColors.warningSoft);
      case 'Gelisah':
        return const BadgeStyle(AppColors.danger, AppColors.dangerSoft);
      default:
        return const BadgeStyle(AppColors.muted, AppColors.surfaceAlt);
    }
  }
}

/// Gaya teks tambahan di luar TextTheme.
class AppText {
  AppText._();

  /// Overline: 13 semibold, sentence case (bukan huruf kapital semua).
  static TextStyle get overline => GoogleFonts.nunitoSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  /// Font display untuk judul besar, dipasangkan dengan Nunito Sans di body.
  static TextStyle display({required double size}) => GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -size * 0.02,
        color: AppColors.text,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondarySoft,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        surfaceContainerHighest: AppColors.surfaceAlt,
        outline: AppColors.border,
        error: AppColors.danger,
        errorContainer: AppColors.dangerSoft,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    // google_fonts 9 memakai TextTheme dari material_ui, jadi pasang font lewat apply.
    final textTheme = base.textTheme
        .apply(fontFamily: GoogleFonts.nunitoSans().fontFamily)
        .copyWith(
      // H1 30 Fraunces SemiBold
      headlineLarge: AppText.display(size: 30),
      // H2 23 Fraunces SemiBold
      headlineMedium: AppText.display(size: 23),
      // H3 18 SemiBold
      titleLarge: GoogleFonts.nunitoSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text),
      // Body 16
      bodyLarge: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.text),
      bodyMedium: GoogleFonts.nunitoSans(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.text),
      // Caption 13
      bodySmall: GoogleFonts.nunitoSans(
          fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.muted),
      labelLarge: GoogleFonts.nunitoSans(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
      labelSmall: GoogleFonts.nunitoSans(
          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
    );

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle:
              GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceAlt,
          disabledForegroundColor: AppColors.muted,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle:
              GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle:
              GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, 48),
          textStyle:
              GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodySmall,
        errorStyle:
            textTheme.bodySmall?.copyWith(color: AppColors.danger),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primarySoft,
        disabledColor: AppColors.surfaceAlt,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        showCheckmark: false,
        labelStyle: GoogleFonts.nunitoSans(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        secondaryLabelStyle: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? AppColors.primary : AppColors.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.muted,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card + 4),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.checkbox)),
        side: const BorderSide(color: AppColors.border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceAlt,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle:
            GoogleFonts.nunitoSans(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    );
  }
}