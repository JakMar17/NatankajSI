/// A fuel station franchise.
class Franchise {
  const Franchise({
    required this.pk,
    required this.name,
    required this.markerUrl,
    required this.markerHoverUrl,
  });

  final int pk;
  final String name;
  final String? markerUrl;
  final String? markerHoverUrl;

  factory Franchise.fromJson(Map<String, dynamic> json) {
    return Franchise(
      pk: json['pk'] as int,
      name: json['name'] as String,
      markerUrl: json['markerUrl'] as String?,
      markerHoverUrl: json['markerHoverUrl'] as String?,
    );
  }
}
