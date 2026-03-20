/// A fetch run entry for the parser backend.
class FetchLog {
  const FetchLog({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.stationsFetched,
    required this.status,
  });

  final int id;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? stationsFetched;
  final String status;

  factory FetchLog.fromJson(Map<String, dynamic> json) {
    return FetchLog(
      id: json['id'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      stationsFetched: json['stationsFetched'] as int?,
      status: json['status'] as String,
    );
  }
}
