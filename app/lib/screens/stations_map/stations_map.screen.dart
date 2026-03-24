import 'package:app/extensions/string.extension.dart';
import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/screens/stations_map/bloc/stations_map.cubit.dart';
import 'package:app/screens/stations_map/bloc/stations_map.state.dart';
import 'package:app/screens/statistics/fuel_locations/fuel_locations.screen.dart';
import 'package:app/data/data.dart';
import 'package:app/styles/styles.dart';
import 'package:app/widgets/base/base.dart';

part 'widgets/_search_bar.widget.dart';
part 'widgets/_map_actions.widget.dart';
part 'widgets/_filters_bottom_sheet.widget.dart';
part 'widgets/_filters_tags.widget.dart';
part 'widgets/_multi_select_picker.widget.dart';
part 'widgets/_station_details_sheet.widget.dart';

const double _stationMarkerWidth = 92;
const double _stationMarkerHeight = 96;
const int _clusterRadius = 70;
const double _clusterBreakoutZoom = 18;
const int _autocompleteMaxResults = 3;
const double _detailsSheetInitialSize = 0.23;
const double _detailsSheetMinSize = 0.14;
const double _detailsSheetMaxSize = 0.75;

/// Displays all fuel stations on a map with a station details bottom sheet.
class StationsMapScreen extends StatelessWidget {
  const StationsMapScreen({
    super.key,
    this.onStationSelectionChanged,
    this.cubit,
  });

  final ValueChanged<bool>? onStationSelectionChanged;
  final StationsMapCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<StationsMapCubit>.value(
        value: cubit!,
        child: _StationsMapView(
          onStationSelectionChanged: onStationSelectionChanged,
        ),
      );
    }

    return BlocProvider(
      create: (context) {
        return StationsMapCubit(
          stationsApiService: context.read<StationsApiService>(),
          franchisesApiService: context.read<FranchisesApiService>(),
          fuelsApiService: context.read<FuelsApiService>(),
          appBootRepository: context.read<AppBootRepository>(),
        )..loadData();
      },
      child: _StationsMapView(
        onStationSelectionChanged: onStationSelectionChanged,
      ),
    );
  }
}

class _StationsMapView extends StatelessWidget {
  const _StationsMapView({this.onStationSelectionChanged});

