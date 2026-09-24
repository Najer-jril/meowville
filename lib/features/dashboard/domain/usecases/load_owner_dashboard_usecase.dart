import '../../../../core/utils/clock.dart';
import '../../../../core/utils/relative_date.dart';
import '../entities/owner_dashboard.dart';
import '../repositories/dashboard_repository.dart';

class LoadOwnerDashboardUseCase {
  const LoadOwnerDashboardUseCase(this._repository, this._clock);

  final DashboardRepository _repository;
  final Clock _clock;

  Future<OwnerDashboard> call({required String userId}) {
    return _repository.loadOwnerDashboard(
      userId: userId,
      today: dateOnly(_clock()),
    );
  }
}
