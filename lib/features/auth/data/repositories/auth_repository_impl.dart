import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/login_credentials.dart';
import '../../domain/entities/register_account_params.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_user_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthRemoteDataSource _dataSource;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _dataSource.authStateChanges.asyncMap((AuthState state) async {
      final String? userId = state.session?.user.id;
      if (userId == null) {
        return null;
      }
      try {
        final AuthUserDto dto = await _dataSource.fetchProfile(userId);
        return dto.toEntity();
      } on AppException {
        return null;
      }
    });
  }

  @override
  Future<AuthUser?> currentUser() async {
    final String? userId = _dataSource.currentUserId;
    if (userId == null) {
      return null;
    }
    try {
      final AuthUserDto dto = await _dataSource.fetchProfile(userId);
      return dto.toEntity();
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<AuthUser> signIn(LoginCredentials credentials) async {
    final String email = credentials.usesEmail
        ? credentials.email!
        : await _dataSource.findEmailByWhatsAppNumber(
            credentials.whatsappNumber!,
          );

    final AuthUserDto dto = await _dataSource.signInWithEmail(
      email: email,
      password: credentials.password,
    );
    return dto.toEntity();
  }

  @override
  Future<AuthUser> registerAccount(RegisterAccountParams params) async {
    final AuthUserDto dto = await _dataSource.registerAccount(
      name: params.name,
      email: params.email,
      whatsappNumber: params.whatsappNumber,
      password: params.password,
      role: params.role.wireValue,
    );
    return dto.toEntity();
  }

  @override
  Future<void> signOut() => _dataSource.signOut();
}
