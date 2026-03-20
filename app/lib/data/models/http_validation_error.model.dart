import 'package:app/data/models/validation_error.model.dart';
import 'package:dart_util_box/dart_util_box.dart';

/// Validation error response returned by FastAPI.
class HttpValidationError {
  const HttpValidationError({
    required this.detail,
  });

  final List<ValidationError>? detail;

  factory HttpValidationError.fromJson(Map<String, dynamic> json) {
    final detailJson = json['detail'] as List<dynamic>?;

    return HttpValidationError(
      detail: detailJson
          ?.mapToList(
            (error) => ValidationError.fromJson(error as Map<String, dynamic>),
          ),
    );
  }
}
