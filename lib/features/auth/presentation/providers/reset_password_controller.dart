import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/recovery_code.dart';
import '../../domain/usecases/confirm_password_reset_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import 'form_submission_status.dart';

class ResetPasswordController extends ChangeNotifier {
  ResetPasswordController(
    this._confirmReset,
    this._requestReset, {
    String? initialEmail,
  }) : hasFixedEmail = initialEmail != null && initialEmail.isNotEmpty {
    if (hasFixedEmail) {
      emailController.text = initialEmail!;
      _notice = _codeSentNotice;
      _startCooldown();
    }
    codeController.addListener(notifyListeners);
  }

  static const Duration resendCooldown = Duration(seconds: 60);
  static const String _codeSentNotice =
      'Kalau email itu terdaftar, kodenya sudah dikirim.';
  static const String _codeResentNotice =
      'Kalau email itu terdaftar, kode baru sudah dikirim.';

  final ConfirmPasswordResetUseCase _confirmReset;
  final RequestPasswordResetUseCase _requestReset;

  final bool hasFixedEmail;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Timer? _cooldownTimer;
  int _resendSecondsLeft = 0;
  bool _isResending = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  FormSubmissionStatus _status = FormSubmissionStatus.idle;
  String? _notice;
  String? _errorMessage;
  String? _emailError;
  String? _codeError;
  String? _passwordError;
  String? _confirmPasswordError;

  int get resendSecondsLeft => _resendSecondsLeft;
  bool get isResending => _isResending;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  FormSubmissionStatus get status => _status;
  String? get notice => _notice;
  String? get errorMessage => _errorMessage;
  String? get emailError => _emailError;
  String? get codeError => _codeError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;

  bool get canResend =>
      _resendSecondsLeft == 0 && !_isResending && !_status.isSubmitting;

  bool get canSubmit =>
      codeController.text.trim().length == RecoveryCode.length &&
      !_status.isSubmitting;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void clearErrors() {
    final bool hasAnyError =
        _errorMessage != null ||
        _emailError != null ||
        _codeError != null ||
        _passwordError != null ||
        _confirmPasswordError != null;

    if (!hasAnyError && _status != FormSubmissionStatus.failure) {
      return;
    }
    _clearFieldErrors();
    _status = FormSubmissionStatus.idle;
    notifyListeners();
  }

  Future<void> resend() async {
    if (!canResend) {
      return;
    }

    _isResending = true;
    _clearFieldErrors();
    _notice = null;
    notifyListeners();

    try {
      await _requestReset(email: emailController.text);
      _notice = _codeResentNotice;
      _startCooldown();
    } on ValidationException catch (error) {
      _emailError = error.message;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isResending = false;
      notifyListeners();
    }
  }

  Future<bool> submit() async {
    if (_status.isSubmitting) {
      return false;
    }

    _status = FormSubmissionStatus.submitting;
    _clearFieldErrors();
    _notice = null;
    notifyListeners();

    try {
      await _confirmReset(
        email: emailController.text,
        code: codeController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
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

    if (message.contains('Konfirmasi kata sandi')) {
      _confirmPasswordError = message;
    } else if (message.contains('Kode')) {
      _codeError = message;
    } else if (message.contains('email')) {
      _emailError = message;
    } else if (message.contains('Kata sandi')) {
      _passwordError = message;
    } else {
      _errorMessage = message;
    }
    notifyListeners();
  }

  void _clearFieldErrors() {
    _errorMessage = null;
    _emailError = null;
    _codeError = null;
    _passwordError = null;
    _confirmPasswordError = null;
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _resendSecondsLeft = resendCooldown.inSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      _resendSecondsLeft -= 1;
      if (_resendSecondsLeft <= 0) {
        _resendSecondsLeft = 0;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    codeController.removeListener(notifyListeners);
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
