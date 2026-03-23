import 'package:app/data/models/mol_data.model.dart';
import 'package:app/data/models/price_entry.model.dart';
import 'package:dart_util_box/dart_util_box.dart';

/// A station plus a price list from the snapshot endpoint.
class StationPrices {
  const StationPrices({
    required this.pk,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.zipCode,
    required this.openHours,
    required this.franchiseId,
    required this.franchiseName,
    required this.prices,
    required this.mol,
  });

  final int pk;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;
  final String? zipCode;
  final String? openHours;
  final int? franchiseId;
  final String? franchiseName;
  final List<PriceEntry> prices;
  final MolData? mol;

  factory StationPrices.fromJson(Map<String, dynamic> json) {
    final pricesJson = json['prices'] as List<dynamic>;

    return StationPrices(
      pk: json['pk'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      zipCode: json['zipCode'] as String?,
      openHours: json['openHours'] as String?,
      franchiseId: json['franchiseId'] as int?,
      franchiseName: json['franchiseName'] as String?,
      prices: pricesJson
          .mapToList(
            (entry) => PriceEntry.fromJson(entry as Map<String, dynamic>),
          ),
      mol: json['mol'] == null
          ? null
          : MolData.fromJson(json['mol'] as Map<String, dynamic>),
    );
  }
}
