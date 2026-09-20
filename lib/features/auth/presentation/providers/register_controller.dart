import 'package:flutter/widgets.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/usecases/register_account_usecase.dart';
import 'form_submission_status.dart';

abstract class RegisterController extends ChangeNotifier {
  RegisterController(this._registerAccount);

  final RegisterAccountUseCase _registerAccount;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  FormSubmissionStatus _status = FormSubmissionStatus.idle;
  String? _errorMessage;
  String? _nameError;
  String? _emailError;
  String? _whatsappError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get termsAccepted => _termsAccepted;
  FormSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get nameError => _nameError;
  String? get emailError => _emailError;
  String? get whatsappError => _whatsappError;
  String? get passwordError => _passwordError;
  String? get confirmPasswordError => _confirmPasswordError;
  String? get termsError => _termsError;

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    if (value) {
      _termsError = null;
    }
    notifyListeners();
  }

  void clearErrors() {
    final bool hasAnyError =
        _errorMessage != null ||
        _nameError != null ||
        _emailError != null ||
        _whatsappError != null ||
        _passwordError != null ||
        _confirmPasswordError != null ||
        _termsError != null;

    if (!hasAnyError && _status != FormSubmissionStatus.failure) {
      return;
    }

    _errorMessage = null;
    _nameError = null;
    _emailError = null;
    _whatsappError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _termsError = null;
    _status = FormSubmissionStatus.idle;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (_status.isSubmitting) {
      return false;
    }

    _status = FormSubmissionStatus.submitting;
    _errorMessage = null;
    _nameError = null;
    _emailError = null;
    _whatsappError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _termsError = null;
    notifyListeners();

    try {
      await _registerAccount(
        name: nameController.text,
        email: emailController.text,
        whatsappNumber: whatsappController.text,
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
        termsAccepted: _termsAccepted,
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
    } else if (message.contains('Nama lengkap')) {
      _nameError = message;
    } else if (message.contains('email') || message.contains('Alamat email')) {
      _emailError = message;
    } else if (message.contains('WhatsApp')) {
      _whatsappError = message;
    } else if (message.contains('Kata sandi')) {
      _passwordError = message;
    } else if (message.contains('persetujuan')) {
      _termsError = message;
    } else {
      _errorMessage = message;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
