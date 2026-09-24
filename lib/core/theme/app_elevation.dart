import 'package:flutter/painting.dart';

import 'app_colors.dart';

abstract final class AppElevation {
  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x0D292725), offset: Offset(0, 2), blurRadius: 6),
  ];

  static const List<BoxShadow> elevated = <BoxShadow>[
    BoxShadow(color: Color(0x14292725), offset: Offset(0, 4), blurRadius: 12),
  ];

  static const List<BoxShadow> floating = <BoxShadow>[
    BoxShadow(color: Color(0x1F292725), offset: Offset(0, 8), blurRadius: 20),
  ];

  static const List<BoxShadow> buttonRaised = <BoxShadow>[
    BoxShadow(color: AppColors.brandTerracottaPressed, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x1A292725), offset: Offset(0, 5), blurRadius: 10),
  ];

  static const List<BoxShadow> buttonPressed = <BoxShadow>[
    BoxShadow(color: AppColors.brandTerracottaEdge, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> buttonSecondary = <BoxShadow>[
    BoxShadow(color: Color(0x0F292725), offset: Offset(0, 2), blurRadius: 6),
  ];

  static const List<BoxShadow> buttonDangerRaised = <BoxShadow>[
    BoxShadow(color: AppColors.errorPressed, offset: Offset(0, 3)),
    BoxShadow(color: Color(0x1A292725), offset: Offset(0, 5), blurRadius: 10),
  ];

  static const List<BoxShadow> buttonDangerPressed = <BoxShadow>[
    BoxShadow(color: AppColors.errorEdge, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> topBar = <BoxShadow>[
    BoxShadow(color: Color(0x0D292725), offset: Offset(0, 2), blurRadius: 8),
  ];

  static const List<BoxShadow> bottomNav = <BoxShadow>[
    BoxShadow(color: Color(0x12292725), offset: Offset(0, -3), blurRadius: 12),
  ];

  // Alias lama.
  static const List<BoxShadow> card = elevated;
  static const List<BoxShadow> raisedButton = buttonRaised;
}
