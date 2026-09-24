import '../entities/pawrent.dart';

abstract interface class AdminPawrentRepository {
  Future<List<PawrentSummary>> loadPawrents();

  Future<PawrentDetail> loadPawrent(String userId);
}
