/// A latest fuel price entry for one station.
class LatestPriceEntry {
  const LatestPriceEntry({
    required this.fuelCode,
    required this.fuelName,
    required this.price,
    required this.fetchedAt,
  });

  final String fuelCode;
  final String fuelName;
  final double price;
  final DateTime fetchedAt;

  factory LatestPriceEntry.fromJson(Map<String, dynamic> json) {
    return LatestPriceEntry(
      fuelCode: json['fuelCode'] as String,
      fuelName: json['fuelName'] as String,
      price: (json['price'] as num).toDouble(),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }
}
