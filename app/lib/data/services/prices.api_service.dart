import 'package:dio/dio.dart';

import 'package:app/data/models/prices_response.model.dart';

/// API calls for latest global price snapshots.
class PricesApiService {
  const PricesApiService(this._dio);

  final Dio _dio;

  Future<PricesResponse> getPrices({DateTime? timestamp}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/prices',
      queryParameters: {
        if (timestamp != null) 'timestamp': timestamp.toIso8601String(),
      },
    );

    final payload = response.data;

    if (payload == null) {
      throw const FormatException('Missing prices payload.');
    }

    return PricesResponse.fromJson(payload);
  }
}
