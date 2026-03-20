/// A historical price snapshot row for one station and fuel type.
class PriceSnapshot {
  const PriceSnapshot({
    required this.id,
    required this.stationId,
    required this.fuelTypeId,
    required this.fuelCode,
    required this.price,
    required this.fetchedAt,
  });

  final int id;
  final int stationId;
  final int fuelTypeId;
  final String fuelCode;
  final double price;
  final DateTime fetchedAt;

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) {
    return PriceSnapshot(
      id: json['id'] as int,
      stationId: json['stationId'] as int,
      fuelTypeId: json['fuelTypeId'] as int,
      fuelCode: json['fuelCode'] as String,
      price: (json['price'] as num).toDouble(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
