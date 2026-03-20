import 'package:flutter/material.dart';

import 'package:app/styles/styles.dart';

/// A small rounded badge for positive or negative trend values.
class TrendPill extends StatelessWidget {
  const TrendPill({
    super.key,
    required this.value,
  });

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.trendFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.trendStroke),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.trendText,
        ),
      ),
    );
  }
}
