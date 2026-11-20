import 'package:flutter/foundation.dart';

/// State loading dan error untuk controller yang mengambil list.
///
/// `load()` tidak pernah throw: error disimpan di [error] untuk
/// ditampilkan layar.
/// Mutasi (tambah/ubah/hapus) melempar `ApiException` yang harus
/// di-catch layar.
mixin LoadState on ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<void> runLoad(Future<void> Function() task) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await task();
    } on Object catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
