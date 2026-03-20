part of '../stations_map.screen.dart';

class _StationDetailsSheet extends StatelessWidget {
  const _StationDetailsSheet({
    required this.station,
    required this.franchise,
    required this.fuelsByCode,
    required this.averagesByFuelCode,
    required this.preferredFuelCode,
  });

  final StationWithPrices station;
  final Franchise? franchise;
  final Map<String, FuelType> fuelsByCode;
  final Map<String, double> averagesByFuelCode;
  final String? preferredFuelCode;

  @override
  Widget build(BuildContext context) {
    final brandName =
        franchise?.name ?? station.franchiseName ?? 'Brand not available';
    final sortedPrices = _sortStationPricesForCards(
      station.latestPrices,
      preferredFuelCode,
    );

    return Align(
      alignment: Alignment.bottomCenter,
      child: NotificationListener<DraggableScrollableNotification>(
        onNotification: (notification) {
          if (notification.extent <= _detailsSheetMinSize + 0.001) {
            context.read<StationsMapCubit>().clearSelection();
          }

          return false;
        },
        child: DraggableScrollableSheet(
          initialChildSize: _detailsSheetInitialSize,
          minChildSize: _detailsSheetMinSize,
          maxChildSize: _detailsSheetMaxSize,
          snap: true,
          snapSizes: const [_detailsSheetInitialSize, _detailsSheetMaxSize],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.bgSecondary.withValues(alpha: 0.96),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.glassStroke),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x7A000000),
                    blurRadius: 28,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: ListView(
                  key: ValueKey(station.pk),
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    const _SheetHandle(),
                    const SizedBox(height: 8),
                    _StationHeader(
                      station: station,
                      franchise: franchise,
                      brandName: brandName,
                      onNavigatePressed:
                          station.lat != null && station.lng != null
                          ? () {
                              _openGoogleMapsNavigation(
                                context,
                                lat: station.lat!,
                                lng: station.lng!,
                                label: station.name,
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 14),
                    Column(
                      mainAxisSize: .min,
                      spacing: 8,
                      children: sortedPrices.mapToList(
                        (price) => _PriceCard(
                          price: price,
                          fuelType: fuelsByCode[price.fuelCode.toLowerCase()],
                          averagePrice: averagesByFuelCode[
                            price.fuelCode.trim().toLowerCase()
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      title: 'Opening hours',
                      icon: Icons.schedule_outlined,
                      lines: [
                        station.openHours?.trim().isNotEmpty == true
                            ? station.openHours!.trim()
                            : 'Opening hours not available',
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoCard(
                      title: 'Address',
                      icon: Icons.pin_drop_outlined,
                      lines: [
                        if (station.address?.trim().isNotEmpty == true)
                          station.address!.trim(),
                        station.zipCode?.trim().isNotEmpty == true
                            ? station.zipCode!.trim()
                            : '',
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<LatestPriceEntry> _sortStationPricesForCards(
  List<LatestPriceEntry> prices,
  String? preferredFuelCode,
) {
  final normalizedPreferredFuelCode = preferredFuelCode?.trim().toLowerCase();
  final indexedPrices = prices.indexed.toList();

  indexedPrices.sort((left, right) {
    final leftPriority = _priceCardPriority(
      left.$2,
      normalizedPreferredFuelCode,
    );
    final rightPriority = _priceCardPriority(
      right.$2,
      normalizedPreferredFuelCode,
    );

    if (leftPriority != rightPriority) {
      return leftPriority.compareTo(rightPriority);
    }

    return left.$1.compareTo(right.$1);
  });

  return indexedPrices.mapToList((entry) => entry.$2);
}

int _priceCardPriority(
  LatestPriceEntry price,
  String? normalizedPreferredFuelCode,
) {
  final normalizedCode = price.fuelCode.trim().toLowerCase();
  final normalizedName = price.fuelName.trim().toLowerCase();

  if (normalizedPreferredFuelCode != null &&
      normalizedPreferredFuelCode.isNotEmpty &&
      normalizedCode == normalizedPreferredFuelCode) {
    return 0;
  }

  if (normalizedCode.contains('95') || normalizedName.contains('95')) {
    return 1;
  }

  final isRegularDieselCode = normalizedCode == 'dizel';
  final isRegularDieselName =
      normalizedName.contains('dizel') && !normalizedName.contains('premium');
  if (isRegularDieselCode || isRegularDieselName) {
    return 2;
  }

  return 3;
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 52,
        child: Divider(color: AppColors.glassStroke, thickness: 3),
      ),
    );
  }
}

class _StationHeader extends StatelessWidget {
  const _StationHeader({
    required this.station,
    required this.franchise,
    required this.brandName,
    required this.onNavigatePressed,
  });

  final StationWithPrices station;
  final Franchise? franchise;
  final String brandName;
  final VoidCallback? onNavigatePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12,
      children: [
        if (franchise?.markerUrl != null)
          Image.network(franchise!.markerUrl!, width: 36, height: 36),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            spacing: 8,
            children: [
              Text(
                station.name,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.glassStroke),
                ),
                child: Text(
                  brandName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textBodyHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _NavigateHeaderButton(onPressed: onNavigatePressed),
      ],
    );
  }
}

class _NavigateHeaderButton extends StatelessWidget {
  const _NavigateHeaderButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Tooltip(
      message: 'Navigate in Google Maps',
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [Color(0x3357C9FF), Color(0x337BFFD9)]
                : const [Color(0x1EFFFFFF), Color(0x1EFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassStroke),
          boxShadow: isEnabled
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.navigation_rounded,
                size: 20,
                color: isEnabled
                    ? AppColors.accentMint
                    : AppColors.textBodyMedium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({
    required this.price,
    required this.fuelType,
    required this.averagePrice,
  });

  final LatestPriceEntry price;
  final FuelType? fuelType;
  final double? averagePrice;

  String get _priceValue => price.price.toStringAsFixed(3);
  String get _title {
    final longName = fuelType?.longName?.trim();
    if (longName != null && longName.isNotEmpty) {
      return longName;
    }

    return price.fuelName;
  }

  String get _subtitle {
    final shortName = fuelType?.name.trim();
    final code = fuelType?.code.trim().isNotEmpty == true
        ? fuelType!.code.trim()
        : price.fuelCode;

    if (shortName != null && shortName.isNotEmpty) {
      return '$shortName · $code';
    }

    return code;
  }

  @override
  Widget build(BuildContext context) {
    final palette = FuelCardPalette.fromCode(fuelType?.code ?? price.fuelCode);

    return Container(
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x29000000),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.local_gas_station_outlined,
              size: 18,
              color: palette.iconColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textBodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 4,
            children: [
              Text(
                '$_priceValue EUR/L',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (averagePrice != null)
                PriceDeltaBadge(delta: price.price - averagePrice!),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.lines,
  });

  final String title;
  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const .all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1F40D9FF), Color(0x1F7BFFD9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassStroke),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x29000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 24, color: AppColors.accentMint),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textBodyHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          for (final line in lines)
            Text(
              line,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textBodyMedium),
            ),
        ],
      ),
    );
  }
}

Future<void> _openGoogleMapsNavigation(
  BuildContext context, {
  required double lat,
  required double lng,
  required String label,
}) async {
  final encodedLabel = Uri.encodeComponent(label);
  final navigationUri = Uri.parse(
    'google.navigation:q=$lat,$lng($encodedLabel)',
  );
  final webUri = Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );

  if (await canLaunchUrl(navigationUri)) {
    await launchUrl(navigationUri);
    return;
  }

  if (await canLaunchUrl(webUri)) {
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
    return;
  }

  if (!context.mounted) {
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Unable to open navigation app.')),
  );
}
