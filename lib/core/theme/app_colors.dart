import 'package:flutter/painting.dart';

abstract final class AppColors {
  static const Color brandTerracotta = Color(0xFFC76543);
  static const Color brandTerracottaDark = Color(0xFFA94D35);
  static const Color brandTerracottaPressed = Color(0xFF8D402D);
  static const Color brandTerracottaEdge = Color(0xFF73331F);
  static const Color brandTerracottaLight = Color(0xFFD98A69);
  static const Color brandCream = Color(0xFFF5EBDD);
  static const Color brandIvory = Color(0xFFFBF8F2);
  static const Color brandCharcoal = Color(0xFF292725);
  static const Color brandBrown = Color(0xFF66534A);
  static const Color brandLine = Color(0xFFDED5C9);
  static const Color brandGreen = Color(0xFF66745B);
  static const Color brandBlue = Color(0xFF71838A);

  static const Color surface = brandCream;
  static const Color surfaceBright = brandIvory;
  static const Color surfaceDim = Color(0xFFE8DED1);
  static const Color surfaceContainerLowest = brandIvory;
  static const Color surfaceContainerLow = brandCream;
  static const Color surfaceContainer = Color(0xFFEFE6D9);
  static const Color surfaceContainerHigh = Color(0xFFE8DED1);
  static const Color surfaceContainerHighest = Color(0xFFD8CABC);
  static const Color surfaceVariant = Color(0xFFE8DED1);
  static const Color surfaceRecessed = Color(0xFFE8DED1);
  static const Color surfaceRecessedStrong = Color(0xFFD8CABC);
  static const Color onSurface = brandCharcoal;
  static const Color onSurfaceVariant = brandBrown;
  static const Color onSurfaceMuted = Color(0xFF8C8178);

  static const Color onSurfacePlaceholder = brandBrown;
  static const Color outline = Color(0xFF8C8178);
  static const Color outlineVariant = brandLine;
  static const Color outlineStrong = Color(0xFFD8CABC);
  static const Color inverseSurface = brandCharcoal;
  static const Color inverseOnSurface = brandCream;
  static const Color surfaceTint = brandTerracotta;
  static const Color background = brandCream;
  static const Color onBackground = brandCharcoal;

  static const Color darkSurface = brandCharcoal;
  static const Color darkCard = Color(0xFF3A3531);
  static const Color darkMuted = Color(0xFFB8A99D);
  static const Color darkLine = Color(0xFF514943);

  static const Color primary = brandTerracotta;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = brandTerracotta;
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color primaryPressed = brandTerracottaPressed;

  static const Color primaryStrong = brandTerracottaDark;
  static const Color primarySoft = Color(0xFFF0DDD6);
  static const Color inversePrimary = brandTerracottaLight;
  static const Color primaryFixed = Color(0xFFF0DDD6);
  static const Color primaryFixedDim = brandTerracottaLight;
  static const Color onPrimaryFixed = Color(0xFF4A2318);
  static const Color onPrimaryFixedVariant = brandTerracottaDark;
  static const Color focusGlow = Color(0x1FC76543);

  static const Color secondary = brandBrown;
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFE8DED1);
  static const Color onSecondaryContainer = brandBrown;
  static const Color secondaryFixed = Color(0xFFE8DED1);
  static const Color secondaryFixedDim = Color(0xFFD8CABC);
  static const Color onSecondaryFixed = Color(0xFF2A211D);
  static const Color onSecondaryFixedVariant = brandBrown;

  static const Color tertiary = brandGreen;
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFE4E9DE);
  static const Color onTertiaryContainer = Color(0xFF52644A);

  static const Color successText = Color(0xFF52644A);
  static const Color successSurface = Color(0xFFE4E9DE);
  static const Color successAccent = brandGreen;

  static const Color pendingText = Color(0xFF7F5622);
  static const Color pendingSurface = Color(0xFFF3E5D0);
  static const Color pendingAccent = Color(0xFFC58A45);

  static const Color infoText = Color(0xFF536A72);
  static const Color infoSurface = Color(0xFFE1E8E9);
  static const Color infoAccent = brandBlue;

  static const Color error = Color(0xFFB85B4D);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF1DEDA);
  static const Color onErrorContainer = Color(0xFF98483D);

  static const Color badgeStayingSurface = Color(0xFFF0DDD6);
  static const Color badgeStayingText = brandTerracottaPressed;
  static const Color badgeDoneSurface = Color(0xFFE7E3DC);
  static const Color badgeDoneText = Color(0xFF665E58);
  static const Color badgeCancelledSurface = Color(0xFFECE9E4);
  static const Color badgeCancelledText = Color(0xFF6A6058);
}
