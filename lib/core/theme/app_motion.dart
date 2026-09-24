import 'package:flutter/animation.dart';

abstract final class AppMotion {
  static const Duration pressFast = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasized = Cubic(0.32, 0.72, 0, 1);
}
