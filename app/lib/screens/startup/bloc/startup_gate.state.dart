import 'package:app/data/data.dart';

/// Startup gate status.
enum StartupGateStatus { loading, error, selectPreference, ready }

/// UI state for the startup preference gate.
class StartupGateState {
  const StartupGateState({
    required this.status,
    required this.fuels,
    required this.selectedFuelCode,
    required this.isSaving,
  });

  factory StartupGateState.initial() {
    return const StartupGateState(
      status: StartupGateStatus.loading,
      fuels: <FuelType>[],
      selectedFuelCode: null,
      isSaving: false,
    );
  }

  final StartupGateStatus status;
  final List<FuelType> fuels;
  final String? selectedFuelCode;
  final bool isSaving;

  StartupGateState copyWith({
    StartupGateStatus? status,
    List<FuelType>? fuels,
    String? selectedFuelCode,
    bool clearSelectedFuelCode = false,
    bool? isSaving,
  }) {
    return StartupGateState(
      status: status ?? this.status,
      fuels: fuels ?? this.fuels,
      selectedFuelCode: clearSelectedFuelCode
          ? null
          : (selectedFuelCode ?? this.selectedFuelCode),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
