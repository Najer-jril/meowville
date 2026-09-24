import 'package:meowville/core/errors/app_exception.dart';
import 'package:meowville/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:meowville/features/dashboard/domain/entities/admin_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_status.dart';
import 'package:meowville/features/dashboard/domain/entities/booking_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/daily_log_entry.dart';
import 'package:meowville/features/dashboard/domain/entities/owner_dashboard.dart';
import 'package:meowville/features/dashboard/domain/entities/pet_summary.dart';
import 'package:meowville/features/dashboard/domain/entities/room_tier.dart';
import 'package:meowville/features/dashboard/domain/entities/sitter_dashboard.dart';
import 'package:meowville/features/dashboard/domain/repositories/dashboard_repository.dart';

final DateTime today = DateTime(2026, 10, 12);

DateTime day(int offset) => DateTime(2026, 10, 12 + offset);

const PetSummary miko = PetSummary(
  id: 'pet-1',
  name: 'Miko',
  breed: 'Domestik',
  sex: 'Jantan',
  weightKg: 4.2,
);

const PetSummary luna = PetSummary(
  id: 'pet-2',
  name: 'Luna',
  breed: 'Persia',
  sex: 'Betina',
  weightKg: 3.8,
);

const RoomTier standardTier = RoomTier(
  id: 1,
  roomType: 'Standard',
  pricePerNight: 75000,
  description: 'Kamar sederhana dengan jendela kecil.',
  includedServices: 'Makan dua kali, air bersih, Pasir baru',
);

const RoomTier deluxeTier = RoomTier(
  id: 2,
  roomType: 'Deluxe',
  pricePerNight: 120000,
  description: 'Kamar lebih luas.',
  includedServices: 'Makan tiga kali',
);

BookingSummary booking({
  String id = '3f9a2b41-0000-4000-8000-000000000001',
  BookingStatus status = BookingStatus.confirmed,
  DateTime? checkin,
  DateTime? checkout,
  PetSummary pet = miko,
  RoomTier tier = standardTier,
  DateTime? createdAt,
  String? unitCode,
  String? ownerName = 'Rani Pratama',
  String? assignedSitterId,
  String? paymentProofPath,
  String? careInstructions,
  double? totalPrice = 225000,
}) {
  return BookingSummary(
    id: id,
    status: status,
    checkin: checkin ?? day(0),
    checkout: checkout ?? day(3),
    pet: pet,
    roomType: tier.roomType,
    roomId: tier.id,
    pricePerNight: tier.pricePerNight,
    totalPrice: totalPrice,
    createdAt: createdAt ?? DateTime(2026, 10, 10, 9),
    unitCode: unitCode,
    ownerName: ownerName,
    assignedSitterId: assignedSitterId,
    paymentProofPath: paymentProofPath,
    careInstructions: careInstructions,
  );
}

DailyLogEntry logFor(
  BookingSummary booking, {
  String id = 'log-1',
  String? mood = 'Ceria',
  String? note = 'Makan lahap dan main bola.',
  String? eatingTime = '08:30',
  String? authorName = 'Gilang',
  DateTime? createdAt,
}) {
  return DailyLogEntry(
    id: id,
    bookingId: booking.id,
    logDate: today,
    createdAt: createdAt ?? DateTime(2026, 10, 12, 8, 45),
    eatingTime: eatingTime,
    mood: mood,
    note: note,
    authorName: authorName,
  );
}

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    this.owner,
    this.sitter,
    this.admin,
    this.error,
    this.gate,
    this.proofUrl = 'https://example.test/bukti.png',
  });

  Future<void>? gate;

  OwnerDashboard? owner;
  SitterDashboard? sitter;
  AdminDashboard? admin;
  AppException? error;
  final String proofUrl;

  int ownerLoads = 0;
  int sitterLoads = 0;
  int adminLoads = 0;
  final List<String> proofRequests = <String>[];

  @override
  Future<OwnerDashboard> loadOwnerDashboard({
    required String userId,
    required DateTime today,
  }) async {
    ownerLoads++;
    await gate;
    if (error != null) {
      throw error!;
    }
    return owner!;
  }

  @override
  Future<SitterDashboard> loadSitterDashboard({
    required String sitterId,
    required DateTime today,
  }) async {
    sitterLoads++;
    await gate;
    if (error != null) {
      throw error!;
    }
    return sitter!;
  }

  @override
  Future<AdminDashboard> loadAdminDashboard({required DateTime today}) async {
    adminLoads++;
    await gate;
    if (error != null) {
      throw error!;
    }
    return admin!;
  }

  @override
  Future<String> createPaymentProofUrl(String path) async {
    proofRequests.add(path);
    return proofUrl;
  }
}

class FakeDashboardDataSource implements DashboardRemoteDataSource {
  FakeDashboardDataSource({
    this.bookings = const <Map<String, dynamic>>[],
    this.pets = const <Map<String, dynamic>>[],
    this.roomRows = const <Map<String, dynamic>>[],
    this.logs = const <Map<String, dynamic>>[],
    this.units = const <Map<String, dynamic>>[],
    this.blocks = const <Map<String, dynamic>>[],
    this.services = const <Map<String, dynamic>>[],
  });

  final JsonRows bookings;
  final JsonRows pets;
  final JsonRows roomRows;
  final JsonRows logs;
  final JsonRows units;
  final JsonRows blocks;
  final JsonRows services;

  final List<String> ownerLogRequests = <String>[];
  int sitterLogRequests = 0;

  @override
  Future<JsonRows> ownerBookings(String userId) async => bookings;

  @override
  Future<JsonRows> ownerPets(String userId) async => pets;

  @override
  Future<JsonRows> rooms() async => roomRows;

  @override
  Future<JsonRows> ownerDailyLogs(String bookingId, DateTime day) async {
    ownerLogRequests.add(bookingId);
    return logs;
  }

  @override
  Future<JsonRows> sitterGuests(String sitterId) async => bookings;

  @override
  Future<JsonRows> dailyLogsFor(List<String> bookingIds, DateTime day) async {
    sitterLogRequests++;
    return logs;
  }

  @override
  Future<JsonRows> adminLiveBookings() async => bookings;

  @override
  Future<JsonRows> recentBookings(int limit) async =>
      bookings.take(limit).toList();

  @override
  Future<JsonRows> activeRoomUnits() async => units;

  @override
  Future<JsonRows> roomBlocksOn(DateTime day) async => blocks;

  @override
  Future<JsonRows> loggedBookingIds(DateTime day) async => logs;

  @override
  Future<JsonRows> bookingServices(List<String> bookingIds) async => services;

  @override
  Future<String> signedPaymentProofUrl(String path) async => 'signed:$path';
}
