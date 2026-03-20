/// A fuel price entry without fetch timestamp.
class PriceEntry {
  const PriceEntry({
    required this.fuelCode,
    required this.fuelName,
    required this.price,
  });

  final String fuelCode;
  final String fuelName;
  final double price;

  factory PriceEntry.fromJson(Map<String, dynamic> json) {
    return PriceEntry(
      fuelCode: json['fuelCode'] as String,
      fuelName: json['fuelName'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}
