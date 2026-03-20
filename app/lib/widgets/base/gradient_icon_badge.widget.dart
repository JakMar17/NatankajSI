import 'package:flutter/material.dart';

import 'package:app/styles/styles.dart';

/// A rounded icon badge with shared gradient styling.
class GradientIconBadge extends StatelessWidget {
  const GradientIconBadge({
    super.key,
    required this.icon,
    this.size = 52,
    this.iconColor = const Color(0xFF06121F),
  });

  final IconData icon;
  final double size;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppGradients.heroIcon,
      ),
      child: Icon(icon, color: iconColor),
    );
  }
}
