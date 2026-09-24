import 'dart:async';

import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/auth/domain/entities/auth_user.dart';
import 'package:meowville/features/auth/domain/entities/login_credentials.dart';
import 'package:meowville/features/auth/domain/entities/register_account_params.dart';
import 'package:meowville/features/auth/domain/entities/user_role.dart';
import 'package:meowville/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.signInError,
    this.registerError,
    this.requestResetError,
    this.confirmResetError,
    this.initialUser,
  });

  final AppException? signInError;

  final AppException? registerError;

  final AppException? requestResetError;

  final AppException? confirmResetError;

  final AuthUser? initialUser;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  final List<LoginCredentials> signInCalls = <LoginCredentials>[];
  final List<RegisterAccountParams> registerCalls = <RegisterAccountParams>[];
  final List<String> requestResetCalls = <String>[];
  final List<({String email, String token, String newPassword})>
  confirmResetCalls = <({String email, String token, String newPassword})>[];

  static final AuthUser sampleUser = AuthUser(
    id: '00000000-0000-4000-8000-000000000000',
    name: 'Rani Pratama',
    email: 'rani@contoh.com',
    whatsappNumber: '081234567890',
    role: UserRole.petOwner,
    createdAt: DateTime.utc(2026, 9, 9),
  );

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  Future<AuthUser?> currentUser() async => initialUser;

  @override
  Future<AuthUser> signIn(LoginCredentials credentials) async {
    signInCalls.add(credentials);
    final AppException? error = signInError;
    if (error != null) {
      throw error;
    }
    _controller.add(sampleUser);
    return sampleUser;
  }

  @override
  Future<AuthUser> registerAccount(RegisterAccountParams params) async {
    registerCalls.add(params);
    final AppException? error = registerError;
    if (error != null) {
      throw error;
    }
    return sampleUser;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    requestResetCalls.add(email);
    final AppException? error = requestResetError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<AuthUser> confirmPasswordReset({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    confirmResetCalls.add((
      email: email,
      token: token,
      newPassword: newPassword,
    ));
    final AppException? error = confirmResetError;
    if (error != null) {
      throw error;
    }
    // verifyOTP membuat sesi lebih dulu, jadi status masuk terpancar sebelum
    // updateUser selesai. Layar reset harus bertahan sampai keduanya selesai.
    _controller.add(sampleUser);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return sampleUser;
  }

  @override
  Future<void> signOut() async {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
