import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/fetch_log.model.dart';

/// API calls for parser fetch log entries.
class FetchLogApiService {
  const FetchLogApiService(this._dio);

  final Dio _dio;

  Future<List<FetchLog>> listFetchLogs({int limit = 20}) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/fetch-log',
      queryParameters: {
        'limit': limit,
      },
    );

    final payload = response.data ?? const <dynamic>[];

    return payload
        .mapToList((item) => FetchLog.fromJson(item as Map<String, dynamic>));
  }
}
