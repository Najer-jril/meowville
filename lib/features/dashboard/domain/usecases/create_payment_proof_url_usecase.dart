import '../repositories/dashboard_repository.dart';

class CreatePaymentProofUrlUseCase {
  const CreatePaymentProofUrlUseCase(this._repository);

  final DashboardRepository _repository;

  Future<String> call(String path) => _repository.createPaymentProofUrl(path);
}
