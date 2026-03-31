import 'dart:developer';

import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/fuel_type.model.dart';

/// API calls for fuel metadata.
class FuelsApiService {
  const FuelsApiService(this._dio);

  final Dio _dio;

  Future<List<FuelType>> listFuels() async {
    final startTime = DateTime.now();
    final response = await _dio.get<List<dynamic>>('/api/v1/fuels');
    final payload = response.data ?? const <dynamic>[];

    log("Fetched fuel list in ${DateTime.now().difference(startTime).inMilliseconds}ms");
    return payload
        .mapToList((item) => FuelType.fromJson(item as Map<String, dynamic>));
  }
}
