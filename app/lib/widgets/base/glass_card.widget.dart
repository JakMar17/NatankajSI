import 'dart:ui';

import 'package:flutter/material.dart';

/// A reusable glassmorphism card surface with blur and inner padding.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 22,
    this.padding = const EdgeInsets.all(18),
    this.blurSigma = 12,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Card(
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
