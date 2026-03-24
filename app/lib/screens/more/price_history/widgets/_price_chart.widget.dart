import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:app/data/models/regulated_price.model.dart';
import 'package:app/styles/styles.dart';

/// A step line chart plotting regulated fuel price over time.
///
/// Null price values are treated as "no regulated price" — they create
/// a visible gap instead of connecting across the missing period.
class PriceLineChart extends StatelessWidget {
  const PriceLineChart({
    super.key,
    required this.prices,
    required this.showPetrol,
    required this.showDiesel,
    required this.touchedX,
    required this.onTouched,
  });

  final List<RegulatedPrice> prices;
  final bool showPetrol;
  final bool showDiesel;
  final double? touchedX;
  final void Function(double x) onTouched;

  static final _tooltipFormat = DateFormat('d MMM yyyy');

  // Fuel-type icon colours from the shared palette.
  static final Color _petrolColor =
      FuelCardPalette.fromCode('95').iconColor;
  static final Color _dieselColor =
      FuelCardPalette.fromCode('dizel').iconColor;

  static double _toX(DateTime date) =>
      date.millisecondsSinceEpoch / 86400000.0;

  static DateTime _toDate(double x) =>
      DateTime.fromMillisecondsSinceEpoch((x * 86400000).round());

  @override
  Widget build(BuildContext context) {
    final sorted = [...prices]
      ..sort((a, b) => a.validFrom.compareTo(b.validFrom));

    final fuels = _activeFuels();
    final allValidSpots = _collectValidSpots(sorted, fuels);

    if (allValidSpots.isEmpty) {
      return const Center(
        child: Text(
          'No data for selected period.',
          style: TextStyle(color: AppColors.textBodyMedium),
        ),
      );
    }

    final allY = allValidSpots.map((s) => s.y).toList();
    final minY = allY.reduce((a, b) => a < b ? a : b);
    final maxY = allY.reduce((a, b) => a > b ? a : b);
    final yPad = ((maxY - minY) * 0.12).clamp(0.02, double.infinity);
    final minX =
        allValidSpots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX =
        allValidSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final xRange = maxX - minX;
    final landmarks = _computeLandmarks(xRange, minX, maxX);

    final (:bars, :barMeta) = _buildBarsWithMeta(sorted, fuels);
    final indicators = _buildIndicators(bars, barMeta);

    return LineChart(
      _buildChartData(
        context,
        bars: bars,
        barMeta: barMeta,
        indicators: indicators,
        minY: minY - yPad,
        maxY: maxY + yPad,
        minX: minX,
        maxX: maxX,
        xRange: xRange,
        landmarks: landmarks,
      ),
      duration: Duration.zero,
    );
  }

  // ── Fuel metadata ────────────────────────────────────────────────

  List<_FuelMeta> _activeFuels() => [
        if (showPetrol)
          _FuelMeta(
            label: 'Bencin 95',
            color: _petrolColor,
            getValue: (p) => p.petrolPrice,
          ),
        if (showDiesel)
          _FuelMeta(
            label: 'Dizel',
            color: _dieselColor,
            getValue: (p) => p.dieselPrice,
          ),
      ];

  // ── Spots ────────────────────────────────────────────────────────

  List<FlSpot> _collectValidSpots(
    List<RegulatedPrice> sorted,
    List<_FuelMeta> fuels,
  ) {
    final spots = <FlSpot>[];
    for (final fuel in fuels) {
      for (final p in sorted) {
        final v = fuel.getValue(p);
        if (v != null) spots.add(FlSpot(_toX(p.validFrom), v));
      }
    }
    return spots;
  }

  /// Splits each fuel's data into contiguous non-null segments.
  /// Each segment becomes a separate [LineChartBarData].
  ({List<LineChartBarData> bars, List<_FuelMeta> barMeta})
      _buildBarsWithMeta(
    List<RegulatedPrice> sorted,
    List<_FuelMeta> fuels,
  ) {
    final bars = <LineChartBarData>[];
    final barMeta = <_FuelMeta>[];

    for (final fuel in fuels) {
      List<FlSpot>? segment;

      for (final price in sorted) {
        final value = fuel.getValue(price);
        final x = _toX(price.validFrom);
        if (value != null) {
          (segment ??= []).add(FlSpot(x, value));
        } else if (segment != null) {
          bars.add(_makeBar(segment, fuel));
          barMeta.add(fuel);
          segment = null;
        }
      }
      if (segment != null) {
        bars.add(_makeBar(segment, fuel));
        barMeta.add(fuel);
      }
    }
    return (bars: bars, barMeta: barMeta);
  }

