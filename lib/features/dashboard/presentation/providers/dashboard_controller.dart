import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';

enum DashboardStatus { loading, ready, failure }

class DashboardController<T> extends ChangeNotifier {
  DashboardController(
    this._load, {
    this.fallbackMessage =
        'Dashboard gagal dimuat. Coba ulangi beberapa saat lagi.',
  }) {
    load();
  }

  final Future<T> Function() _load;

  final String fallbackMessage;

  DashboardStatus _status = DashboardStatus.loading;
  T? _data;
  String? _errorMessage;
  bool _disposed = false;

  DashboardStatus get status => _status;
  T? get data => _data;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = DashboardStatus.loading;
    _errorMessage = null;
    _notify();
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    try {
      _data = await _load();
      _status = DashboardStatus.ready;
      _errorMessage = null;
    } on AppException catch (error) {
      _status = DashboardStatus.failure;
      _errorMessage = error.message;
    } on Object {
      _status = DashboardStatus.failure;
      _errorMessage = fallbackMessage;
    }
    _notify();
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
