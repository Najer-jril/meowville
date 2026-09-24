import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/data_error_mapper.dart';
import '../models/auth_user_dto.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const String _usersTable = 'users';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<String> findEmailByWhatsAppNumber(String whatsappNumber) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(_usersTable)
          .select('email')
          .eq('whatsapp_number', whatsappNumber)
          .maybeSingle();

      if (row == null) {
        throw const NotFoundException(
          'Nomor WhatsApp itu belum terdaftar sebagai akun pemilik.',
        );
      }
      return row['email'] as String;
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<AuthUserDto> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final User? user = response.user;
      if (user == null) {
        throw const UnauthorizedException('Email atau kata sandi tidak cocok.');
      }
      return await fetchProfile(user.id);
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<AuthUserDto> registerAccount({
    required String name,
    required String email,
    required String whatsappNumber,
    required String password,
    required String role,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{
          'name': name,
          'whatsapp_number': whatsappNumber,
          'role': role,
        },
      );

      final User? user = response.user;
      if (user == null) {
        throw const UnexpectedException(
          'Pendaftaran belum selesai. Coba ulangi beberapa saat lagi.',
        );
      }

      if (response.session != null) {
        return await fetchProfile(user.id);
      }
      return AuthUserDto(
        id: user.id,
        name: name,
        email: email,
        whatsappNumber: whatsappNumber,
        role: role,
        createdAt: DateTime.now(),
      );
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<AuthUserDto> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    try {
      final AuthResponse verified = await _client.auth.verifyOTP(
        type: OtpType.recovery,
        email: email,
        token: token,
      );
      final User? user = verified.user;
      if (user == null) {
        throw const UnexpectedException(
          'Kode belum bisa diperiksa. Coba ulangi beberapa saat lagi.',
        );
      }

      try {
        await _client.auth.updateUser(UserAttributes(password: newPassword));
      } on AuthException catch (error) {
        await _discardRecoverySession();
        throw _mapAuthError(error, afterCodeUsed: true);
      }
      return await fetchProfile(user.id);
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<void> _discardRecoverySession() async {
    try {
      await _client.auth.signOut();
    } on Object {
      //noname
    }
  }

  Future<AuthUserDto> fetchProfile(String userId) async {
    try {
      final Map<String, dynamic>? row = await _client
          .from(_usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        throw const NotFoundException(
          'Profil pemilik belum ada untuk akun ini.',
        );
      }
      return AuthUserDto.fromJson(row);
    } on PostgrestException catch (error) {
      throw _mapPostgrestError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw _mapAuthError(error);
    } on SocketException catch (error) {
      throw NetworkException(_networkMessage, cause: error);
    }
  }

  static const String _networkMessage = networkErrorMessage;

  AppException _mapAuthError(
    AuthException error, {
    bool afterCodeUsed = false,
  }) {
    final String code = error.statusCode ?? '';
    final String reason = error.code ?? '';
    final String message = error.message.toLowerCase();

    if (error is AuthRetryableFetchException) {
      return NetworkException(_networkMessage, cause: error);
    }
    if (reason == 'otp_expired' ||
        message.contains('token has expired') ||
        message.contains('token is invalid')) {
      return UnauthorizedException(
        'Kode itu tidak cocok atau sudah lewat satu jam. Minta kode baru.',
        cause: error,
      );
    }
    if (code == '429' ||
        reason == 'over_email_send_rate_limit' ||
        reason == 'over_request_rate_limit' ||
        message.contains('rate limit') ||
        message.contains('you can only request this after')) {
      return UnauthorizedException(
        'Terlalu banyak percobaan. Tunggu beberapa menit.',
        cause: error,
      );
    }
    if (error is AuthWeakPasswordException || reason == 'weak_password') {
      return ValidationException(
        afterCodeUsed
            ? 'Kata sandi terlalu lemah. Minta kode baru, lalu pilih yang lebih panjang.'
            : 'Kata sandi terlalu lemah.',
        cause: error,
      );
    }
    if (reason == 'same_password') {
      return ValidationException(
        afterCodeUsed
            ? 'Kata sandi baru harus berbeda dari yang lama. Minta kode baru untuk mencoba lagi.'
            : 'Kata sandi baru harus berbeda dari yang lama.',
        cause: error,
      );
    }

    if (message.contains('invalid login credentials')) {
      return UnauthorizedException(
        'Email atau kata sandi tidak cocok.',
        cause: error,
      );
    }
    if (message.contains('email not confirmed')) {
      return UnauthorizedException(
        'Email itu belum dikonfirmasi. Buka tautan verifikasi di kotak masuk Anda.',
        cause: error,
      );
    }
    if (message.contains('already registered') ||
        message.contains('user already') ||
        code == '422') {
      return ConflictException(
        'Email itu sudah dipakai akun lain.',
        cause: error,
      );
    }
    if (code == '401' || code == '403') {
      return UnauthorizedException(
        'Sesi tidak berlaku. Masuk ulang untuk melanjutkan.',
        cause: error,
      );
    }
    return UnexpectedException(
      'Autentikasi gagal. Coba ulangi beberapa saat lagi.',
      cause: error,
    );
  }

  AppException _mapPostgrestError(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return ConflictException(
          'Email atau nomor WhatsApp itu sudah dipakai akun lain.',
          cause: error,
        );
      case '23502':
        return ValidationException(
          'Ada data wajib yang belum terisi.',
          cause: error,
        );
      case '42501':
        return UnauthorizedException(
          'Akun ini tidak berhak mengakses data tersebut.',
          cause: error,
        );
      default:
        return UnexpectedException(
          'Data pemilik gagal diproses. Coba ulangi beberapa saat lagi.',
          cause: error,
        );
    }
  }
}