  LineChartBarData _makeBar(List<FlSpot> spots, _FuelMeta fuel) =>
      LineChartBarData(
        spots: spots,
        isCurved: false,
        color: fuel.color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              fuel.color.withAlpha(45),
              fuel.color.withAlpha(0),
            ],
          ),
        ),
      );

  // ── Persistent tooltip ───────────────────────────────────────────

  /// Returns at most one touched spot per fuel across all their segments.
  List<ShowingTooltipIndicators> _buildIndicators(
    List<LineChartBarData> bars,
    List<_FuelMeta> barMeta,
  ) {
    if (touchedX == null) return [];

    final seen = <String>{};
    final spotsToShow = <LineBarSpot>[];

    for (int i = 0; i < bars.length; i++) {
      final fuelLabel = barMeta[i].label;
      if (seen.contains(fuelLabel)) continue;
      final bar = bars[i];
      for (int j = 0; j < bar.spots.length; j++) {
        if ((bar.spots[j].x - touchedX!).abs() < 0.5) {
          spotsToShow.add(LineBarSpot(bar, i, bar.spots[j]));
          seen.add(fuelLabel);
          break;
        }
      }
    }

    if (spotsToShow.isEmpty) return [];
    return [ShowingTooltipIndicators(spotsToShow)];
  }

  // ── Chart data ───────────────────────────────────────────────────

  LineChartData _buildChartData(
    BuildContext context, {
    required List<LineChartBarData> bars,
    required List<_FuelMeta> barMeta,
    required List<ShowingTooltipIndicators> indicators,
    required double minY,
    required double maxY,
    required double minX,
    required double maxX,
    required double xRange,
    required List<(double, String)> landmarks,
  }) {
    final yRange = maxY - minY;
    return LineChartData(
      minY: minY,
      maxY: maxY,
      minX: minX,
      maxX: maxX,
      clipData: const FlClipData.all(),
      showingTooltipIndicators: indicators,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (yRange / 4).clamp(0.01, double.infinity),
        getDrawingHorizontalLine: (_) => const FlLine(
          color: AppColors.glassStroke,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      extraLinesData: touchedX != null
          ? ExtraLinesData(
              verticalLines: [
                VerticalLine(
                  x: touchedX!,
                  color: AppColors.glassStroke,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ],
            )
          : null,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: false,
        touchCallback: (event, response) {
          final spots = response?.lineBarSpots;
          if (spots != null && spots.isNotEmpty) {
            onTouched(spots.first.x);
          }
        },
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColors.bgSecondary,
          tooltipRoundedRadius: 10,
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          getTooltipItems: (spots) {
            final date = _toDate(spots.first.x);
            return spots.asMap().entries.map((entry) {
              final i = entry.key;
              final spot = entry.value;
              final fuel = barMeta[spot.barIndex];
              return LineTooltipItem(
                i == 0 ? '${_tooltipFormat.format(date)}\n' : '',
                const TextStyle(
                  color: AppColors.textBodyMedium,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${fuel.label}: '
                        '${spot.y.toStringAsFixed(3)} EUR',
                    style: TextStyle(
                      color: fuel.color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      titlesData: _buildTitlesData(context, landmarks),
      lineBarsData: bars,
    );
  }

  // ── X-axis landmarks ─────────────────────────────────────────────

  List<(double, String)> _computeLandmarks(
    double xRange,
    double minX,
    double maxX,
  ) {
    if (xRange > 1825) return _yearlyLandmarks(minX, maxX);
    return _monthlyLandmarks(minX, maxX);
  }

  List<(double, String)> _yearlyLandmarks(double minX, double maxX) {
    final fmt = DateFormat('yyyy');
    final result = <(double, String)>[];
    var year = _toDate(minX).year;
    while (true) {
      final d = DateTime(year);
      final x = _toX(d);
      if (x > maxX + 1) break;
      if (x >= minX - 1) result.add((x, fmt.format(d)));
      year++;
    }
    return result;
  }

  List<(double, String)> _monthlyLandmarks(double minX, double maxX) {
    final fmt = DateFormat('MMM yy');
    final result = <(double, String)>[];
    final start = _toDate(minX);
    var year = start.year;
    var month = start.month;
    while (true) {
      final d = DateTime(year, month);
      final x = _toX(d);
      if (x > maxX + 1) break;
      if (x >= minX - 1) result.add((x, fmt.format(d)));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return result;
  }

  FlTitlesData _buildTitlesData(
    BuildContext context,
    List<(double, String)> landmarks,
  ) {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 54,
          getTitlesWidget: (value, meta) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              value.toStringAsFixed(3),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textBodyMedium,
              ),
            ),
          ),
        ),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 1,
          getTitlesWidget: (value, meta) {
            for (final (lx, label) in landmarks) {
              if ((lx - value).abs() < 0.01) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(
                      color: AppColors.textBodyMedium,
                    ),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FuelMeta {
  const _FuelMeta({
    required this.label,
    required this.color,
    required this.getValue,
  });

  final String label;
  final Color color;
  final double? Function(RegulatedPrice) getValue;
}
