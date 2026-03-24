/// Government-regulated fuel price valid from a specific date.
class RegulatedPrice {
  const RegulatedPrice({
    required this.pk,
    required this.validFrom,
    required this.petrolPrice,
    required this.dieselPrice,
  });

  final int pk;
  final DateTime validFrom;
  final double? petrolPrice;
  final double? dieselPrice;

  factory RegulatedPrice.fromJson(Map<String, dynamic> json) =>
      RegulatedPrice(
        pk: json['pk'] as int,
        validFrom: DateTime.parse(json['validFrom'] as String),
        petrolPrice: (json['petrolPrice'] as num?)?.toDouble(),
        dieselPrice: (json['dieselPrice'] as num?)?.toDouble(),
      );
}
