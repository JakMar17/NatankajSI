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
    required this.averagesByFuelCode,
    required this.selectedFranchiseIds,
    required this.selectedFuelCodes,
    required this.preferredFuelCode,
    required this.selectedStation,
    required this.selectedStationDetail,
    required this.isLoadingStationDetail,
    required this.userLocation,
    required this.mapInitialCenter,
    required this.mapInitialZoom,
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
      averagesByFuelCode: const <String, double>{},
      selectedFranchiseIds: const <int>{},
      selectedFuelCodes: const <String>{},
      preferredFuelCode: null,
      selectedStation: null,
      selectedStationDetail: null,
      isLoadingStationDetail: false,
      userLocation: null,
      mapInitialCenter: defaultMapCenter,
      mapInitialZoom: 9,
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
  final Map<String, double> averagesByFuelCode;
  final Set<int> selectedFranchiseIds;
  final Set<String> selectedFuelCodes;
  final String? preferredFuelCode;
  final StationWithPrices? selectedStation;

  /// Full station detail fetched lazily from [GET /api/v1/stations/{id}].
  ///
  /// Null until the per-station detail request completes. Contains prices
  /// and MOL data that are not available in the lightweight station list.
  final StationWithPrices? selectedStationDetail;

  /// True while the per-station detail request is in flight.
  final bool isLoadingStationDetail;

  final LatLng? userLocation;

  /// Pre-computed initial center for [FlutterMap], set once in [loadData].
  final LatLng mapInitialCenter;

  /// Pre-computed initial zoom for [FlutterMap], set once in [loadData].
  final double mapInitialZoom;

  int get totalStations => allStations.length;

  bool get hasActiveFilters =>
      selectedFranchiseIds.isNotEmpty || selectedFuelCodes.isNotEmpty;

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
    Map<String, double>? averagesByFuelCode,
    Set<int>? selectedFranchiseIds,
    Set<String>? selectedFuelCodes,
    String? preferredFuelCode,
    bool clearPreferredFuelCode = false,
    StationWithPrices? selectedStation,
    bool clearSelectedStation = false,
    StationWithPrices? selectedStationDetail,
    bool clearSelectedStationDetail = false,
    bool? isLoadingStationDetail,
    LatLng? userLocation,
    LatLng? mapInitialCenter,
    double? mapInitialZoom,
  }) {
    final clearStation = clearSelectedStation;
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
      averagesByFuelCode: averagesByFuelCode ?? this.averagesByFuelCode,
      selectedFranchiseIds: selectedFranchiseIds ?? this.selectedFranchiseIds,
      selectedFuelCodes: selectedFuelCodes ?? this.selectedFuelCodes,
      preferredFuelCode: clearPreferredFuelCode
          ? null
          : (preferredFuelCode ?? this.preferredFuelCode),
      selectedStation: clearStation
          ? null
          : (selectedStation ?? this.selectedStation),
      selectedStationDetail: (clearStation || clearSelectedStationDetail)
          ? null
          : (selectedStationDetail ?? this.selectedStationDetail),
      isLoadingStationDetail: clearStation
          ? false
          : (isLoadingStationDetail ?? this.isLoadingStationDetail),
      userLocation: userLocation ?? this.userLocation,
      mapInitialCenter: mapInitialCenter ?? this.mapInitialCenter,
      mapInitialZoom: mapInitialZoom ?? this.mapInitialZoom,
    );
  }
}
