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
    this.loadingMessage,
  });

  factory StartupGateState.initial() {
    return const StartupGateState(
      status: StartupGateStatus.loading,
      fuels: <FuelType>[],
      selectedFuelCode: null,
      isSaving: false,
      loadingMessage: 'Loading station data...',
    );
  }

  final StartupGateStatus status;
  final List<FuelType> fuels;
  final String? selectedFuelCode;
  final bool isSaving;
  final String? loadingMessage;

  StartupGateState copyWith({
    StartupGateStatus? status,
    List<FuelType>? fuels,
    String? selectedFuelCode,
    bool clearSelectedFuelCode = false,
    bool? isSaving,
    String? loadingMessage,
    bool clearLoadingMessage = false,
  }) {
    return StartupGateState(
      status: status ?? this.status,
      fuels: fuels ?? this.fuels,
      selectedFuelCode: clearSelectedFuelCode
          ? null
          : (selectedFuelCode ?? this.selectedFuelCode),
      isSaving: isSaving ?? this.isSaving,
      loadingMessage: clearLoadingMessage
          ? null
          : (loadingMessage ?? this.loadingMessage),
    );
  }
}
