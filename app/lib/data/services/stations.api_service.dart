import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/models.dart';

/// API calls for station resources.
class StationsApiService {
  const StationsApiService(this._dio);

  final Dio _dio;

  Future<List<StationWithPrices>> listStations() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/stations');
    final payload = response.data ?? const <dynamic>[];

    return payload
        .mapToList((item) => StationWithPrices.fromJson(item as Map<String, dynamic>));
  }

  Future<StationWithPrices> getStation({required int pk}) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/v1/stations/$pk');
    final payload = response.data;

    if (payload == null) {
      throw const FormatException('Missing station payload.');
    }

    return StationWithPrices.fromJson(payload);
  }

  Future<List<PriceSnapshot>> getStationPriceHistory({
    required int pk,
    DateTime? from,
    DateTime? to,
    String? fuel,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/stations/$pk/prices',
      queryParameters: {
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
        if (fuel != null && fuel.isNotEmpty) 'fuel': fuel,
      },
    );

    final payload = response.data ?? const <dynamic>[];

    return payload
        .mapToList((item) => PriceSnapshot.fromJson(item as Map<String, dynamic>));
  }
}
