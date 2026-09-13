import 'package:flutter/painting.dart';

abstract final class AppRadius {
  static const double control = 12;
  static const double card = 16;
  static const double hero = 20;
  static const double pill = 999;

  static const double base = 6;
  static const double lg = control;
  static const double xl = card;
  static const double full = pill;

  static const BorderRadius baseAll = BorderRadius.all(Radius.circular(base));
  static const BorderRadius controlAll = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
  static const BorderRadius heroAll = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));

  static const BorderRadius lgAll = controlAll;
  static const BorderRadius xlAll = cardAll;
}
