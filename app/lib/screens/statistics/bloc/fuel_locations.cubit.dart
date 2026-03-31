import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/statistics/bloc/fuel_locations.state.dart';
import 'package:app/screens/statistics/bloc/statistics.state.dart';

/// Loads stations for one fuel type and supports local search/sort.
class FuelLocationsCubit extends Cubit<FuelLocationsState> {
  FuelLocationsCubit({
    required StationsApiService stationsApiService,
    required AppBootRepository appBootRepository,
  }) : _stationsApiService = stationsApiService,
       _appBootRepository = appBootRepository,
       super(FuelLocationsState.initial());

  final StationsApiService _stationsApiService;
  final AppBootRepository _appBootRepository;

  static const Distance _distance = Distance();
  static const int _modeMinimumStations = 10;

  Future<void> load({
    required String fuelCode,
    required String fuelLabel,
  }) async {
    emit(
      state.copyWith(
        status: FuelLocationsStatus.loading,
        clearErrorMessage: true,
      ),
    );

    try {
      final boot = _appBootRepository.data;
      final List<StationWithPrices> stations;
      if (boot != null) {
        final pricesById = _appBootRepository.latestPricesFuture != null
            ? await _appBootRepository.latestPricesFuture!
            : await _stationsApiService.listLatestPrices();
        stations = mergeStationsWithPrices(boot.stations, pricesById);
      } else {
        final results = await Future.wait<dynamic>([
          _stationsApiService.listStations(),
          _stationsApiService.listLatestPrices(),
        ]);
        stations = mergeStationsWithPrices(
          results[0] as List<Station>,
          results[1] as Map<int, List<LatestPriceEntry>>,
        );
      }
      final userLocation =
          boot?.userLocation ?? await _checkUserLocation();
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
          statistics: allItems.isNotEmpty
              ? _computeStatistics(
                  fuelCode: normalizedFuelCode,
                  fuelLabel: fuelLabel,
                  items: allItems,
                )
              : null,
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

  FuelStatistics _computeStatistics({
    required String fuelCode,
    required String fuelLabel,
    required List<FuelLocationItem> items,
  }) {
    final sum = items.fold<double>(0, (v, item) => v + item.price);
    final averagePrice = sum / items.length;
    final averageDeviation = items.fold<double>(
          0,
          (v, item) => v + (item.price - averagePrice).abs(),
        ) /
        items.length;
    final averageDeviationPercent = averagePrice == 0
        ? 0.0
        : (averageDeviation / averagePrice) * 100.0;

    var minItem = items.first;
    var maxItem = items.first;
    var closestItem = items.first;

    for (final item in items) {
      if (item.price < minItem.price) minItem = item;
      if (item.price > maxItem.price) maxItem = item;
      final itemDist = item.distanceKm;
      final closestDist = closestItem.distanceKm;
      if (itemDist != null &&
          (closestDist == null || itemDist < closestDist)) {
        closestItem = item;
      }
    }

    final byPrice = <String, ({double price, int count})>{};
    for (final item in items) {
      final key = item.price.toStringAsFixed(3);
      final bucket = byPrice[key];
      byPrice[key] = bucket == null
          ? (price: item.price, count: 1)
          : (price: bucket.price, count: bucket.count + 1);
    }

    final stationCount = items.map((i) => i.stationPk).toSet().length;
    ({double price, String label}) primaryPrice;

    if (stationCount > _modeMinimumStations) {
      final top = byPrice.values.reduce(
        (a, b) => a.count >= b.count ? a : b,
      );
      primaryPrice = top.count >= 2
          ? (price: top.price, label: 'Most common price')
          : (price: averagePrice, label: 'Average price');
    } else {
      primaryPrice = (price: averagePrice, label: 'Average price');
    }

    final distribution =
        byPrice.values
            .map(
              (b) => PriceDistributionBucket(price: b.price, count: b.count),
            )
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price));

    StationPricePoint toPoint(FuelLocationItem item) => StationPricePoint(
      stationPk: item.stationPk,
      stationName: item.stationName,
      stationAddress: item.stationAddress,
      price: item.price,
      distanceKm: item.distanceKm,
    );

    return FuelStatistics(
      fuelCode: fuelCode,
      fuelLabel: fuelLabel,
      sampleCount: items.length,
      stationCount: stationCount,
      averagePrice: averagePrice,
      primaryPrice: primaryPrice.price,
      primaryPriceLabel: primaryPrice.label,
      averageDeviation: averageDeviation,
      averageDeviationPercent: averageDeviationPercent,
      closestToUser: toPoint(closestItem),
      minPricePoint: toPoint(minItem),
      maxPricePoint: toPoint(maxItem),
      priceDistribution: distribution,
    );
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

  /// Checks location permission and returns position if already granted.
  ///
  /// Does not request permission — that is handled once at startup.
  Future<LatLng?> _checkUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();

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
