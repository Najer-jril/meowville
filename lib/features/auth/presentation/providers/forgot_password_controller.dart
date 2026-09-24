import 'package:flutter/widgets.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import 'form_submission_status.dart';

class ForgotPasswordController extends ChangeNotifier {
  ForgotPasswordController(this._requestReset);

  final RequestPasswordResetUseCase _requestReset;

  final TextEditingController emailController = TextEditingController();

  FormSubmissionStatus _status = FormSubmissionStatus.idle;
  String? _errorMessage;
  String? _emailError;

  FormSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get emailError => _emailError;

  String get submittedEmail => emailController.text.trim().toLowerCase();

  void clearErrors() {
    if (_errorMessage == null &&
        _emailError == null &&
        _status != FormSubmissionStatus.failure) {
      return;
    }
    _errorMessage = null;
    _emailError = null;
    _status = FormSubmissionStatus.idle;
    notifyListeners();
  }

  Future<bool> submit() async {
    if (_status.isSubmitting) {
      return false;
    }

    _status = FormSubmissionStatus.submitting;
    _errorMessage = null;
    _emailError = null;
    notifyListeners();

    try {
      await _requestReset(email: emailController.text);
      _status = FormSubmissionStatus.success;
      notifyListeners();
      return true;
    } on ValidationException catch (error) {
      _status = FormSubmissionStatus.failure;
      _emailError = error.message;
      notifyListeners();
      return false;
    } on AppException catch (error) {
      _status = FormSubmissionStatus.failure;
      _errorMessage = error.message;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }
}
