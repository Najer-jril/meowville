import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_exception.dart';

const String networkErrorMessage =
    'Perangkat tidak dapat menghubungi server. Periksa koneksi, lalu coba lagi.';

AppException mapDataError(Object error, {required String fallback}) {
  if (error is AppException) {
    return error;
  }
  if (error is SocketException || error is AuthRetryableFetchException) {
    return NetworkException(networkErrorMessage, cause: error);
  }
  if (error is PostgrestException) {
    if (error.code == '42501') {
      return UnauthorizedException(
        'Akun ini tidak berhak mengakses data tersebut.',
        cause: error,
      );
    }
    return UnexpectedException(fallback, cause: error);
  }
  return UnexpectedException(fallback, cause: error);
}

AppException mapParallelWaitError(
  ParallelWaitError<Object?, Object?> error, {
  required String fallback,
}) {
  final List<Object?> errors = switch (error.errors) {
    (Object? a, Object? b) => <Object?>[a, b],
    (Object? a, Object? b, Object? c) => <Object?>[a, b, c],
    (Object? a, Object? b, Object? c, Object? d) => <Object?>[a, b, c, d],
    (Object? a, Object? b, Object? c, Object? d, Object? e) => <Object?>[
      a,
      b,
      c,
      d,
      e,
    ],
    (Object? a, Object? b, Object? c, Object? d, Object? e, Object? f) =>
      <Object?>[a, b, c, d, e, f],
    _ => const <Object?>[],
  };
  for (final Object? item in errors) {
    if (item is AsyncError) {
      return mapDataError(item.error, fallback: fallback);
    }
  }
  return UnexpectedException(fallback, cause: error);
}
