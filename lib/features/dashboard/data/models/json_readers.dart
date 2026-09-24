typedef PublicUrlResolver = String Function(String bucket, String path);

Map<String, dynamic>? asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

double? asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String? asNonEmptyString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return null;
}

String? photoUrlFor(
  PublicUrlResolver resolve,
  String bucket,
  Object? storedPath,
) {
  final String? path = asNonEmptyString(storedPath);
  return path == null ? null : resolve(bucket, path);
}
