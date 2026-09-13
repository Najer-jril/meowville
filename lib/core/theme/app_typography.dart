import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const String headlineFamily = 'Fredoka';
  static const String uiFamily = 'Inter';

  static TextStyle _font(
    String family, {
    required double fontSize,
    required FontWeight fontWeight,
    required double lineHeight,
    required double letterSpacingEm,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: lineHeight / fontSize,
      letterSpacing: fontSize * letterSpacingEm,
      color: AppColors.onSurface,
      fontFeatures: fontFeatures,
    );
  }

  static TextStyle _fredoka({
    required double fontSize,
    required double lineHeight,
    required double letterSpacingEm,
    FontWeight fontWeight = FontWeight.w600,
  }) => _font(
    headlineFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    lineHeight: lineHeight,
    letterSpacingEm: letterSpacingEm,
  );

  static TextStyle _inter({
    required double fontSize,
    required FontWeight fontWeight,
    required double lineHeight,
    required double letterSpacingEm,
    List<FontFeature>? fontFeatures,
  }) => _font(
    uiFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    lineHeight: lineHeight,
    letterSpacingEm: letterSpacingEm,
    fontFeatures: fontFeatures,
  );

  static TextStyle get display =>
      _fredoka(fontSize: 30, lineHeight: 36, letterSpacingEm: -0.02);

  static TextStyle get headlineLg =>
      _fredoka(fontSize: 26, lineHeight: 32, letterSpacingEm: -0.015);

  static TextStyle get headlineMd =>
      _fredoka(fontSize: 21, lineHeight: 28, letterSpacingEm: -0.01);

  static TextStyle get headlineSm =>
      _fredoka(fontSize: 18, lineHeight: 24, letterSpacingEm: -0.005);

  static TextStyle get wordmark =>
      _fredoka(fontSize: 26, lineHeight: 32, letterSpacingEm: 0);

  static TextStyle get bodyLg => _inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    lineHeight: 24,
    letterSpacingEm: -0.005,
  );

  static TextStyle get bodyMd => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    lineHeight: 20,
    letterSpacingEm: 0,
  );

  static TextStyle get bodySm => _inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    lineHeight: 18,
    letterSpacingEm: 0.005,
  );

  static TextStyle get labelLg => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    lineHeight: 18,
    letterSpacingEm: 0.005,
  );

  static TextStyle get labelMd => _inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    lineHeight: 16,
    letterSpacingEm: 0.015,
  );

  static TextStyle get caption => _inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    lineHeight: 14,
    letterSpacingEm: 0.02,
  );

  static TextStyle get labelSm => caption;

  static TextStyle get tabularNumeric => _inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    lineHeight: 20,
    letterSpacingEm: -0.01,
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}
