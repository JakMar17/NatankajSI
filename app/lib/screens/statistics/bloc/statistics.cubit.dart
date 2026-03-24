
import 'package:dart_util_box/dart_util_box.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/stations_map/bloc/stations_map.cubit.dart';
import 'package:app/screens/statistics/bloc/statistics.state.dart';

/// Loads and computes fuel price statistics for the statistics tab.
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({
    required StationsApiService stationsApiService,
    required FuelsApiService fuelsApiService,
    required AppBootRepository appBootRepository,
  }) : _stationsApiService = stationsApiService,
       _fuelsApiService = fuelsApiService,
       _appBootRepository = appBootRepository,
       super(StatisticsState.initial());

  final StationsApiService _stationsApiService;
  final FuelsApiService _fuelsApiService;
  final AppBootRepository _appBootRepository;

  static const Distance _distance = Distance();
  static const int _modeMinimumStations = 10;

  Future<void> load() async {
    emit(
      state.copyWith(status: StatisticsStatus.loading, clearErrorMessage: true),
    );

    try {
      final List<StationWithPrices> stations;
      final List<FuelType> fuels;

      final boot = _appBootRepository.data;
      if (boot != null) {
        stations = boot.stations;
        fuels = boot.fuels;
      } else {
        final results = await Future.wait<dynamic>([
          _stationsApiService.listStations(),
          _fuelsApiService.listFuels(),
        ]);
        stations = results[0] as List<StationWithPrices>;
        fuels = results[1] as List<FuelType>;
      }

      final userLocation = boot?.userLocation ?? await _checkUserLocation();
      final preferredFuelCode = await StationsMapCubit.readPreferredFuelCode();
      final fuelLabels = {
        for (final fuel in fuels)
          fuel.code.trim().toLowerCase(): _labelForFuel(fuel),
      };
      final entriesByFuelCode = <String, List<_StationFuelSample>>{};

      for (final station in stations) {
        if (station.lat == null || station.lng == null) {
          continue;
        }

        for (final priceEntry in station.latestPrices) {
          final fuelCode = priceEntry.fuelCode.trim().toLowerCase();

          if (fuelCode.isEmpty) {
            continue;
          }

          entriesByFuelCode.putIfAbsent(fuelCode, () => <_StationFuelSample>[])
            ..add(
              _StationFuelSample(
                stationPk: station.pk,
                stationName: station.name,
                stationAddress: station.address,
                latitude: station.lat!,
                longitude: station.lng!,
                price: priceEntry.price,
              ),
            );
        }
      }

      final fuelStats =
          entriesByFuelCode.entries.mapToList(
            (entry) => _buildFuelStatistics(
              fuelCode: entry.key,
              fuelLabel: fuelLabels[entry.key] ?? entry.key.toUpperCase(),
              samples: entry.value,
              userLocation: userLocation,
            ),
          )..sort((left, right) {
            final leftPriority = _fuelSortPriority(
              fuelCode: left.fuelCode,
              preferredFuelCode: preferredFuelCode,
            );
            final rightPriority = _fuelSortPriority(
              fuelCode: right.fuelCode,
              preferredFuelCode: preferredFuelCode,
            );

            if (leftPriority != rightPriority) {
              return leftPriority.compareTo(rightPriority);
            }

            return left.fuelLabel.toLowerCase().compareTo(
              right.fuelLabel.toLowerCase(),
            );
          });

      emit(
        state.copyWith(
          status: StatisticsStatus.ready,
          userLocation: userLocation,
          fuelStats: fuelStats,
          generatedAt: DateTime.now(),
        ),
      );
    } on Exception catch (error) {
      emit(
        state.copyWith(
          status: StatisticsStatus.error,
          errorMessage: 'Failed to load statistics: $error',
        ),
      );
    }
  }

  FuelStatistics _buildFuelStatistics({
    required String fuelCode,
    required String fuelLabel,
    required List<_StationFuelSample> samples,
    required LatLng? userLocation,
  }) {
    final sum = samples.fold<double>(
      0,
      (value, sample) => value + sample.price,
    );
    final averagePrice = sum / samples.length;

    final minSample = _findMinPriceSample(samples);
    final maxSample = _findMaxPriceSample(samples);
    final closestToUser = _findClosestToUserSample(
      samples: samples,
      userLocation: userLocation,
    );
    final distinctStations = samples.map((sample) => sample.stationPk).toSet();
    final primaryPriceDetails = _resolvePrimaryPrice(
      samples: samples,
      averagePrice: averagePrice,
      stationCount: distinctStations.length,
    );
    final averageDeviation = _calculateAverageDeviation(
      samples: samples,
      averagePrice: averagePrice,
    );
    final averageDeviationPercent = averagePrice == 0
        ? 0.0
        : (averageDeviation / averagePrice) * 100.0;

    return FuelStatistics(
      fuelCode: fuelCode,
      fuelLabel: fuelLabel,
      sampleCount: samples.length,
      stationCount: distinctStations.length,
      averagePrice: averagePrice,
      primaryPrice: primaryPriceDetails.price,
      primaryPriceLabel: primaryPriceDetails.label,
      averageDeviation: averageDeviation,
      averageDeviationPercent: averageDeviationPercent,
      closestToUser: _toStationPricePoint(
        sample: closestToUser,
        userLocation: userLocation,
      ),
      minPricePoint: _toStationPricePoint(
        sample: minSample,
        userLocation: userLocation,
      ),
      maxPricePoint: _toStationPricePoint(
        sample: maxSample,
        userLocation: userLocation,
      ),
      priceDistribution: _buildPriceDistribution(samples),
    );
  }

  _StationFuelSample _findMinPriceSample(List<_StationFuelSample> samples) {
    var selected = samples.first;

    for (final sample in samples) {
      if (sample.price < selected.price) {
        selected = sample;
      }
    }

    return selected;
  }

  _StationFuelSample _findMaxPriceSample(List<_StationFuelSample> samples) {
    var selected = samples.first;

    for (final sample in samples) {
      if (sample.price > selected.price) {
        selected = sample;
      }
    }

    return selected;
  }

  _StationFuelSample _findClosestToUserSample({
    required List<_StationFuelSample> samples,
    required LatLng? userLocation,
  }) {
    if (userLocation == null) {
      return samples.first;
    }

    var selected = samples.first;
    var selectedDistance = _distanceFromUser(selected, userLocation);

    for (final sample in samples.skip(1)) {
      final sampleDistance = _distanceFromUser(sample, userLocation);

      if (sampleDistance < selectedDistance) {
        selected = sample;
        selectedDistance = sampleDistance;
      }
    }

    return selected;
  }

  _PrimaryPrice _resolvePrimaryPrice({
    required List<_StationFuelSample> samples,
    required double averagePrice,
    required int stationCount,
  }) {
    final shouldPreferMode = stationCount > _modeMinimumStations;

    if (!shouldPreferMode) {
      return _PrimaryPrice(price: averagePrice, label: 'Average price');
    }

    final byPrice = <String, _PriceBucket>{};

    for (final sample in samples) {
      final normalizedPrice = sample.price.toStringAsFixed(3);
      final bucket = byPrice[normalizedPrice];

      if (bucket == null) {
        byPrice[normalizedPrice] = _PriceBucket(price: sample.price, count: 1);
        continue;
      }

      byPrice[normalizedPrice] = _PriceBucket(
        price: bucket.price,
        count: bucket.count + 1,
      );
    }

    _PriceBucket? topBucket;

    for (final bucket in byPrice.values) {
      if (topBucket == null || bucket.count > topBucket.count) {
        topBucket = bucket;
      }
    }

    if (topBucket == null || topBucket.count < 2) {
      return _PrimaryPrice(price: averagePrice, label: 'Average price');
    }

    return _PrimaryPrice(price: topBucket.price, label: 'Most common price');
  }

  List<PriceDistributionBucket> _buildPriceDistribution(
    List<_StationFuelSample> samples,
  ) {
    final byPrice = <String, _PriceBucket>{};

    for (final sample in samples) {
      final key = sample.price.toStringAsFixed(3);
      final bucket = byPrice[key];

      byPrice[key] = bucket == null
          ? _PriceBucket(price: sample.price, count: 1)
          : _PriceBucket(price: bucket.price, count: bucket.count + 1);
    }

    final buckets =
        byPrice.values
            .map(
              (b) => PriceDistributionBucket(price: b.price, count: b.count),
            )
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price));

    return buckets;
  }

  double _calculateAverageDeviation({
    required List<_StationFuelSample> samples,
    required double averagePrice,
  }) {
    final totalDeviation = samples.fold<double>(
      0,
      (value, sample) => value + (sample.price - averagePrice).abs(),
    );

    return totalDeviation / samples.length;
  }

  StationPricePoint _toStationPricePoint({
    required _StationFuelSample sample,
    required LatLng? userLocation,
  }) {
    final distanceFromUser = userLocation == null
        ? null
        : _distanceFromUser(sample, userLocation);

    return StationPricePoint(
      stationPk: sample.stationPk,
      stationName: sample.stationName,
      stationAddress: sample.stationAddress,
      price: sample.price,
      distanceKm: distanceFromUser,
    );
  }

  double _distanceFromUser(_StationFuelSample sample, LatLng? userLocation) {
    if (userLocation == null) {
      return double.infinity;
    }

    return _distance.as(
      LengthUnit.Kilometer,
      userLocation,
      LatLng(sample.latitude, sample.longitude),
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

  String _labelForFuel(FuelType fuel) {
    final longName = fuel.longName?.trim();

    if (longName != null && longName.isNotEmpty) {
      return longName;
    }

    final shortName = fuel.name.trim();

    if (shortName.isNotEmpty) {
      return shortName;
    }

    return fuel.code;
  }

  int _fuelSortPriority({
    required String fuelCode,
    required String? preferredFuelCode,
  }) {
    if (preferredFuelCode != null && fuelCode == preferredFuelCode) {
      return 0;
    }

    if (fuelCode == '95') {
      return 1;
    }

    if (fuelCode == 'dizel') {
      return 2;
    }

    return 3;
  }
}

class _StationFuelSample {
  const _StationFuelSample({
    required this.stationPk,
    required this.stationName,
    required this.stationAddress,
    required this.latitude,
    required this.longitude,
    required this.price,
  });

  final int stationPk;
  final String stationName;
  final String? stationAddress;
  final double latitude;
  final double longitude;
  final double price;
}

class _PrimaryPrice {
  const _PrimaryPrice({required this.price, required this.label});

  final double price;
  final String label;
}

class _PriceBucket {
  const _PriceBucket({required this.price, required this.count});

  final double price;
  final int count;
}
