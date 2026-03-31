import 'dart:developer';

import 'package:dart_util_box/dart_util_box.dart';
import 'package:dio/dio.dart';

import 'package:app/data/models/franchise.model.dart';

/// API calls for franchise metadata.
class FranchisesApiService {
  const FranchisesApiService(this._dio);

  final Dio _dio;

  Future<List<Franchise>> listFranchises() async {
    final startTime = DateTime.now();
    final response = await _dio.get<List<dynamic>>('/api/v1/franchises');
    final payload = response.data ?? const <dynamic>[];

    log("Fetched franchise list in ${DateTime.now().difference(startTime).inMilliseconds}ms");
    return payload
        .mapToList((item) => Franchise.fromJson(item as Map<String, dynamic>));
  }
}
