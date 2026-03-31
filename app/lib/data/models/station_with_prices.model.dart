import 'package:app/data/models/latest_price_entry.model.dart';
import 'package:app/data/models/mol_data.model.dart';
import 'package:app/data/models/station.model.dart';
import 'package:dart_util_box/dart_util_box.dart';

/// A station with its latest known prices.
class StationWithPrices {
  const StationWithPrices({
    required this.pk,
    required this.franchiseId,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.zipCode,
    required this.openHours,
    required this.franchiseName,
    required this.latestPrices,
    required this.mol,
  });

  final int pk;
  final int? franchiseId;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String? zipCode;
  final String? openHours;
  final String? franchiseName;
  final List<LatestPriceEntry> latestPrices;
  final MolData? mol;

  /// Creates a [StationWithPrices] from a lightweight [Station] and its prices.
  ///
  /// [mol] is left null because station listing does not include MOL data;
  /// fetch the full detail via [GET /api/v1/stations/{id}] to obtain it.
  factory StationWithPrices.fromStation(
    Station station,
    List<LatestPriceEntry> prices,
  ) => StationWithPrices(
    pk: station.pk,
    franchiseId: station.franchiseId,
    name: station.name,
    address: station.address,
    lat: station.lat,
    lng: station.lng,
    zipCode: station.zipCode,
    openHours: station.openHours,
    franchiseName: station.franchiseName,
    latestPrices: prices,
    mol: null,
  );

  factory StationWithPrices.fromJson(Map<String, dynamic> json) {
    final latestPricesJson = json['latestPrices'] as List<dynamic>;

    return StationWithPrices(
      pk: json['pk'] as int,
      franchiseId: json['franchiseId'] as int?,
      name: json['name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      zipCode: json['zipCode'] as String?,
      openHours: json['openHours'] as String?,
      franchiseName: json['franchiseName'] as String?,
      latestPrices: latestPricesJson
          .mapToList(
            (entry) => LatestPriceEntry.fromJson(
              entry as Map<String, dynamic>,
            ),
          ),
      mol: json['mol'] == null
          ? null
          : MolData.fromJson(json['mol'] as Map<String, dynamic>),
    );
  }
}

/// Merges lightweight [Station] objects with the latest-prices map.
///
/// Stations with no entry in [pricesById] get an empty price list.
List<StationWithPrices> mergeStationsWithPrices(
  List<Station> stations,
  Map<int, List<LatestPriceEntry>> pricesById,
) => stations.mapToList(
  (s) => StationWithPrices.fromStation(s, pricesById[s.pk] ?? const []),
);
