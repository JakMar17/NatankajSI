import 'dart:async';
import 'dart:math' as math;

import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/screens/stations_map/bloc/stations_map.state.dart';
import 'package:app/data/data.dart';

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
  }) : _stationsApiService = stationsApiService,
       _franchisesApiService = franchisesApiService,
       _fuelsApiService = fuelsApiService,
       super(StationsMapState.initial());

  final StationsApiService _stationsApiService;
  final FranchisesApiService _franchisesApiService;
  final FuelsApiService _fuelsApiService;
  Timer? _searchDebounce;

  static const Duration _searchDebounceDuration = Duration(milliseconds: 280);
  static const double _dropdownSelectionZoom = 16;
  static const double _userLocationZoom = 15;
  static const Distance _distance = Distance();
  static const String _preferredFuelCodeKey =
      'stations_map.preferred_fuel_code';

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final results = await Future.wait<dynamic>([
        _stationsApiService.listStations(),
        _franchisesApiService.listFranchises(),
        _fuelsApiService.listFuels(),
      ]);

      final stations = results[0] as List<StationWithPrices>;
      final franchises = results[1] as List<Franchise>;
      final fuels = results[2] as List<FuelType>;
      final stationsWithCoordinates = stations.whereToList(
        (station) => station.lat != null && station.lng != null,
      );
      final franchisesById = {
        for (final franchise in franchises) franchise.pk: franchise,
      };
      final fuelsByCode = {
        for (final fuel in fuels) fuel.code.toLowerCase(): fuel,
      };
      final preferredFuelCode = await _loadPreferredFuelCode();
      final resolvedPreferredFuelCode =
          preferredFuelCode != null && fuelsByCode.containsKey(preferredFuelCode)
          ? preferredFuelCode
          : null;
      final filteredStations = _filterStations(
        stations: stationsWithCoordinates,
        query: state.searchQuery,
        franchisesById: franchisesById,
        selectedFranchiseIds: state.selectedFranchiseIds,
        selectedFuelCodes: state.selectedFuelCodes,
      );

      emit(
        state.copyWith(
          isLoading: false,
          allStations: stationsWithCoordinates,
          stations: filteredStations,
          franchisesById: franchisesById,
          fuelsByCode: fuelsByCode,
          preferredFuelCode: resolvedPreferredFuelCode,
          clearSelectedStation: true,
        ),
      );

      if (preferredFuelCode != resolvedPreferredFuelCode) {
        await _savePreferredFuelCode(resolvedPreferredFuelCode);
      }

      await centerOnUserLocation();
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
    await _savePreferredFuelCode(normalizedPreferredFuelCode);
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

    emit(state.copyWith(selectedStation: station));
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

    emit(state.copyWith(selectedStation: station));
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

  StationWithPrices? _findNearestStation(LatLng userLocation) {
    if (state.allStations.isEmpty) {
      return null;
    }

    StationWithPrices? nearestStation;
    var nearestDistance = double.infinity;

    for (final station in state.allStations) {
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

  Future<String?> _loadPreferredFuelCode() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final savedValue = sharedPreferences.getString(_preferredFuelCodeKey);
    final normalizedValue = savedValue?.trim().toLowerCase();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    return normalizedValue;
  }

  Future<void> _savePreferredFuelCode(String? value) async {
    final sharedPreferences = await SharedPreferences.getInstance();

    if (value == null || value.isEmpty) {
      await sharedPreferences.remove(_preferredFuelCodeKey);
      return;
    }

    await sharedPreferences.setString(_preferredFuelCodeKey, value);
  }
}
