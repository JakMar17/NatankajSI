import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:app/screens/statistics/bloc/statistics.state.dart';
import 'package:app/styles/styles.dart';

/// A bar chart showing how many stations offer each fuel price.
///
/// Bars are ordered from the lowest to the highest price on the x axis.
/// The y axis represents the station count at that price.
/// Tapping a bar shows a tooltip with the price and station count.
class PriceDistributionChart extends StatelessWidget {
  const PriceDistributionChart({super.key, required this.distribution});

  final List<PriceDistributionBucket> distribution;

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) return const SizedBox.shrink();

    final maxCount = distribution.fold<int>(
      0,
      (value, bucket) => max(value, bucket.count),
    );

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price distribution',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textBodyMedium,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              _buildChartData(context, maxCount),
              duration: Duration.zero,
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _buildChartData(BuildContext context, int maxCount) {
    return BarChartData(
      barGroups: _buildBarGroups(),
      maxY: (maxCount * 1.2).ceilToDouble(),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      barTouchData: _buildTouchData(),
      titlesData: _buildTitlesData(context),
      alignment: BarChartAlignment.spaceEvenly,
    );
  }

  BarTouchData _buildTouchData() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => AppColors.bgSecondary,
        tooltipRoundedRadius: 10,
        tooltipPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        tooltipMargin: 8,
        fitInsideHorizontally: true,
        fitInsideVertically: true,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final bucket = distribution[group.x];
          final stationLabel =
              bucket.count == 1 ? 'station' : 'stations';
          return BarTooltipItem(
            '${bucket.price.toStringAsFixed(3)} EUR\n',
            const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            children: [
              TextSpan(
                text: '${bucket.count} $stationLabel',
                style: const TextStyle(
                  color: AppColors.textBodyMedium,
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return distribution.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.count.toDouble(),
            color: AppColors.accentBlue,
            width: _barWidth,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(3),
            ),
          ),
        ],
      );
    }).toList();
  }

  double get _barWidth {
    if (distribution.length <= 5) return 24;
    if (distribution.length <= 12) return 16;
    return 10;
  }

  FlTitlesData _buildTitlesData(BuildContext context) {
    return FlTitlesData(
      leftTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
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
          reservedSize: 22,
          getTitlesWidget: (value, meta) =>
              _buildBottomTitle(context, value.toInt()),
        ),
      ),
    );
  }

  Widget _buildBottomTitle(BuildContext context, int index) {
    final lastIndex = distribution.length - 1;
    final midIndex = lastIndex ~/ 2;
    final isLabelIndex =
        index == 0 ||
        index == lastIndex ||
        (distribution.length > 5 && index == midIndex);

    if (!isLabelIndex) return const SizedBox.shrink();

    return Text(
      distribution[index].price.toStringAsFixed(3),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: AppColors.textBodyMedium),
    );
  }
}
