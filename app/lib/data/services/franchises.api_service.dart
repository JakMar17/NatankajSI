import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/franchise.model.dart';

/// API calls for franchise metadata.
class FranchisesApiService {
  const FranchisesApiService(this._dio);

  final Dio _dio;

  Future<List<Franchise>> listFranchises() async {
    final response = await _dio.get<List<dynamic>>('/api/v1/franchises');
    final payload = response.data ?? const <dynamic>[];

    return payload
        .mapToList((item) => Franchise.fromJson(item as Map<String, dynamic>));
  }
}
