import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/startup/bloc/startup_gate.state.dart';
import 'package:app/screens/stations_map/bloc/stations_map.cubit.dart';

/// Handles first-run preferred fuel selection and pre-fetches all app data.
class StartupGateCubit extends Cubit<StartupGateState> {
  StartupGateCubit({
    required FuelsApiService fuelsApiService,
    required StationsApiService stationsApiService,
    required FranchisesApiService franchisesApiService,
    required RegulatedPricesApiService regulatedPricesApiService,
    required AppBootRepository appBootRepository,
  }) : _fuelsApiService = fuelsApiService,
       _stationsApiService = stationsApiService,
       _franchisesApiService = franchisesApiService,
       _regulatedPricesApiService = regulatedPricesApiService,
       _appBootRepository = appBootRepository,
       super(StartupGateState.initial());

  final FuelsApiService _fuelsApiService;
  final StationsApiService _stationsApiService;
  final FranchisesApiService _franchisesApiService;
  final RegulatedPricesApiService _regulatedPricesApiService;
  final AppBootRepository _appBootRepository;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: StartupGateStatus.loading,
        loadingMessage: 'Loading station data...',
        isSaving: false,
      ),
    );

    // Start the latest-prices fetch in the background immediately.
    // Feature screens will await [AppBootRepository.latestPricesFuture] when
    // they need price data; startup itself does not block on this.
    _appBootRepository.latestPricesFuture = _stationsApiService
        .listLatestPrices()
        .onError((error, stackTrace) {
          log('StartupGateCubit: latest-prices fetch failed: $error');
          return <int, List<LatestPriceEntry>>{};
        });

    try {
      final results = await Future.wait<dynamic>([
        _stationsApiService.listStations(),
        _franchisesApiService.listFranchises(),
        _fuelsApiService.listFuels(),
        _safeGetLatestRegulatedPrice(),
        _tryReadUserLocation(),
      ]);

      _appBootRepository.data = AppBootData(
        stations: results[0] as List<Station>,
        franchises: results[1] as List<Franchise>,
        fuels: results[2] as List<FuelType>,
        latestRegulatedPrice: results[3] as RegulatedPrice?,
        userLocation: results[4] as LatLng?,
      );

      final preferredFuelCode = await StationsMapCubit.readPreferredFuelCode();

      if (preferredFuelCode != null) {
        emit(
          state.copyWith(
            status: StartupGateStatus.ready,
            fuels: const <FuelType>[],
            clearSelectedFuelCode: true,
            clearLoadingMessage: true,
          ),
        );
        return;
      }

      final sortedFuels = List<FuelType>.from(
        _appBootRepository.data!.fuels,
      )..sort((left, right) {
          final leftPriority = _fuelSortPriority(left);
          final rightPriority = _fuelSortPriority(right);
          if (leftPriority != rightPriority) {
            return leftPriority.compareTo(rightPriority);
          }
          return labelForFuel(
            left,
          ).toLowerCase().compareTo(labelForFuel(right).toLowerCase());
        });

      emit(
        state.copyWith(
          status: StartupGateStatus.selectPreference,
          fuels: sortedFuels,
          clearSelectedFuelCode: true,
          clearLoadingMessage: true,
          isSaving: false,
        ),
      );
    } on Exception catch (error) {
      log('StartupGateCubit.load failed: $error');
      emit(state.copyWith(status: StartupGateStatus.error, isSaving: false));
    }
  }

  void selectFuelCode(String? fuelCode) {
    emit(state.copyWith(selectedFuelCode: fuelCode));
  }

  Future<void> confirmSelection() async {
    final selectedFuelCode = state.selectedFuelCode;

    if (selectedFuelCode == null || state.isSaving) {
      return;
    }

    emit(state.copyWith(isSaving: true));

    try {
      await StationsMapCubit.writePreferredFuelCode(selectedFuelCode);
      emit(state.copyWith(status: StartupGateStatus.ready, isSaving: false));
    } on Exception {
      emit(state.copyWith(status: StartupGateStatus.error, isSaving: false));
    }
  }

  String labelForFuel(FuelType fuel) {
    final longName = fuel.longName?.trim();

    if (longName != null && longName.isNotEmpty) {
      return longName;
    }

    if (fuel.name.trim().isNotEmpty) {
      return fuel.name.trim();
    }

    return fuel.code;
  }

  int _fuelSortPriority(FuelType fuel) {
    final normalizedCode = fuel.code.trim().toLowerCase();

    if (normalizedCode == '95') {
      return 0;
    }

    if (normalizedCode == 'dizel') {
      return 1;
    }

    return 2;
  }

  Future<RegulatedPrice?> _safeGetLatestRegulatedPrice() async {
    try {
      return await _regulatedPricesApiService.getLatest();
    } on Exception {
      return null;
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

      if (!enabled) {
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
