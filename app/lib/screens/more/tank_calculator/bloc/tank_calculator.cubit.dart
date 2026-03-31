import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/more/tank_calculator/bloc/tank_calculator.state.dart';

/// Loads station prices and computes tank cost summaries.
class TankCalculatorCubit extends Cubit<TankCalculatorState> {
  TankCalculatorCubit({
    required StationsApiService stationsApiService,
    required AppBootRepository appBootRepository,
    required RegulatedPricesApiService regulatedPricesApiService,
  }) : _stationsApiService = stationsApiService,
       _appBootRepository = appBootRepository,
       _regulatedPricesApiService = regulatedPricesApiService,
       super(TankCalculatorState.initial());

  final StationsApiService _stationsApiService;
  final AppBootRepository _appBootRepository;
  final RegulatedPricesApiService _regulatedPricesApiService;

  static const Distance _distance = Distance();
  static const double _nearbyRadiusKm = 30;
  static const double _maxRadiusKm = 1000;
  static const String _preferredFuelKey = 'stations_map.preferred_fuel_code';
  static const String _capacityKey = 'tank_calculator.capacity_liters';

  List<StationWithPrices> _cachedStations = [];
  LatLng? _userLocation;

  Future<void> load() async {
    emit(TankCalculatorState.initial());
    try {
      final boot = _appBootRepository.data;
      if (boot != null) {
        final pricesById = _appBootRepository.latestPricesFuture != null
            ? await _appBootRepository.latestPricesFuture!
            : await _stationsApiService.listLatestPrices();
        _cachedStations = mergeStationsWithPrices(boot.stations, pricesById);
        _userLocation = boot.userLocation;
      } else {
        final results = await Future.wait([
          _stationsApiService.listStations(),
          _stationsApiService.listLatestPrices(),
          _tryReadUserLocation(),
        ]);
        _cachedStations = mergeStationsWithPrices(
          results[0] as List<Station>,
          results[1] as Map<int, List<LatestPriceEntry>>,
        );
        _userLocation = results[2] as LatLng?;
      }

      final fuelCodes = _extractFuelCodes(_cachedStations);
      final fuelNames = _extractFuelNames(_cachedStations);
      final preferred = await _readPreferredFuelCode(fuelCodes);
      final savedCapacity = await _readSavedCapacity();
      final regulatedHistory = await _loadRegulatedHistorySafely();

      emit(
        _computeResults(
          fuelCode: preferred,
          availableFuelCodes: fuelCodes,
          fuelNames: fuelNames,
          capacityLiters: savedCapacity,
          regulatedPriceHistory: regulatedHistory,
        ),
      );
    } on Exception catch (e) {
      log('TankCalculatorCubit.load failed: $e');
      emit(
        TankCalculatorState(
          status: TankCalculatorStatus.error,
          capacityLiters: state.capacityLiters,
          availableFuelCodes: const [],
          errorMessage: 'Could not load station data.',
        ),
      );
    }
  }

  void setCapacity(double liters) {
    if (liters <= 0) return;
    emit(state.withCapacity(liters));
    _saveCapacity(liters);
  }

  void selectFuel(String fuelCode) {
    if (_cachedStations.isEmpty) return;
    emit(
      _computeResults(
        fuelCode: fuelCode,
        availableFuelCodes: state.availableFuelCodes,
        fuelNames: state.fuelNames,
        capacityLiters: state.capacityLiters,
        regulatedPriceHistory: state.regulatedPriceHistory,
      ),
    );
  }

