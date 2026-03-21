part of "../fuel_locations.screen.dart";

class _FuelLocationsStatisticsTab extends StatelessWidget {
  const _FuelLocationsStatisticsTab({
    required this.statistics,
    required this.onStationPressed,
  });

  final FuelStatistics? statistics;
  final ValueChanged<int> onStationPressed;

  @override
  Widget build(BuildContext context) {
    final stats = statistics;
    if (stats == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Statistics not available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textBodyMedium),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        _StatPriceHeader(statistics: stats),
        const SizedBox(height: 24),
        _buildMetricCards(context, stats),
        const SizedBox(height: 16),
        PriceDistributionChart(distribution: stats.priceDistribution),
        const SizedBox(height: 16),
        _buildAdditionalInfo(stats),
      ],
    );
  }

  void _onStationTapped(BuildContext context, int stationPk) {
    onStationPressed(stationPk);
    Navigator.of(context).pop();
  }

  Widget _buildMetricCards(BuildContext context, FuelStatistics stats) {
    return Column(
      spacing: 10,
      children: [
        _StatMetricRow(
          label: 'Nearest to me',
          point: stats.closestToUser,
          icon: Icons.near_me_rounded,
          onPressed: () => _onStationTapped(
            context,
            stats.closestToUser.stationPk,
          ),
        ),
        _StatMetricRow(
          label: 'Cheapest station',
          point: stats.minPricePoint,
          icon: Icons.south_rounded,
          onPressed: () => _onStationTapped(
            context,
            stats.minPricePoint.stationPk,
          ),
        ),
        _StatMetricRow(
          label: 'Most expensive station',
          point: stats.maxPricePoint,
          icon: Icons.north_rounded,
          onPressed: () => _onStationTapped(
            context,
            stats.maxPricePoint.stationPk,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo(FuelStatistics stats) {
    return Column(
      children: [
        _StatSummaryRow(
          label: 'Price range',
          value: '${stats.priceSpread.toStringAsFixed(3)} EUR',
        ),
        _StatSummaryRow(
          label: 'Typical variation',
          value:
              '${stats.averageDeviation.toStringAsFixed(3)} EUR '
              '(${stats.averageDeviationPercent.toStringAsFixed(1)}%)',
        ),
        _StatSummaryRow(
          label: 'Coverage',
          value:
              '${stats.stationCount} stations, '
              '${stats.sampleCount} prices',
        ),
      ],
    );
  }
}

class _StatPriceHeader extends StatelessWidget {
  const _StatPriceHeader({required this.statistics});

  final FuelStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${statistics.primaryPrice.toStringAsFixed(3)} EUR',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          statistics.primaryPriceLabel,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
        ),
      ],
    );
  }
}

class _StatMetricRow extends StatelessWidget {
  const _StatMetricRow({
    required this.label,
    required this.point,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final StationPricePoint point;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final address = point.stationAddress?.trim();
    final hasAddress = address != null && address.isNotEmpty;
    final distance = point.distanceKm;
    final hasDistance = distance != null && distance.isFinite;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.textBodyMedium),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textBodyMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${point.price.toStringAsFixed(3)} EUR',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              point.stationName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textBodyHigh,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasAddress)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textBodyMedium,
                  ),
                ),
              ),
            if (hasDistance)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${distance.toStringAsFixed(1)} km from you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textBodyMedium,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatSummaryRow extends StatelessWidget {
  const _StatSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textBodyHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
