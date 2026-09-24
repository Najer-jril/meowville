import 'package:flutter/foundation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/admin_booking.dart';
import '../../domain/entities/booking_decision.dart';
import '../../domain/usecases/decide_booking_usecase.dart';

class BookingDecisionController extends ChangeNotifier {
  BookingDecisionController(this._decide, this._adminId);

  final DecideBookingUseCase _decide;
  final String? Function() _adminId;

  BookingDecision? _inFlight;
  String? _errorMessage;
  bool _disposed = false;

  BookingDecision? get inFlight => _inFlight;
  String? get errorMessage => _errorMessage;
  bool get isSubmitting => _inFlight != null;

  Future<bool> submit(AdminBooking booking, BookingDecision decision) async {
    if (isSubmitting) {
      return false;
    }
    _inFlight = decision;
    _errorMessage = null;
    _notify();

    bool saved = false;
    try {
      await _decide(booking: booking, decision: decision, adminId: _adminId());
      saved = true;
    } on AppException catch (error) {
      _errorMessage = error.message;
    } on Object catch (error) {
      debugPrint('Keputusan reservasi ${booking.id} gagal: $error');
      _errorMessage = 'Keputusan belum tersimpan. Coba ulangi sebentar lagi.';
    }
    _inFlight = null;
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
