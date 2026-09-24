import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../entities/sitter_dashboard.dart';
import '../repositories/dashboard_repository.dart';

class LoadSitterDashboardUseCase {
  const LoadSitterDashboardUseCase(this._repository, this._clock);

  final DashboardRepository _repository;
  final Clock _clock;

  Future<SitterDashboard> call({required String sitterId}) {
    return _repository.loadSitterDashboard(
      sitterId: sitterId,
      today: dateOnly(_clock()),
    );
  }
}
