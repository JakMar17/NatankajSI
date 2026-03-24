part of '../tank_calculator.screen.dart';

class _StationCard extends StatelessWidget {
  const _StationCard({
    required this.label,
    required this.station,
    required this.capacityLiters,
    required this.fuelCode,
    required this.onTap,
    this.highlight = false,
    this.dimmed = false,
  });

  final String label;
  final StationSummary station;
  final double capacityLiters;
  final String fuelCode;
  final VoidCallback onTap;
  final bool highlight;
  final bool dimmed;

  Color get _accentColor {
    if (highlight) {
      return FuelCardPalette.fromCode(fuelCode).iconColor;
    } else if (dimmed) {
      return AppColors.accentOrange;
    } else {
      return AppColors.textBodyHigh;
    }
  }

  FuelCardPalette get _fuelPalette => FuelCardPalette.fromCode(fuelCode);

  double get _total => station.pricePerLiter * capacityLiters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlight
                  ? _fuelPalette.iconColor.withAlpha(80)
                  : AppColors.glassStroke,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 4,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Text(
                            station.name,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ?_buildAddress(context, station.address),
                          ?_buildDistanceBadge(context, station.distanceKm),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: .end,
                      children: [
                        Text(
                          '${_total.toStringAsFixed(2)} €',
                          style: textTheme.titleMedium?.copyWith(
                            color: _accentColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${station.pricePerLiter.toStringAsFixed(3)}/L',
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.textBodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildAddress(BuildContext context, String? address) {
    if (address == null) {
      return null;
    }
    return Padding(
      padding: const .only(top: 2),
      child: Text(
        address,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textBodyMedium),
      ),
    );
  }

  Widget? _buildDistanceBadge(BuildContext context, double? distanceKm) {
    if (distanceKm == null) {
      return null;
    }

    final label = distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1)} km';

    return Padding(
      padding: const .only(top: 4),
      child: Row(
        spacing: 4,
        children: [
          const Icon(Icons.near_me, size: 12, color: AppColors.accentBlue),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.accentBlue),
          ),
        ],
      ),
    );
  }
}