import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/admin_pawrents/domain/entities/pawrent.dart';
import 'package:meowville/features/admin_pawrents/domain/repositories/admin_pawrent_repository.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';

class FakeAdminPawrentRepository implements AdminPawrentRepository {
  FakeAdminPawrentRepository({
    this.pawrents = const <PawrentDetail>[],
    this.error,
    this.gate,
  });

  List<PawrentDetail> pawrents;
  AppException? error;
  Future<void>? gate;

  int detailLoads = 0;

  @override
  Future<List<PawrentSummary>> loadPawrents() async {
    await gate;
    if (error != null) {
      throw error!;
    }
    return <PawrentSummary>[
      for (final PawrentDetail p in pawrents)
        PawrentSummary(
          id: p.id,
          name: p.name,
          email: p.email,
          petCount: p.pets.length,
          bookingStatuses: <BookingStatus>[
            for (final PawrentBooking b in p.bookings) b.status,
          ],
        ),
    ];
  }

  @override
  Future<PawrentDetail> loadPawrent(String userId) async {
    detailLoads++;
    await gate;
    if (error != null) {
      throw error!;
    }
    return pawrents.firstWhere(
      (PawrentDetail p) => p.id == userId,
      orElse: () =>
          throw const NotFoundException('Pawrent ini tidak ditemukan.'),
    );
  }
}
