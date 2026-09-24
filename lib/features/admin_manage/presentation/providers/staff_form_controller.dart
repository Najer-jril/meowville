import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/staff_draft.dart';
import '../../domain/usecases/staff_usecases.dart';

class StaffFormController extends ChangeNotifier {
  StaffFormController(this._create);

  final CreateStaffAccountUseCase _create;

  bool _isSubmitting = false;
  String? _errorMessage;
  bool _disposed = false;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<bool> submit(StaffDraft draft) async {
    if (_isSubmitting) {
      return false;
    }
    _isSubmitting = true;
    _errorMessage = null;
    _notify();

    bool saved = false;
    try {
      await _create(draft);
      saved = true;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } on Object catch (error) {
      debugPrint('Pembuatan akun staf ${draft.email} gagal: $error');
      _errorMessage = 'Akun staf belum dibuat. Coba ulangi sebentar lagi.';
    }
    _isSubmitting = false;
    _notify();
    return saved;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
