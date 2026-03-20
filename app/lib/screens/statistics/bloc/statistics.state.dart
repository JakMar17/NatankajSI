import 'package:latlong2/latlong.dart';

/// Represents loading and error state for station statistics.
enum StatisticsStatus { loading, ready, error }

/// Immutable state for the statistics tab.
class StatisticsState {
  const StatisticsState({
    required this.status,
    required this.errorMessage,
    required this.userLocation,
    required this.fuelStats,
    required this.generatedAt,
  });

  factory StatisticsState.initial() {
    return const StatisticsState(
      status: StatisticsStatus.loading,
      errorMessage: null,
      userLocation: null,
      fuelStats: <FuelStatistics>[],
      generatedAt: null,
    );
  }

  final StatisticsStatus status;
  final String? errorMessage;
  final LatLng? userLocation;
  final List<FuelStatistics> fuelStats;
  final DateTime? generatedAt;

  StatisticsState copyWith({
    StatisticsStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
    LatLng? userLocation,
    bool clearUserLocation = false,
    List<FuelStatistics>? fuelStats,
    DateTime? generatedAt,
  }) {
    return StatisticsState(
      status: status ?? this.status,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      userLocation: clearUserLocation
          ? null
          : (userLocation ?? this.userLocation),
      fuelStats: fuelStats ?? this.fuelStats,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// Aggregated statistics for one fuel type.
class FuelStatistics {
  const FuelStatistics({
    required this.fuelCode,
    required this.fuelLabel,
    required this.sampleCount,
    required this.stationCount,
    required this.averagePrice,
    required this.primaryPrice,
    required this.primaryPriceLabel,
    required this.averageDeviation,
    required this.averageDeviationPercent,
    required this.closestToUser,
    required this.minPricePoint,
    required this.maxPricePoint,
    required this.priceDistribution,
  });

  final String fuelCode;
  final String fuelLabel;
  final int sampleCount;
  final int stationCount;

  /// True mean across all samples, used for per-station delta comparisons.
  final double averagePrice;
  final double primaryPrice;
  final String primaryPriceLabel;
  final double averageDeviation;
  final double averageDeviationPercent;
  final StationPricePoint closestToUser;
  final StationPricePoint minPricePoint;
  final StationPricePoint maxPricePoint;

  /// Price buckets sorted from lowest to highest price.
  final List<PriceDistributionBucket> priceDistribution;

  double get priceSpread => maxPricePoint.price - minPricePoint.price;
}

/// A single price bucket: how many stations charge exactly [price].
class PriceDistributionBucket {
  const PriceDistributionBucket({
    required this.price,
    required this.count,
  });

  final double price;
  final int count;
}

/// Price and location details for one station/fuel data point.
class StationPricePoint {
  const StationPricePoint({
    required this.stationPk,
    required this.stationName,
    required this.stationAddress,
    required this.price,
    required this.distanceKm,
  });

  final int stationPk;
  final String stationName;
  final String? stationAddress;
  final double price;
  final double? distanceKm;
}