  final ValueChanged<bool>? onStationSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StationsMapCubit, StationsMapState>(
      listenWhen: (previous, current) {
        return previous.selectedStation?.pk != current.selectedStation?.pk;
      },
      listener: (context, state) {
        onStationSelectionChanged?.call(state.selectedStation != null);
      },
      builder: (context, state) {
        return DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.appBackground),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                _MapBody(state: state),
                const _MapActions(),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: _SearchBar(),
                  ),
                ),
                if (state.selectedStation != null)
                  _StationDetailsSheet(
                    station: state.selectedStation!,
                    franchise: state.selectedStation!.franchiseId == null
                        ? null
                        : state.franchisesById[state
                              .selectedStation!
                              .franchiseId],
                    fuelsByCode: state.fuelsByCode,
                    averagesByFuelCode: state.averagesByFuelCode,
                    preferredFuelCode: state.preferredFuelCode,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapBody extends StatelessWidget {
  const _MapBody({required this.state});

  final StationsMapState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            state.errorMessage!,
            style: const TextStyle(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.allStations.isEmpty) {
      return const Center(
        child: Text(
          'No stations with coordinates were returned by API.',
          style: TextStyle(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
      );
    }

    final stationMarkers = state.stations.mapToList(
      (station) => Marker(
        point: LatLng(station.lat!, station.lng!),
        width: _stationMarkerWidth,
        height: _stationMarkerHeight,
        child: _StationMarker(
          station: station,
          franchise: station.franchiseId == null
              ? null
              : state.franchisesById[station.franchiseId],
          preferredFuelCode: state.preferredFuelCode,
          isSelected: state.selectedStation?.pk == station.pk,
          onTap: () {
            context.read<StationsMapCubit>().selectStation(station);
          },
        ),
      ),
    );
    final userLocationMarkers = <Marker>[
      if (state.userLocation != null)
        Marker(
          point: state.userLocation!,
          width: 28,
          height: 28,
          child: const _UserLocationMarker(),
        ),
    ];

    return Stack(
      children: [
        AppMap(
          mapController: state.mapController,
          center: state.mapInitialCenter,
          markers: stationMarkers,
          nonClusterMarkers: userLocationMarkers,
          initialZoom: state.mapInitialZoom,
          minZoom: 4,
          maxZoom: 18,
          maxClusterRadius: _clusterRadius,
          clusterBreakoutZoom: _clusterBreakoutZoom,
          clusterBuilder: (context, clusterMarkers) {
            return _ClusterCountMarker(count: clusterMarkers.length);
          },
          onTap: (point) {
            context.read<StationsMapCubit>().clearSelection();
          },
        ),
      ],
    );
  }
}

class _StationMarker extends StatelessWidget {
  const _StationMarker({
    required this.station,
    required this.franchise,
    required this.preferredFuelCode,
    required this.isSelected,
    required this.onTap,
  });

  final StationWithPrices station;
  final Franchise? franchise;
  final String? preferredFuelCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerFuel = _resolveMarkerFuel(
      prices: station.latestPrices,
      preferredFuelCode: preferredFuelCode,
    );
    final logoUrl = franchise?.markerUrl;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentBlue : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassStroke),
            ),
            child: Text(
              markerFuel == null
                  ? '--'
                  : '${markerFuel.price.toStringAsFixed(3)} EUR',
              style: TextStyle(
                color: isSelected ? Colors.black : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.bgSecondary,
            child: ClipOval(
              child: _MarkerLogo(logoUrl: logoUrl, fallbackText: station.name),
            ),
          ),
          const Icon(Icons.location_on, size: 22, color: AppColors.accentMint),
        ],
      ),
    );
  }
}

class _ClusterCountMarker extends StatelessWidget {
  const _ClusterCountMarker({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.accentBlue, AppColors.accentMint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _MarkerLogo extends StatelessWidget {
  const _MarkerLogo({required this.logoUrl, required this.fallbackText});

  final String? logoUrl;
  final String fallbackText;

  @override
  Widget build(BuildContext context) {
    if (logoUrl.isNotNullOrEmpty) {
      return Image.network(
        logoUrl!,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Center(
      child: Text(
        fallbackText.trim().isEmpty ? '?' : fallbackText.trim()[0],
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3BA8FF),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

LatestPriceEntry? _resolveMarkerFuel({
  required List<LatestPriceEntry> prices,
  required String? preferredFuelCode,
}) {
  final preferredFuel = _findFuelByCode(prices, preferredFuelCode);

  if (preferredFuel != null) {
    return preferredFuel;
  }

  return _findFuel95(prices) ?? (prices.isEmpty ? null : prices.first);
}

LatestPriceEntry? _findFuelByCode(
  List<LatestPriceEntry> prices,
  String? fuelCode,
) {
  final normalizedFuelCode = fuelCode?.trim().toLowerCase();

  if (normalizedFuelCode == null || normalizedFuelCode.isEmpty) {
    return null;
  }

  for (final entry in prices) {
    if (entry.fuelCode.toLowerCase() == normalizedFuelCode) {
      return entry;
    }
  }

  return null;
}

LatestPriceEntry? _findFuel95(List<LatestPriceEntry> prices) {
  for (final entry in prices) {
    final normalizedCode = entry.fuelCode.toLowerCase();
    final normalizedName = entry.fuelName.toLowerCase();

    if (normalizedCode.contains('95') || normalizedName.contains('95')) {
      return entry;
    }
  }

  return null;
}
