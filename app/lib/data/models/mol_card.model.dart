/// A payment or loyalty card accepted at a MOL station.
class MolCard {
  const MolCard({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory MolCard.fromJson(Map<String, dynamic> json) => MolCard(
    code: json['code'] as String,
    name: json['name'] as String,
  );
}
