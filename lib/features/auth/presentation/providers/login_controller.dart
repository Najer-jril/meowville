import 'package:flutter/widgets.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import 'form_submission_status.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._signIn);

  final SignInUseCase _signIn;

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  FormSubmissionStatus _status = FormSubmissionStatus.idle;
  String? _errorMessage;
  String? _identifierError;
  String? _passwordError;

  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  FormSubmissionStatus get status => _status;

  String? get errorMessage => _errorMessage;

  String? get identifierError => _identifierError;
  String? get passwordError => _passwordError;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearErrors() {
    if (_errorMessage == null &&
        _identifierError == null &&
        _passwordError == null &&
        _status != FormSubmissionStatus.failure) {
      return;
    }
    _errorMessage = null;
    _identifierError = null;
    _passwordError = null;
    _status = FormSubmissionStatus.idle;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (_status.isSubmitting) {
      return false;
    }

    _status = FormSubmissionStatus.submitting;
    _errorMessage = null;
    _identifierError = null;
    _passwordError = null;
    notifyListeners();

    try {
      await _signIn(
        identifier: identifierController.text,
        password: passwordController.text,
        rememberMe: _rememberMe,
      );
      _status = FormSubmissionStatus.success;
      notifyListeners();
      return true;
    } on ValidationException catch (error) {
      _applyValidationError(error);
      return false;
    } on AppException catch (error) {
      _status = FormSubmissionStatus.failure;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  void _applyValidationError(ValidationException error) {
    _status = FormSubmissionStatus.failure;
    final String message = error.message;

    if (message.contains('Kata sandi')) {
      _passwordError = message;
    } else {
      _identifierError = message;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
