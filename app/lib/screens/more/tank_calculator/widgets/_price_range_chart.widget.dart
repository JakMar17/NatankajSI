import 'package:flutter/material.dart';

import 'package:app/styles/styles.dart';

/// Proportional bar chart comparing full tank cost across price points.
///
/// All bars share the same scale (priciest overall = full width).
/// Optional bars (nearby / closest) appear only when data is available.
class PriceRangeChart extends StatelessWidget {
  const PriceRangeChart({
    super.key,
    required this.cheapestPerLiter,
    required this.mostExpensivePerLiter,
    required this.capacityLiters,
    required this.fuelCode,
    this.closestPerLiter,
    this.cheapestNearbyPerLiter,
    this.mostExpensiveNearbyPerLiter,
  });

  final double cheapestPerLiter;
  final double mostExpensivePerLiter;
  final double capacityLiters;
  final String fuelCode;
  final double? closestPerLiter;
  final double? cheapestNearbyPerLiter;
  final double? mostExpensiveNearbyPerLiter;

  @override
  Widget build(BuildContext context) {
    final fuelColor = FuelCardPalette.fromCode(fuelCode).iconColor;
    const expColor = Color(0xFFFF8A65);
    const closestColor = AppColors.accentBlue;

    final cheapTotal = cheapestPerLiter * capacityLiters;
    final priciestTotal = mostExpensivePerLiter * capacityLiters;
    final closestTotal = closestPerLiter != null
        ? closestPerLiter! * capacityLiters
        : null;
    final cheapNearbyTotal = cheapestNearbyPerLiter != null
        ? cheapestNearbyPerLiter! * capacityLiters
        : null;
    final expNearbyTotal = mostExpensiveNearbyPerLiter != null
        ? mostExpensiveNearbyPerLiter! * capacityLiters
        : null;

    // All bars are proportional to the global maximum.
    final maxTotal = priciestTotal;

    double frac(double total) =>
        maxTotal > 0 ? (total / maxTotal).clamp(0.0, 1.0) : 1.0;

    // Build bar list sorted by ascending price.
    final bars = <_BarEntry>[
      _BarEntry(
        label: 'CHEAPEST',
        total: cheapTotal,
        fraction: frac(cheapTotal),
        color: fuelColor,
      ),
      if (cheapNearbyTotal != null)
        _BarEntry(
          label: 'CHEAPEST 30 KM',
          total: cheapNearbyTotal,
          fraction: frac(cheapNearbyTotal),
          color: fuelColor.withAlpha(160),
        ),
      if (closestTotal != null)
        _BarEntry(
          label: 'CLOSEST TO ME',
          total: closestTotal,
          fraction: frac(closestTotal),
          color: closestColor,
        ),
      if (expNearbyTotal != null)
        _BarEntry(
          label: 'PRICIEST 30 KM',
          total: expNearbyTotal,
          fraction: frac(expNearbyTotal),
          color: expColor.withAlpha(160),
        ),
      _BarEntry(
        label: 'PRICIEST',
        total: priciestTotal,
        fraction: 1.0,
        color: expColor,
      ),
    ]..sort((a, b) => a.total.compareTo(b.total));

    final globalDiff = priciestTotal - cheapTotal;
    final globalDiffPct = priciestTotal > 0
        ? globalDiff / priciestTotal * 100
        : 0.0;

    final hasDiffNearby =
        cheapNearbyTotal != null && expNearbyTotal != null;
    final nearbyDiff = hasDiffNearby
        ? expNearbyTotal - cheapNearbyTotal
        : null;
    final nearbyDiffPct =
        hasDiffNearby && expNearbyTotal > 0
            ? nearbyDiff! / expNearbyTotal * 100
            : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRICE RANGE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textBodyMedium,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          ...bars.map(
            (bar) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PriceBar(entry: bar),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: AppColors.glassStroke, height: 1),
          const SizedBox(height: 14),
          _DiffRow(
            label: 'GLOBAL DIFF',
            diff: globalDiff,
            diffPct: globalDiffPct,
          ),
          if (nearbyDiff != null) ...[
            const SizedBox(height: 8),
            _DiffRow(
              label: '30 KM DIFF',
              diff: nearbyDiff,
              diffPct: nearbyDiffPct!,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarEntry {
  const _BarEntry({
    required this.label,
    required this.total,
    required this.fraction,
    required this.color,
  });

  final String label;
  final double total;
  final double fraction;
  final Color color;
}

class _PriceBar extends StatelessWidget {
  const _PriceBar({required this.entry});

  final _BarEntry entry;

  static const double _barHeight = 40;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            (constraints.maxWidth * entry.fraction).clamp(80.0, constraints.maxWidth);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: barWidth,
          height: _barHeight,
          decoration: BoxDecoration(
            color: entry.color.withAlpha(28),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: entry.color.withAlpha(90)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.label,
                style: textTheme.labelSmall?.copyWith(
                  color: entry.color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '€${entry.total.toStringAsFixed(2)}',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textBodyHigh,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.label,
    required this.diff,
    required this.diffPct,
  });

  final String label;
  final double diff;
  final double diffPct;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textBodyMedium,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '€${diff.toStringAsFixed(2)}',
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.textBodyHigh,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${diffPct.toStringAsFixed(1)}%',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textBodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
