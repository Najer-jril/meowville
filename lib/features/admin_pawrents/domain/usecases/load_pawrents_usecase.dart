import '../entities/pawrent.dart';
import '../repositories/admin_pawrent_repository.dart';

class LoadPawrentsUseCase {
  const LoadPawrentsUseCase(this._repository);

  final AdminPawrentRepository _repository;

  Future<List<PawrentSummary>> call() => _repository.loadPawrents();
}

class LoadPawrentDetailUseCase {
  const LoadPawrentDetailUseCase(this._repository);

  final AdminPawrentRepository _repository;

  Future<PawrentDetail> call(String userId) => _repository.loadPawrent(userId);
}
