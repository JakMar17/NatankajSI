import 'dart:developer';

import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/models.dart';

/// API calls for station resources.
class StationsApiService {
  const StationsApiService(this._dio);

  final Dio _dio;

  /// Fetches the lightweight station list for map and listing views.
  ///
  /// Returns stations without prices or MOL data. Use [listLatestPrices]
  /// for price data and [getStation] for full per-station details.
  Future<List<Station>> listStations() async {
    final startTime = DateTime.now();
    final response = await _dio.get<List<dynamic>>('/api/v1/stations');
    final payload = response.data ?? const <dynamic>[];

    log('Fetched station list in '
        '${DateTime.now().difference(startTime).inMilliseconds}ms');
    return payload.mapToList(
      (item) => Station.fromJson(item as Map<String, dynamic>),
    );
  }

  /// Fetches the latest fuel prices for all stations, keyed by station ID.
  ///
  /// Started at app launch as a non-blocking background fetch. Feature screens
  /// await the future stored in [AppBootRepository.latestPricesFuture].
  Future<Map<int, List<LatestPriceEntry>>> listLatestPrices() async {
    final startTime = DateTime.now();
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/stations/latest-prices',
    );
    final payload = response.data ?? const <dynamic>[];

    log('Fetched latest prices in '
        '${DateTime.now().difference(startTime).inMilliseconds}ms '
        '(${payload.length} items)');
    if (payload.isNotEmpty) {
      log('latest-prices sample item keys: '
          '${(payload.first as Map<String, dynamic>).keys.toList()}');
    }

    final result = <int, List<LatestPriceEntry>>{};
    for (final item in payload) {
      final map = item as Map<String, dynamic>;
      // The API uses `pk` naming convention; try common variants defensively.
      final stationId = (map['stationId'] ?? map['stationPk'] ?? map['pk'] ?? map['id']) as int?;
      if (stationId == null) {
        log('latest-prices: skipping item with no station id, keys=${map.keys.toList()}');
        continue;
      }
      final pricesJson = map['latestPrices'] as List<dynamic>? ?? const [];
      result[stationId] = pricesJson.mapToList(
        (entry) => LatestPriceEntry.fromJson(entry as Map<String, dynamic>),
      );
    }
    return result;
  }

  /// Fetches full station detail including latest prices and MOL data.
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
