import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/data/data.dart';

const LatLng defaultMapCenter = LatLng(46.0569, 14.5058);

class StationsMapState {
  const StationsMapState({
    required this.mapController,
    required this.isLoading,
    required this.isLocating,
    required this.errorMessage,
    required this.searchQuery,
    required this.allStations,
    required this.stations,
    required this.franchisesById,
    required this.fuelsByCode,
    required this.selectedStation,
    required this.userLocation,
  });

  factory StationsMapState.initial() {
    return StationsMapState(
      mapController: MapController(),
      isLoading: true,
      isLocating: false,
      errorMessage: null,
      searchQuery: '',
      allStations: const <StationWithPrices>[],
      stations: const <StationWithPrices>[],
      franchisesById: const <int, Franchise>{},
      fuelsByCode: const <String, FuelType>{},
      selectedStation: null,
      userLocation: null,
    );
  }

  final MapController mapController;
  final bool isLoading;
  final bool isLocating;
  final String? errorMessage;
  final String searchQuery;
  final List<StationWithPrices> allStations;
  final List<StationWithPrices> stations;
  final Map<int, Franchise> franchisesById;
  final Map<String, FuelType> fuelsByCode;
  final StationWithPrices? selectedStation;
  final LatLng? userLocation;

  int get totalStations => allStations.length;

  LatLng get center {
    if (userLocation != null) {
      return userLocation!;
    }

    if (allStations.isEmpty) {
      return defaultMapCenter;
    }

    final totalLat = allStations.fold<double>(
      0,
      (sum, station) => sum + station.lat!,
    );
    final totalLng = allStations.fold<double>(
      0,
      (sum, station) => sum + station.lng!,
    );

    return LatLng(totalLat / allStations.length, totalLng / allStations.length);
  }

  StationsMapState copyWith({
    bool? isLoading,
    bool? isLocating,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? searchQuery,
    List<StationWithPrices>? allStations,
    List<StationWithPrices>? stations,
    Map<int, Franchise>? franchisesById,
    Map<String, FuelType>? fuelsByCode,
    StationWithPrices? selectedStation,
    bool clearSelectedStation = false,
    LatLng? userLocation,
  }) {
    return StationsMapState(
      mapController: mapController,
      isLoading: isLoading ?? this.isLoading,
      isLocating: isLocating ?? this.isLocating,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      allStations: allStations ?? this.allStations,
      stations: stations ?? this.stations,
      franchisesById: franchisesById ?? this.franchisesById,
      fuelsByCode: fuelsByCode ?? this.fuelsByCode,
      selectedStation: clearSelectedStation
          ? null
          : (selectedStation ?? this.selectedStation),
      userLocation: userLocation ?? this.userLocation,
    );
  }
}
