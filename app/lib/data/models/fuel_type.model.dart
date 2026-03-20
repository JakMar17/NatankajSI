/// A fuel type exposed by the API.
class FuelType {
  const FuelType({
    required this.pk,
    required this.code,
    required this.name,
    required this.longName,
  });

  final int pk;
  final String code;
  final String name;
  final String? longName;

  factory FuelType.fromJson(Map<String, dynamic> json) {
    return FuelType(
      pk: json['pk'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      longName: json['longName'] as String?,
    );
  }
}
