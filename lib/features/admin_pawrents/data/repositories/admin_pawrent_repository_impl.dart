import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/pawrent.dart';
import '../../domain/repositories/admin_pawrent_repository.dart';
import '../datasources/admin_pawrent_remote_datasource.dart';
import '../models/pawrent_dto.dart';

class AdminPawrentRepositoryImpl implements AdminPawrentRepository {
  const AdminPawrentRepositoryImpl(this._dataSource);

  final AdminPawrentRemoteDataSource _dataSource;

  @override
  Future<List<PawrentSummary>> loadPawrents() async {
    final List<Map<String, dynamic>> rows = await _dataSource.pawrents();
    return rows.map(pawrentSummaryFromJson).toList(growable: false);
  }

  @override
  Future<PawrentDetail> loadPawrent(String userId) async {
    final Map<String, dynamic>? row = await _dataSource.pawrent(userId);
    if (row == null) {
      throw const NotFoundException(
        'Pawrent ini tidak ditemukan. Mungkin tautannya salah.',
      );
    }
    return pawrentDetailFromJson(row);
  }
}
