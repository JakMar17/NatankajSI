import 'package:app/data/models/station_prices.model.dart';
import 'package:dart_util_box/dart_util_box.dart';

/// Response payload for latest prices across all stations.
class PricesResponse {
  const PricesResponse({
    required this.fetchedAt,
    required this.stations,
  });

  final DateTime fetchedAt;
  final List<StationPrices> stations;

  factory PricesResponse.fromJson(Map<String, dynamic> json) {
    final stationsJson = json['stations'] as List<dynamic>;

    return PricesResponse(
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      stations: stationsJson
          .mapToList(
            (station) => StationPrices.fromJson(station as Map<String, dynamic>),
          ),
    );
  }
}
