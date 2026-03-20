import 'package:flutter/material.dart';

/// A compact badge showing how a price compares to an average.
///
/// Shows green for below average, red for above average, and neutral
/// when within [threshold] of the average.
class PriceDeltaBadge extends StatelessWidget {
  const PriceDeltaBadge({
    super.key,
    required this.delta,
    this.threshold = 0.0005,
  });

  final double delta;
  final double threshold;

  static const Color _cheaperFill = Color(0x337BFFD9);
  static const Color _cheaperText = Color(0xFF7BFFD9);
  static const Color _pricierFill = Color(0x33FF7B7B);
  static const Color _pricierText = Color(0xFFFF9090);
  static const Color _neutralFill = Color(0x33FFFFFF);
  static const Color _neutralText = Color(0xBEFFFFFF);

  @override
  Widget build(BuildContext context) {
    final (label, fill, text) = switch (delta) {
      < 0 when delta.abs() > threshold => (
        delta.toStringAsFixed(3),
        _cheaperFill,
        _cheaperText,
      ),
      > 0 when delta > threshold => (
        '+${delta.toStringAsFixed(3)}',
        _pricierFill,
        _pricierText,
      ),
      _ => ('avg', _neutralFill, _neutralText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
