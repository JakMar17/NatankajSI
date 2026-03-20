import 'package:flutter/material.dart';

/// Visual tokens for fuel-specific price cards.
class FuelCardPalette {
  const FuelCardPalette({
    required this.startColor,
    required this.endColor,
    required this.iconColor,
  });

  final Color startColor;
  final Color endColor;
  final Color iconColor;

  static const FuelCardPalette _defaultPalette = FuelCardPalette(
    startColor: Color(0x3340D9FF),
    endColor: Color(0x337BFFD9),
    iconColor: Color(0xFF7BFFD9),
  );

  static const Map<String, FuelCardPalette> _paletteByCode =
      <String, FuelCardPalette>{
        '95': FuelCardPalette(
          startColor: Color(0x3354CF76),
          endColor: Color(0x3336A95D),
          iconColor: Color(0xFF9BFFBD),
        ),
        '98': FuelCardPalette(
          startColor: Color(0x3360D884),
          endColor: Color(0x3342BD6A),
          iconColor: Color(0xFFA7FFCB),
        ),
        '100': FuelCardPalette(
          startColor: Color(0x336CE298),
          endColor: Color(0x3347C177),
          iconColor: Color(0xFFBCFFD8),
        ),
        'dizel': FuelCardPalette(
          startColor: Color(0x33565E6B),
          endColor: Color(0x333A404A),
          iconColor: Color(0xFFDDE1E7),
        ),
        'dizel-premium': FuelCardPalette(
          startColor: Color(0x33676F7B),
          endColor: Color(0x33454B56),
          iconColor: Color(0xFFFFD684),
        ),
        'avtoplin-lpg': FuelCardPalette(
          startColor: Color(0x334AABFF),
          endColor: Color(0x33387ADB),
          iconColor: Color(0xFFB8D8FF),
        ),
        'cng': FuelCardPalette(
          startColor: Color(0x333FC8FF),
          endColor: Color(0x332A8BD4),
          iconColor: Color(0xFFB2ECFF),
        ),
        'lng': FuelCardPalette(
          startColor: Color(0x33347BFF),
          endColor: Color(0x33244FB3),
          iconColor: Color(0xFFB7C9FF),
        ),
        'hvo': FuelCardPalette(
          startColor: Color(0x333BC9A9),
          endColor: Color(0x33298F78),
          iconColor: Color(0xFFB7FFE3),
        ),
        'koel': FuelCardPalette(
          startColor: Color(0x33CB8D48),
          endColor: Color(0x338A5D2E),
          iconColor: Color(0xFFFFD7B0),
        ),
      };

  static FuelCardPalette fromCode(String fuelCode) {
    final normalizedCode = fuelCode.trim().toLowerCase();
    return _paletteByCode[normalizedCode] ?? _defaultPalette;
  }
}
