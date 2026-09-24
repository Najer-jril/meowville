import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';

class RoomMutationController extends ChangeNotifier {
  String? _busyKey;
  String? _errorMessage;
  bool _disposed = false;

  String? get busyKey => _busyKey;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _busyKey != null;

  Future<bool> run(String key, Future<void> Function() action) async {
    if (isBusy) {
      return false;
    }
    _busyKey = key;
    _errorMessage = null;
    _notify();

    bool saved = false;
    try {
      await action();
      saved = true;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } on Object catch (error) {
      debugPrint('Perubahan kamar "$key" gagal: $error');
      _errorMessage = 'Perubahan belum tersimpan. Coba ulangi sebentar lagi.';
    }
    _busyKey = null;
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
