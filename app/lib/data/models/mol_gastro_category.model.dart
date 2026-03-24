/// A gastro/food category available at a MOL station.
class MolGastroCategory {
  const MolGastroCategory({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory MolGastroCategory.fromJson(Map<String, dynamic> json) =>
      MolGastroCategory(
        code: json['code'] as String,
        name: json['name'] as String,
      );
}
