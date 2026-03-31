import 'dart:developer';

import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import 'package:app/data/models/regulated_price.model.dart';

/// API calls for government-regulated fuel prices.
class RegulatedPricesApiService {
  const RegulatedPricesApiService(this._dio);

  final Dio _dio;

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  /// Fetches the most recently published regulated price.
  Future<RegulatedPrice> getLatest() async {
    final startTime = DateTime.now();
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/regulated-prices/latest',
    );
    final payload = response.data;
    log("Fetched latest regulated price in ${DateTime.now().difference(startTime).inMilliseconds}ms");
    if (payload == null) {
      throw const FormatException('Missing regulated price payload.');
    }
    return RegulatedPrice.fromJson(payload);
  }

  /// Fetches all regulated prices, optionally filtered by date range.
  Future<List<RegulatedPrice>> list({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/regulated-prices',
      queryParameters: {
        if (fromDate != null)
          'from_date': _dateFormat.format(fromDate),
        if (toDate != null) 'to_date': _dateFormat.format(toDate),
      },
    );
    final payload = response.data ?? const <dynamic>[];
    return payload.mapToList(
      (item) =>
          RegulatedPrice.fromJson(item as Map<String, dynamic>),
    );
  }
}
