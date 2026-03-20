import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:app/data/data.dart';
import 'package:app/screens/startup/bloc/startup_gate.state.dart';
import 'package:app/screens/stations_map/bloc/stations_map.cubit.dart';

/// Handles first-run preferred fuel selection flow.
class StartupGateCubit extends Cubit<StartupGateState> {
  StartupGateCubit({required FuelsApiService fuelsApiService})
    : _fuelsApiService = fuelsApiService,
      super(StartupGateState.initial());

  final FuelsApiService _fuelsApiService;

  Future<void> load() async {
    emit(state.copyWith(status: StartupGateStatus.loading, isSaving: false));

    try {
      final preferredFuelCode = await StationsMapCubit.readPreferredFuelCode();

      if (preferredFuelCode != null) {
        emit(
          state.copyWith(
            status: StartupGateStatus.ready,
            fuels: const <FuelType>[],
            clearSelectedFuelCode: true,
          ),
        );
        return;
      }

      final fuels = await _fuelsApiService.listFuels();
      final sortedFuels = List<FuelType>.from(fuels)
        ..sort((left, right) {
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
          isSaving: false,
        ),
      );
    } on Exception {
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
}
