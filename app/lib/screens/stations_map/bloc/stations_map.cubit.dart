import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;

import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/stations_map/bloc/stations_map.state.dart';

enum LocationCenteringResult {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  error,
}

class StationsMapCubit extends Cubit<StationsMapState> {
  StationsMapCubit({
    required StationsApiService stationsApiService,
    required FranchisesApiService franchisesApiService,
    required FuelsApiService fuelsApiService,
    required AppBootRepository appBootRepository,
  }) : _stationsApiService = stationsApiService,
       _franchisesApiService = franchisesApiService,
       _fuelsApiService = fuelsApiService,
       _appBootRepository = appBootRepository,
       super(StationsMapState.initial());

  final StationsApiService _stationsApiService;
  final FranchisesApiService _franchisesApiService;
  final FuelsApiService _fuelsApiService;
  final AppBootRepository _appBootRepository;
  Timer? _searchDebounce;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 280);
  static const double _dropdownSelectionZoom = 16;
  static const double _userLocationZoom = 15;
  static const Distance _distance = Distance();
  static const String preferredFuelCodeStorageKey =
      'stations_map.preferred_fuel_code';

  // Lightweight station list used to apply prices once they arrive.
  List<Station> _rawStations = const [];

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final List<Franchise> franchises;
      final List<FuelType> fuels;
      final Future<Map<int, List<LatestPriceEntry>>> pricesFuture;

      final boot = _appBootRepository.data;
      if (boot != null) {
        _rawStations = boot.stations;
        franchises = boot.franchises;
        fuels = boot.fuels;
        pricesFuture = _appBootRepository.latestPricesFuture ??
            _stationsApiService.listLatestPrices();
      } else {
        final results = await Future.wait<dynamic>([
          _stationsApiService.listStations(),
          _franchisesApiService.listFranchises(),
          _fuelsApiService.listFuels(),
        ]);
        _rawStations = results[0] as List<Station>;
        franchises = results[1] as List<Franchise>;
        fuels = results[2] as List<FuelType>;
        pricesFuture = _stationsApiService.listLatestPrices();
      }

      final franchisesById = {
        for (final franchise in franchises) franchise.pk: franchise,
      };
      final fuelsByCode = {
        for (final fuel in fuels) fuel.code.toLowerCase(): fuel,
      };
      final preferredFuelCode = await readPreferredFuelCode();
      final resolvedPreferredFuelCode =
          preferredFuelCode != null &&
              fuelsByCode.containsKey(preferredFuelCode)
          ? preferredFuelCode
          : null;

      // Show stations on map immediately without waiting for prices.
      final stationsNoPrices = mergeStationsWithPrices(_rawStations, const {});
      final stationsWithCoords = stationsNoPrices.whereToList(
        (s) => s.lat != null && s.lng != null,
      );
      final filteredStations = _filterStations(
        stations: stationsWithCoords,
        query: state.searchQuery,
        franchisesById: franchisesById,
        selectedFranchiseIds: state.selectedFranchiseIds,
        selectedFuelCodes: state.selectedFuelCodes,
      );

      final bootLocation = boot?.userLocation;

      LatLng mapInitialCenter = defaultMapCenter;
      double mapInitialZoom = 9;
      if (bootLocation != null) {
        final nearest = _findNearestStationFrom(
          bootLocation,
          stationsWithCoords,
        );
        if (nearest != null && nearest.lat != null && nearest.lng != null) {
          final nearestLoc = LatLng(nearest.lat!, nearest.lng!);
          final distKm = _distance.as(
            LengthUnit.Kilometer,
            bootLocation,
            nearestLoc,
          );
          mapInitialCenter = LatLng(
            (bootLocation.latitude + nearestLoc.latitude) / 2,
            (bootLocation.longitude + nearestLoc.longitude) / 2,
          );
          mapInitialZoom = _zoomForDistance(distKm);
        } else {
          mapInitialCenter = bootLocation;
          mapInitialZoom = _userLocationZoom;
        }
      }

      emit(
        state.copyWith(
          isLoading: false,
          allStations: stationsWithCoords,
          stations: filteredStations,
          franchisesById: franchisesById,
          fuelsByCode: fuelsByCode,
          averagesByFuelCode: const {},
          preferredFuelCode: resolvedPreferredFuelCode,
          clearSelectedStation: true,
          userLocation: bootLocation,
          mapInitialCenter: mapInitialCenter,
          mapInitialZoom: mapInitialZoom,
        ),
      );

      if (preferredFuelCode != resolvedPreferredFuelCode) {
        await writePreferredFuelCode(resolvedPreferredFuelCode);
      }

      if (bootLocation == null) {
        unawaited(centerOnUserLocation());
      }

      // Wait for prices and update the map once they arrive.
      final pricesById = await pricesFuture;
      if (isClosed) return;

      final stationsWithPrices = mergeStationsWithPrices(_rawStations, pricesById);
      final allWithCoords = stationsWithPrices.whereToList(
        (s) => s.lat != null && s.lng != null,
      );
      final filteredWithPrices = _filterStations(
        stations: allWithCoords,
        query: state.searchQuery,
        franchisesById: state.franchisesById,
        selectedFranchiseIds: state.selectedFranchiseIds,
        selectedFuelCodes: state.selectedFuelCodes,
      );

      emit(
        state.copyWith(
          allStations: allWithCoords,
          stations: filteredWithPrices,
          averagesByFuelCode: _computeAveragesByFuelCode(allWithCoords),
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load stations: $error',
        ),
      );
    }
  }

  void onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();

    emit(
      state.copyWith(
        searchQuery: query,
        clearSelectedStation: query.trim().isNotEmpty,
      ),
    );

    _searchDebounce = Timer(_searchDebounceDuration, () {
      _applyFilters();
    });
  }

  void applyFilters({
    required Set<int> franchiseIds,
    required Set<String> fuelCodes,
    required String? preferredFuelCode,
  }) async {
    final normalizedPreferredFuelCode = preferredFuelCode?.toLowerCase();

    emit(
      state.copyWith(
        selectedFranchiseIds: franchiseIds,
        selectedFuelCodes: fuelCodes.map((code) => code.toLowerCase()).toSet(),
        preferredFuelCode: normalizedPreferredFuelCode,
        clearPreferredFuelCode: normalizedPreferredFuelCode == null,
      ),
    );
    await writePreferredFuelCode(normalizedPreferredFuelCode);
    _applyFilters();
  }

  void clearFilters() {
    emit(
      state.copyWith(
        selectedFranchiseIds: const <int>{},
        selectedFuelCodes: const <String>{},
      ),
    );
    _applyFilters();
  }

  void _applyFilters() {
    final filteredStations = _filterStations(
      stations: state.allStations,
      query: state.searchQuery,
      franchisesById: state.franchisesById,
      selectedFranchiseIds: state.selectedFranchiseIds,
      selectedFuelCodes: state.selectedFuelCodes,
    );

    final selectedStation = state.selectedStation;
    final hasSelectedStation = selectedStation != null;
    final selectedIsVisible =
        hasSelectedStation &&
        filteredStations.any((station) => station.pk == selectedStation.pk);

    emit(
      state.copyWith(
        stations: filteredStations,
        clearSelectedStation: hasSelectedStation && !selectedIsVisible,
      ),
    );
  }

  Map<String, double> _computeAveragesByFuelCode(
    List<StationWithPrices> stations,
  ) {
    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final station in stations) {
      for (final entry in station.latestPrices) {
        final code = entry.fuelCode.trim().toLowerCase();
        sums[code] = (sums[code] ?? 0) + entry.price;
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }

    return {
      for (final code in sums.keys) code: sums[code]! / counts[code]!,
    };
  }

  List<StationWithPrices> _filterStations({
    required List<StationWithPrices> stations,
    required String query,
    required Map<int, Franchise> franchisesById,
    required Set<int> selectedFranchiseIds,
    required Set<String> selectedFuelCodes,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty &&
        selectedFranchiseIds.isEmpty &&
        selectedFuelCodes.isEmpty) {
      return stations;
    }

    return stations.whereToList((station) {
      final franchise = station.franchiseId == null
          ? null
          : franchisesById[station.franchiseId];
      final haystack = <String?>[
        station.name,
        station.address,
        station.zipCode,
        station.openHours,
        station.franchiseName,
        franchise?.name,
      ].whereType<String>().map((value) => value.toLowerCase());
      final matchesQuery =
          normalizedQuery.isEmpty ||
          haystack.any((value) => value.contains(normalizedQuery));
      final matchesFranchise =
          selectedFranchiseIds.isEmpty ||
          (station.franchiseId != null &&
              selectedFranchiseIds.contains(station.franchiseId));
      final matchesFuel =
          selectedFuelCodes.isEmpty ||
          station.latestPrices.any(
            (price) => selectedFuelCodes.contains(price.fuelCode.toLowerCase()),
          );

      return matchesQuery && matchesFranchise && matchesFuel;
    });
  }

  void selectStation(StationWithPrices station) {
    final latitude = station.lat;
    final longitude = station.lng;

    if (latitude != null && longitude != null) {
      state.mapController.move(
        LatLng(latitude, longitude),
        math.max(state.mapController.camera.zoom, 12),
      );
    }

    emit(
      state.copyWith(
        selectedStation: station,
        clearSelectedStationDetail: true,
        isLoadingStationDetail: true,
      ),
    );
    unawaited(_loadStationDetail(station.pk));
  }

  Future<void> _loadStationDetail(int pk) async {
    try {
      final detail = await _stationsApiService.getStation(pk: pk);
      if (state.selectedStation?.pk == pk) {
        emit(
          state.copyWith(
            selectedStationDetail: detail,
            isLoadingStationDetail: false,
          ),
        );
      }
    } on Exception catch (error) {
      log('_loadStationDetail failed for pk=$pk: $error');
      if (state.selectedStation?.pk == pk) {
        emit(state.copyWith(isLoadingStationDetail: false));
      }
    }
  }

  void selectStationFromDropdown(StationWithPrices station) {
    final latitude = station.lat;
    final longitude = station.lng;

    if (latitude != null && longitude != null) {
      state.mapController.move(
        LatLng(latitude, longitude),
        _dropdownSelectionZoom,
      );
    }

    emit(
      state.copyWith(
        selectedStation: station,
        clearSelectedStationDetail: true,
        isLoadingStationDetail: true,
      ),
    );
    unawaited(_loadStationDetail(station.pk));
  }

  void selectStationByPk(int stationPk) {
    StationWithPrices? station;

    for (final entry in state.allStations) {
      if (entry.pk == stationPk) {
        station = entry;
        break;
      }
    }

    if (station == null) {
      return;
    }

    selectStation(station);
  }

  void clearSelection() {
    if (state.selectedStation == null) {
      return;
    }

    emit(state.copyWith(clearSelectedStation: true));
  }

  Future<LocationCenteringResult> centerOnUserLocation() async {
    if (state.isLocating) {
      return LocationCenteringResult.error;
    }

    emit(state.copyWith(isLocating: true));

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(isLocating: false));
        return LocationCenteringResult.permissionDenied;
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(isLocating: false));
        return LocationCenteringResult.permissionDeniedForever;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        emit(state.copyWith(isLocating: false));
        return LocationCenteringResult.serviceDisabled;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final userLocation = LatLng(position.latitude, position.longitude);
      final nearestStation = _findNearestStation(userLocation);

      if (nearestStation == null ||
          nearestStation.lat == null ||
          nearestStation.lng == null) {
        state.mapController.move(
          userLocation,
          math.max(state.mapController.camera.zoom, _userLocationZoom),
        );
      } else {
        final nearestLocation = LatLng(
          nearestStation.lat!,
          nearestStation.lng!,
        );
        final center = LatLng(
          (userLocation.latitude + nearestLocation.latitude) / 2,
          (userLocation.longitude + nearestLocation.longitude) / 2,
        );
        final distanceInKm = _distance.as(
          LengthUnit.Kilometer,
          userLocation,
          nearestLocation,
        );

        state.mapController.move(center, _zoomForDistance(distanceInKm));
      }

      emit(state.copyWith(isLocating: false, userLocation: userLocation));
      return LocationCenteringResult.success;
    } on Exception {
      emit(state.copyWith(isLocating: false));
      return LocationCenteringResult.error;
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  StationWithPrices? _findNearestStation(LatLng userLocation) =>
      _findNearestStationFrom(userLocation, state.allStations);

  StationWithPrices? _findNearestStationFrom(
    LatLng userLocation,
    List<StationWithPrices> stations,
  ) {
    if (stations.isEmpty) {
      return null;
    }

    StationWithPrices? nearestStation;
    var nearestDistance = double.infinity;

    for (final station in stations) {
      final latitude = station.lat;
      final longitude = station.lng;

      if (latitude == null || longitude == null) {
        continue;
      }

      final stationLocation = LatLng(latitude, longitude);
      final distance = _distance.as(
        LengthUnit.Kilometer,
        userLocation,
        stationLocation,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestStation = station;
      }
    }

    return nearestStation;
  }

  double _zoomForDistance(double distanceInKm) {
    if (distanceInKm <= 0.4) {
      return 16;
    }

    if (distanceInKm <= 1) {
      return 15;
    }

    if (distanceInKm <= 2) {
      return 14;
    }

    if (distanceInKm <= 5) {
      return 13;
    }

    if (distanceInKm <= 10) {
      return 12;
    }

    if (distanceInKm <= 20) {
      return 11;
    }

    if (distanceInKm <= 40) {
      return 10;
    }

    return 9;
  }

  /// Reads preferred fuel code from persistent storage.
  static Future<String?> readPreferredFuelCode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final savedValue = sharedPreferences.getString(preferredFuelCodeStorageKey);
    final normalizedValue = savedValue?.trim().toLowerCase();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }

  /// Writes preferred fuel code to persistent storage.
  static Future<void> writePreferredFuelCode(String? value) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    if (value == null || value.isEmpty) {
      await sharedPreferences.remove(preferredFuelCodeStorageKey);
      return;
    }

    await sharedPreferences.setString(preferredFuelCodeStorageKey, value);
  }
}
