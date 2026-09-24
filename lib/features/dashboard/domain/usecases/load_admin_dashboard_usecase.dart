import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../entities/admin_dashboard.dart';
import '../repositories/dashboard_repository.dart';

class LoadAdminDashboardUseCase {
  const LoadAdminDashboardUseCase(this._repository, this._clock);

  final DashboardRepository _repository;
  final Clock _clock;

  Future<AdminDashboard> call() {
    return _repository.loadAdminDashboard(today: dateOnly(_clock()));
  }
}
