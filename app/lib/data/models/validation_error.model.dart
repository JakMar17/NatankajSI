/// A single API validation error item.
class ValidationError {
  const ValidationError({
    required this.loc,
    required this.msg,
    required this.type,
    required this.input,
    required this.ctx,
  });

  final List<Object> loc;
  final String msg;
  final String type;
  final Object? input;
  final Map<String, dynamic>? ctx;

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    final locJson = json['loc'] as List<dynamic>;

    return ValidationError(
      loc: locJson.cast<Object>(),
      msg: json['msg'] as String,
      type: json['type'] as String,
      input: json['input'],
      ctx: json['ctx'] as Map<String, dynamic>?,
    );
  }
}
