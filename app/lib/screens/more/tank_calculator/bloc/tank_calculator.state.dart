import 'package:app/data/models/regulated_price.model.dart';

enum TankCalculatorStatus { loading, ready, error }

/// A station result used for display in the tank calculator.
class StationSummary {
  const StationSummary({
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
}

/// State for the fuel tank cost calculator screen.
class TankCalculatorState {
  const TankCalculatorState({
    required this.status,
    required this.capacityLiters,
    required this.availableFuelCodes,
    this.regulatedPriceHistory = const [],
    this.fuelNames = const {},
    this.fuelCode,
    this.hasLocation = false,
    this.closestStation,
    this.cheapestNearby,
    this.mostExpensiveNearby,
    this.cheapestAll,
    this.mostExpensiveAll,
    this.errorMessage,
  });

  final TankCalculatorStatus status;
  final double capacityLiters;
  final String? fuelCode;
  final List<String> availableFuelCodes;
  final List<RegulatedPrice> regulatedPriceHistory;

  /// Human-readable display name keyed by fuel code.
  final Map<String, String> fuelNames;

  /// Whether user location was available when results were computed.
  final bool hasLocation;

  /// Nearest station to the user (requires location).
  final StationSummary? closestStation;

  /// Cheapest station within 30 km (requires location).
  final StationSummary? cheapestNearby;

  /// Most expensive station within 30 km (requires location).
  final StationSummary? mostExpensiveNearby;

  /// Station with the lowest price within 1 000 km (or globally).
  final StationSummary? cheapestAll;

  /// Station with the highest price within 1 000 km (or globally).
  final StationSummary? mostExpensiveAll;

  final String? errorMessage;

  static TankCalculatorState initial() => const TankCalculatorState(
    status: TankCalculatorStatus.loading,
    capacityLiters: 50,
    availableFuelCodes: [],
  );

  /// Whether regulated historical prices are available for the selected fuel.
  bool get supportsRegulatedHistory => fuelCode == '95' || fuelCode == 'dizel';

  TankCalculatorState withCapacity(double liters) => TankCalculatorState(
    status: status,
    capacityLiters: liters,
    fuelCode: fuelCode,
    availableFuelCodes: availableFuelCodes,
    regulatedPriceHistory: regulatedPriceHistory,
    fuelNames: fuelNames,
    hasLocation: hasLocation,
    closestStation: closestStation,
    cheapestNearby: cheapestNearby,
    mostExpensiveNearby: mostExpensiveNearby,
    cheapestAll: cheapestAll,
    mostExpensiveAll: mostExpensiveAll,
  );
}
