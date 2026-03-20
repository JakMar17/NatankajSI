import 'package:flutter/material.dart';

import 'package:app/styles/app_colors.dart';

/// Shared gradients used across screens and components.
class AppGradients {
  AppGradients._();

  static const Gradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.bgPrimary,
      AppColors.bgSecondary,
      Color(0xFF0B1D2D),
    ],
  );

  static const Gradient heroIcon = LinearGradient(
    colors: <Color>[
      Color(0xFF55D0FF),
      Color(0xFF75FFE5),
    ],
  );
}
