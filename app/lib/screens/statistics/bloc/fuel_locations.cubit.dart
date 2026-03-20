import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/statistics/bloc/fuel_locations.state.dart';

/// Loads stations for one fuel type and supports local search/sort.
class FuelLocationsCubit extends Cubit<FuelLocationsState> {
  FuelLocationsCubit({required StationsApiService stationsApiService})
    : _stationsApiService = stationsApiService,
      super(FuelLocationsState.initial());

  final StationsApiService _stationsApiService;

  static const Distance _distance = Distance();

  Future<void> load({required String fuelCode}) async {
    emit(
      state.copyWith(
        status: FuelLocationsStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final stations = await _stationsApiService.listStations();
      final userLocation = await _tryReadUserLocation();
      final normalizedFuelCode = fuelCode.trim().toLowerCase();
      final allItems = <FuelLocationItem>[];

      for (final station in stations) {
        if (station.lat == null || station.lng == null) {
          continue;
        }

        LatestPriceEntry? matchingEntry;

        for (final entry in station.latestPrices) {
          if (entry.fuelCode.trim().toLowerCase() == normalizedFuelCode) {
            matchingEntry = entry;
            break;
          }
        }

        if (matchingEntry == null) {
          continue;
        }

        allItems.add(
          FuelLocationItem(
            stationPk: station.pk,
            stationName: station.name,
            stationAddress: station.address,
            franchiseName: station.franchiseName,
            openHours: station.openHours,
            price: matchingEntry.price,
            distanceKm: _distanceFromUser(
              latitude: station.lat!,
              longitude: station.lng!,
              userLocation: userLocation,
            ),
          ),
        );
      }

      emit(
        state.copyWith(
          status: FuelLocationsStatus.ready,
          allItems: allItems,
          searchQuery: '',
          orderBy: FuelLocationsOrderBy.distance,
          isAscending: true,
        ),
      );
      _applyFilters();
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: FuelLocationsStatus.error,
          errorMessage: 'Failed to load stations: $error',
        ),
      );
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters();
  }

  void setOrderBy(FuelLocationsOrderBy orderBy) {
    emit(state.copyWith(orderBy: orderBy));
    _applyFilters();
  }

  void setDirection(bool isAscending) {
    emit(state.copyWith(isAscending: isAscending));
    _applyFilters();
  }

  void _applyFilters() {
    final normalizedQuery = state.searchQuery.trim().toLowerCase();
    final filtered = state.allItems.whereToList((item) {
      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = <String?>[
        item.stationName,
        item.stationAddress,
        item.franchiseName,
      ].whereType<String>().map((value) => value.toLowerCase());

      return haystack.any((value) => value.contains(normalizedQuery));
    });

    filtered.sort(
      (left, right) => _compare(
        left,
        right,
        orderBy: state.orderBy,
        isAscending: state.isAscending,
      ),
    );

    emit(state.copyWith(visibleItems: filtered));
  }

  int _compare(
    FuelLocationItem left,
    FuelLocationItem right, {
    required FuelLocationsOrderBy orderBy,
    required bool isAscending,
  }) {
    switch (orderBy) {
      case FuelLocationsOrderBy.distance:
        return _compareDistance(
          left.distanceKm,
          right.distanceKm,
          asc: isAscending,
        );
      case FuelLocationsOrderBy.price:
        if (isAscending) {
          return left.price.compareTo(right.price);
        }

        return right.price.compareTo(left.price);
    }
  }

  int _compareDistance(double? left, double? right, {required bool asc}) {
    if (left == null && right == null) {
      return 0;
    }

    if (left == null) {
      return 1;
    }

    if (right == null) {
      return -1;
    }

    if (asc) {
      return left.compareTo(right);
    }

    return right.compareTo(left);
  }

  double? _distanceFromUser({
    required double latitude,
    required double longitude,
    required LatLng? userLocation,
  }) {
    if (userLocation == null) {
      return null;
    }

    return _distance.as(
      LengthUnit.Kilometer,
      userLocation,
      LatLng(latitude, longitude),
    );
  }

  Future<LatLng?> _tryReadUserLocation() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      return LatLng(position.latitude, position.longitude);
    } on Exception {
      return null;
    }
  }
}