  TankCalculatorState _computeResults({
    required String fuelCode,
    required List<String> availableFuelCodes,
    required Map<String, String> fuelNames,
    required double capacityLiters,
    required List<RegulatedPrice> regulatedPriceHistory,
  }) {
    final normalizedCode = fuelCode.trim().toLowerCase();
    final items = <_StationItem>[];

    for (final station in _cachedStations) {
      if (station.lat == null || station.lng == null) continue;

      LatestPriceEntry? entry;
      for (final e in station.latestPrices) {
        if (e.fuelCode.trim().toLowerCase() == normalizedCode) {
          entry = e;
          break;
        }
      }
      if (entry == null) continue;

      final distanceKm = _userLocation == null
          ? null
          : _distance.as(
              LengthUnit.Kilometer,
              _userLocation!,
              LatLng(station.lat!, station.lng!),
            );

      items.add(
        _StationItem(
          pk: station.pk,
          name: station.name,
          address: station.address,
          franchiseName: station.franchiseName,
          pricePerLiter: entry.price,
          distanceKm: distanceKm,
        ),
      );
    }

    if (items.isEmpty) {
      return TankCalculatorState(
        status: TankCalculatorStatus.error,
        capacityLiters: capacityLiters,
        fuelCode: fuelCode,
        availableFuelCodes: availableFuelCodes,
        regulatedPriceHistory: regulatedPriceHistory,
        fuelNames: fuelNames,
        errorMessage: 'No stations found for selected fuel.',
      );
    }

    StationSummary? closestStation;
    StationSummary? cheapestNearby;
    StationSummary? mostExpensiveNearby;

    if (_userLocation != null) {
      _StationItem? closest;
      for (final item in items) {
        final d = item.distanceKm;
        if (d == null) continue;
        if (closest == null || d < closest.distanceKm!) closest = item;
      }
      closestStation = closest?.toSummary();

      final nearby = items
          .where((i) => (i.distanceKm ?? double.infinity) <= _nearbyRadiusKm)
          .toList();
      if (nearby.isNotEmpty) {
        cheapestNearby = nearby
            .reduce((a, b) => a.pricePerLiter < b.pricePerLiter ? a : b)
            .toSummary();
        mostExpensiveNearby = nearby
            .reduce((a, b) => a.pricePerLiter > b.pricePerLiter ? a : b)
            .toSummary();
      }
    }

    // Use 1 000 km radius when location is known, otherwise all stations.
    final searchSpace = _userLocation != null
        ? items
              .where((i) => (i.distanceKm ?? double.infinity) <= _maxRadiusKm)
              .toList()
        : items;
    final pool = searchSpace.isNotEmpty ? searchSpace : items;

    final cheapestAll = pool
        .reduce((a, b) => a.pricePerLiter < b.pricePerLiter ? a : b)
        .toSummary();
    final mostExpensiveAll = pool
        .reduce((a, b) => a.pricePerLiter > b.pricePerLiter ? a : b)
        .toSummary();

    return TankCalculatorState(
      status: TankCalculatorStatus.ready,
      capacityLiters: capacityLiters,
      fuelCode: fuelCode,
      availableFuelCodes: availableFuelCodes,
      regulatedPriceHistory: regulatedPriceHistory,
      fuelNames: fuelNames,
      hasLocation: _userLocation != null,
      closestStation: closestStation,
      cheapestNearby: cheapestNearby,
      mostExpensiveNearby: mostExpensiveNearby,
      cheapestAll: cheapestAll,
      mostExpensiveAll: mostExpensiveAll,
    );
  }

  Future<List<RegulatedPrice>> _loadRegulatedHistorySafely() async {
    try {
      final raw = await _regulatedPricesApiService.list();
      final sorted = [...raw]
        ..sort((a, b) => a.validFrom.compareTo(b.validFrom));
      return _forwardFillToToday(sorted);
    } on Exception catch (e) {
      log('TankCalculatorCubit._loadRegulatedHistorySafely failed: $e');
      return const [];
    }
  }

  static List<RegulatedPrice> _forwardFillToToday(List<RegulatedPrice> sorted) {
    if (sorted.isEmpty) return sorted;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = <RegulatedPrice>[];

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      result.add(current);

      final nextDate = (i + 1 < sorted.length)
          ? sorted[i + 1].validFrom
          : today.add(const Duration(days: 1));

      var day = DateTime(
        current.validFrom.year,
        current.validFrom.month,
        current.validFrom.day + 1,
      );
      while (day.isBefore(nextDate) && !day.isAfter(today)) {
        result.add(
          RegulatedPrice(
            pk: current.pk,
            validFrom: day,
            petrolPrice: current.petrolPrice,
            dieselPrice: current.dieselPrice,
          ),
        );
        day = day.add(const Duration(days: 1));
      }
    }
    return result;
  }

  List<String> _extractFuelCodes(List<StationWithPrices> stations) {
    final codes = <String>{};
    for (final station in stations) {
      for (final entry in station.latestPrices) {
        codes.add(entry.fuelCode.trim().toLowerCase());
      }
    }
    final sorted = codes.toList()
      ..sort((a, b) {
        const priority = ['95', 'dizel'];
        final ai = priority.indexOf(a);
        final bi = priority.indexOf(b);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return a.compareTo(b);
      });
    return sorted;
  }

  Map<String, String> _extractFuelNames(List<StationWithPrices> stations) {
    final names = <String, String>{};
    for (final station in stations) {
      for (final entry in station.latestPrices) {
        final code = entry.fuelCode.trim().toLowerCase();
        names.putIfAbsent(code, () => entry.fuelName);
      }
    }
    return names;
  }

  Future<String> _readPreferredFuelCode(List<String> codes) async {
    if (codes.isEmpty) return '95';
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_preferredFuelKey);
      if (saved != null && codes.contains(saved)) return saved;
    } on Exception {
      // fall through
    }
    return codes.first;
  }

  Future<double> _readSavedCapacity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getDouble(_capacityKey);
      if (saved != null && saved > 0) return saved;
    } on Exception {
      // fall through
    }
    return 50;
  }

  Future<void> _saveCapacity(double liters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_capacityKey, liters);
    } on Exception catch (e) {
      log('TankCalculatorCubit._saveCapacity failed: $e');
    }
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
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
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

class _StationItem {
  const _StationItem({
    required this.pk,
    required this.name,
    this.address,
    this.franchiseName,
    required this.pricePerLiter,
    this.distanceKm,
  });

  final int pk;
  final String name;
  final String? address;
  final String? franchiseName;
  final double pricePerLiter;
  final double? distanceKm;

  StationSummary toSummary() => StationSummary(
    pk: pk,
    name: name,
    address: address,
    franchiseName: franchiseName,
    pricePerLiter: pricePerLiter,
    distanceKm: distanceKm,
  );
}
