extension StringNullableExtension on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}