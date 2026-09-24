import '../entities/admin_dashboard.dart';
import '../entities/owner_dashboard.dart';
import '../entities/sitter_dashboard.dart';

abstract interface class DashboardRepository {
  Future<OwnerDashboard> loadOwnerDashboard({
    required String userId,
    required DateTime today,
  });

  Future<SitterDashboard> loadSitterDashboard({
    required String sitterId,
    required DateTime today,
  });

  Future<AdminDashboard> loadAdminDashboard({required DateTime today});

  Future<String> createPaymentProofUrl(String path);
}
