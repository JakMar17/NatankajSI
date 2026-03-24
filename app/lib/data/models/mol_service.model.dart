/// A service offered at a MOL station.
class MolService {
  const MolService({
    required this.code,
    required this.name,
    required this.value,
  });

  final String code;
  final String name;
  final String? value;

  factory MolService.fromJson(Map<String, dynamic> json) => MolService(
    code: json['code'] as String,
    name: json['name'] as String,
    value: json['value'] as String?,
  );
}
