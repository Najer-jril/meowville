import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_out_usecase.dart';

enum AuthSessionStatus { checking, signedIn, signedOut }

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._repository, this._signOut) {
    _restore();
    _subscription = _repository.authStateChanges.listen(_handleAuthUser);
  }

  final AuthRepository _repository;
  final SignOutUseCase _signOut;

  StreamSubscription<AuthUser?>? _subscription;

  AuthSessionStatus _status = AuthSessionStatus.checking;
  AuthUser? _user;

  AuthSessionStatus get status => _status;
  AuthUser? get user => _user;
  bool get isAuthenticated => _status == AuthSessionStatus.signedIn;
  bool get isChecking => _status == AuthSessionStatus.checking;

  Future<void> _restore() async {
    final AuthUser? restored = await _repository.currentUser();
    _handleAuthUser(restored);
  }

  void _handleAuthUser(AuthUser? user) {
    _user = user;
    _status = user == null
        ? AuthSessionStatus.signedOut
        : AuthSessionStatus.signedIn;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _signOut();
    _handleAuthUser(null);
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
