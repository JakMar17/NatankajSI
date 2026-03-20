part of '../fuel_locations.screen.dart';

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.item,
    required this.fuelCode,
    required this.onPressed,
  });

  final FuelLocationItem item;
  final String fuelCode;
  final VoidCallback onPressed;

  bool get _hasDistance => item.distanceKm != null;

  String? get _franchise => item.franchiseName?.trim();

  @override
  Widget build(BuildContext context) {
    final palette = FuelCardPalette.fromCode(fuelCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [palette.startColor, palette.endColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassStroke),
          ),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    if (_franchise.isNotNullOrEmpty)
                      Text(
                        _franchise!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textBodyMedium,
                        ),
                      ),
                    Text(
                      item.stationName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (item.stationAddress != null &&
                        item.stationAddress!.trim().isNotEmpty)
                      Text(
                        item.stationAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textBodyMedium,
                        ),
                      ),
                    Text(
                      _hasDistance
                          ? '${item.distanceKm!.toStringAsFixed(1)} km away'
                          : 'Distance unavailable',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textBodyHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item.price.toStringAsFixed(3)} €/L',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}