import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space40 = 40;
  static const double space48 = 48;

  static const double screenEdge = 16;
  static const double cardPadding = 16;
  static const double statusBarInset = 59;
  static const double bottomNavSafe = 34;

  static const double topBarHeight = 56;

  static double topBarGap(BuildContext context) =>
      MediaQuery.paddingOf(context).top + topBarHeight;

  static const double controlHeight = 48;
  static const double minTapTarget = 44;
  static const double fabSize = 56;
  static const double avatarFrame = 48;
  static const double leadingIconInset = 40;
  static const double trailingIconInset = 44;
}
