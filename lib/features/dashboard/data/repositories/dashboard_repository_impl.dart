import '../../domain/entities/admin_dashboard.dart';
import '../../domain/entities/booking_summary.dart';
import '../../domain/entities/daily_log_entry.dart';
import '../../domain/entities/owner_dashboard.dart';
import '../../domain/entities/room_tier.dart';
import '../../domain/entities/sitter_dashboard.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../models/booking_dto.dart';
import '../models/daily_log_dto.dart';
import '../models/json_readers.dart';
import '../models/pet_dto.dart';
import '../models/room_dtos.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._dataSource, this._resolveUrl);

  static const int recentBookingLimit = 5;

  final DashboardRemoteDataSource _dataSource;
  final PublicUrlResolver _resolveUrl;

  List<BookingSummary> _bookings(JsonRows rows) => rows
      .map(
        (Map<String, dynamic> row) =>
            BookingDto.fromJson(row).toEntity(_resolveUrl),
      )
      .toList(growable: false);

  List<DailyLogEntry> _logs(JsonRows rows) => rows
      .map(
        (Map<String, dynamic> row) =>
            DailyLogDto.fromJson(row).toEntity(_resolveUrl),
      )
      .toList(growable: false);

  List<RoomTier> _rooms(JsonRows rows) => rows
      .map((Map<String, dynamic> row) => RoomDto.fromJson(row).toEntity())
      .toList(growable: false);

  @override
  Future<OwnerDashboard> loadOwnerDashboard({
    required String userId,
    required DateTime today,
  }) async {
    final (JsonRows bookingRows, JsonRows petRows, JsonRows roomRows) = await (
      _dataSource.ownerBookings(userId),
      _dataSource.ownerPets(userId),
      _dataSource.rooms(),
    ).wait;

    final List<BookingSummary> bookings = _bookings(bookingRows);
    final BookingSummary? active = OwnerDashboard.findActive(bookings);

    // Laporan hanya ditarik saat ada reservasi aktif, dan bergantung pada id-nya.
    final List<DailyLogEntry> todayLogs = active == null
        ? const <DailyLogEntry>[]
        : _logs(await _dataSource.ownerDailyLogs(active.id, today));

    return OwnerDashboard.compose(
      bookings: bookings,
      pets: petRows
          .map(
            (Map<String, dynamic> row) =>
                PetDto.fromJson(row).toEntity(_resolveUrl),
          )
          .toList(growable: false),
      rooms: _rooms(roomRows),
      todayLogs: todayLogs,
      today: today,
    );
  }

  @override
  Future<SitterDashboard> loadSitterDashboard({
    required String sitterId,
    required DateTime today,
  }) async {
    final List<BookingSummary> guests = _bookings(
      await _dataSource.sitterGuests(sitterId),
    );
    final List<DailyLogEntry> logs = _logs(
      await _dataSource.dailyLogsFor(
        guests.map((BookingSummary b) => b.id).toList(growable: false),
        today,
      ),
    );
    return SitterDashboard.compose(
      guests: guests,
      todayLogs: logs,
      today: today,
    );
  }

  @override
  Future<AdminDashboard> loadAdminDashboard({required DateTime today}) async {
    final (
      JsonRows liveRows,
      JsonRows recentRows,
      JsonRows roomRows,
      JsonRows unitRows,
      JsonRows blockRows,
      JsonRows logRows,
    ) = await (
      _dataSource.adminLiveBookings(),
      _dataSource.recentBookings(recentBookingLimit),
      _dataSource.rooms(),
      _dataSource.activeRoomUnits(),
      _dataSource.roomBlocksOn(today),
      _dataSource.loggedBookingIds(today),
    ).wait;

    final List<BookingSummary> recent = _bookings(recentRows);
    final JsonRows serviceRows = await _dataSource.bookingServices(
      recent.map((BookingSummary b) => b.id).toList(growable: false),
    );

    final Map<String, List<String>> services = <String, List<String>>{};
    for (final Map<String, dynamic> row in serviceRows) {
      final String? name = asNonEmptyString(
        asMap(row['services'])?['service_name'],
      );
      if (name != null) {
        services
            .putIfAbsent(row['booking_id'] as String, () => <String>[])
            .add(name);
      }
    }

    return AdminDashboard.compose(
      liveBookings: _bookings(liveRows),
      recent: recent,
      rooms: _rooms(roomRows),
      units: unitRows
          .map(
            (Map<String, dynamic> row) => RoomUnitDto.fromJson(row).toEntity(),
          )
          .toList(growable: false),
      blocks: blockRows
          .map(
            (Map<String, dynamic> row) => RoomBlockDto.fromJson(row).toEntity(),
          )
          .toList(growable: false),
      todayLogs: _logs(logRows),
      servicesByBooking: services,
      today: today,
    );
  }

  @override
  Future<String> createPaymentProofUrl(String path) {
    return _dataSource.signedPaymentProofUrl(path);
  }
}
